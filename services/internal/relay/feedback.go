package relay

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

// Feedback is deliberately stateless: an accepted submission is forwarded to
// a chat webhook and never stored, so the relay keeps its single-binary,
// no-volume deployment. The channel is the archive.

const (
	feedbackMaxBody = 4096 // whole request; the client sends ~2KB at most
	feedbackMaxText = 1800 // Discord embed description is 4096, keep margin
	feedbackMaxMeta = 32   // version/platform/source are short tags
	feedbackPerMin  = 5    // per client IP
	feedbackGlobal  = 20   // all IPs; the Discord webhook allows ~30/min
	discordTimeout  = 5 * time.Second
)

// Feedback is one submission as the client sends it.
type Feedback struct {
	Text     string `json:"feedback"`
	Version  string `json:"version"`
	Platform string `json:"platform"`
	Source   string `json:"source"`
}

// Sink delivers an accepted submission somewhere a human reads it.
// One implementation today (Discord); a file/DB sink can be added later
// without touching the HTTP handler.
type Sink interface {
	Send(context.Context, Feedback) error
}

// ------------------------------------------------------------------ Discord

// DiscordSink posts a feedback embed into one channel via its webhook URL.
type DiscordSink struct {
	url    string
	client *http.Client
}

// NewDiscordSink builds a sink for a channel webhook.
func NewDiscordSink(url string, client *http.Client) *DiscordSink {
	return &DiscordSink{url: url, client: client}
}

type discordPayload struct {
	Embeds []discordEmbed `json:"embeds"`
}

type discordEmbed struct {
	Title       string         `json:"title"`
	Description string         `json:"description"`
	Color       int            `json:"color"`
	Fields      []discordField `json:"fields,omitempty"`
	Timestamp   string         `json:"timestamp"`
}

type discordField struct {
	Name   string `json:"name"`
	Value  string `json:"value"`
	Inline bool   `json:"inline"`
}

// Send renders the submission as one embed. Version/platform make the channel
// triage-able without a database.
func (d *DiscordSink) Send(ctx context.Context, f Feedback) error {
	embed := discordEmbed{
		Title:       "papope feedback",
		Description: f.Text,
		Color:       0x0098dc, // team blue, matches the game
		Timestamp:   time.Now().UTC().Format(time.RFC3339),
	}
	if f.Version != "" {
		embed.Fields = append(embed.Fields, discordField{Name: "version", Value: f.Version, Inline: true})
	}
	if f.Platform != "" {
		embed.Fields = append(embed.Fields, discordField{Name: "platform", Value: f.Platform, Inline: true})
	}
	if f.Source != "" {
		embed.Fields = append(embed.Fields, discordField{Name: "source", Value: f.Source, Inline: true})
	}
	body, err := json.Marshal(discordPayload{Embeds: []discordEmbed{embed}})
	if err != nil {
		return err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, d.url, bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("User-Agent", "papope-relay-feedback")
	resp, err := d.client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	// Drain a little so the connection can be reused; ignore the payload.
	io.Copy(io.Discard, io.LimitReader(resp.Body, 4096))
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("webhook status %d", resp.StatusCode)
	}
	return nil
}

// --------------------------------------------------------------- HTTP layer

// FeedbackServer owns the endpoint's throttles and sink.
type FeedbackServer struct {
	sink   Sink
	perIP  *throttle
	global *throttle
}

// NewFeedbackServer wires throttles for an explicit sink (tests use this).
func NewFeedbackServer(sink Sink, limitPerMin int) *FeedbackServer {
	if limitPerMin <= 0 {
		limitPerMin = feedbackPerMin
	}
	return &FeedbackServer{
		sink:   sink,
		perIP:  newThrottle(limitPerMin),
		global: newThrottle(feedbackGlobal),
	}
}

// NewFeedback reads the deployment config: PAPOPE_FEEDBACK_WEBHOOK (secret,
// required) and PAPOPE_FEEDBACK_RATE (per-IP cap, optional). A missing
// webhook disables the route (503) but keeps the relay serving matches.
func NewFeedback() *FeedbackServer {
	url := strings.TrimSpace(os.Getenv("PAPOPE_FEEDBACK_WEBHOOK"))
	var sink Sink
	if url == "" {
		log.Printf("feedback: PAPOPE_FEEDBACK_WEBHOOK unset; POST /v1/feedback returns 503")
	} else {
		sink = NewDiscordSink(url, &http.Client{Timeout: discordTimeout})
	}
	limit := feedbackPerMin
	if raw := strings.TrimSpace(os.Getenv("PAPOPE_FEEDBACK_RATE")); raw != "" {
		if n, err := strconv.Atoi(raw); err == nil && n > 0 {
			limit = n
		} else {
			log.Printf("feedback: ignoring PAPOPE_FEEDBACK_RATE=%q", raw)
		}
	}
	return NewFeedbackServer(sink, limit)
}

// HandleCreate: POST /v1/feedback {feedback,version,platform,source} -> {}
// 503 when unconfigured, 429 when throttled, 502 when the sink refuses.
// CORS (and the preflight) is the mux-level WithCORS wrapper's job.
func (f *FeedbackServer) HandleCreate(w http.ResponseWriter, r *http.Request) {
	if !f.perIP.allow(clientIP(r)) || !f.global.allow("*") {
		writeErr(w, http.StatusTooManyRequests, "rate limited, try again shortly")
		return
	}

	var in Feedback
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, feedbackMaxBody)).Decode(&in); err != nil {
		writeErr(w, http.StatusBadRequest, "body must be {\"feedback\":\"...\"}")
		return
	}
	in.Text = strings.TrimSpace(in.Text)
	if in.Text == "" {
		writeErr(w, http.StatusBadRequest, "feedback must not be empty")
		return
	}
	in.Text = clampRunes(in.Text, feedbackMaxText)
	in.Version = clampRunes(strings.TrimSpace(in.Version), feedbackMaxMeta)
	in.Platform = clampRunes(strings.TrimSpace(in.Platform), feedbackMaxMeta)
	in.Source = clampRunes(strings.TrimSpace(in.Source), feedbackMaxMeta)

	if f.sink == nil {
		writeErr(w, http.StatusServiceUnavailable, "feedback is disabled")
		return
	}
	ctx, cancel := context.WithTimeout(r.Context(), discordTimeout)
	defer cancel()
	if err := f.sink.Send(ctx, in); err != nil {
		// Never log the submission itself: it may contain anything.
		log.Printf("feedback: forward failed: %v", err)
		writeErr(w, http.StatusBadGateway, "could not deliver feedback")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{})
}

// clampRunes caps s at max characters without splitting UTF-8.
func clampRunes(s string, max int) string {
	r := []rune(s)
	if len(r) <= max {
		return s
	}
	return string(r[:max])
}

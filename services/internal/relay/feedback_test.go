package relay

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// fakeSink records submissions instead of posting to Discord.
type fakeSink struct {
	got []Feedback
	err error
}

func (f *fakeSink) Send(_ context.Context, fb Feedback) error {
	f.got = append(f.got, fb)
	return f.err
}

func feedbackMux(sink Sink, perMin int) *http.ServeMux {
	srv := NewFeedbackServer(sink, perMin)
	mux := http.NewServeMux()
	mux.HandleFunc("POST /v1/feedback", srv.HandleCreate)
	mux.HandleFunc("OPTIONS /v1/feedback", srv.HandlePreflight)
	return mux
}

func postFeedback(mux *http.ServeMux, body string) *httptest.ResponseRecorder {
	req := httptest.NewRequest(http.MethodPost, "/v1/feedback", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	return rec
}

func TestFeedbackForwards(t *testing.T) {
	sink := &fakeSink{}
	mux := feedbackMux(sink, 10)

	rec := postFeedback(mux, `{"feedback":"  dash is stuck  ","version":"1.5.0","platform":"Web","source":"PAPOPE"}`)
	if rec.Code != http.StatusOK {
		t.Fatalf("status %d: %s", rec.Code, rec.Body.String())
	}
	if got := rec.Header().Get("Access-Control-Allow-Origin"); got != "*" {
		t.Fatalf("missing CORS origin, got %q", got)
	}
	if len(sink.got) != 1 {
		t.Fatalf("sink got %d submissions", len(sink.got))
	}
	got := sink.got[0]
	if got.Text != "dash is stuck" {
		t.Fatalf("text %q", got.Text)
	}
	if got.Version != "1.5.0" || got.Platform != "Web" || got.Source != "PAPOPE" {
		t.Fatalf("metadata %+v", got)
	}
}

func TestFeedbackRejectsEmpty(t *testing.T) {
	sink := &fakeSink{}
	rec := postFeedback(feedbackMux(sink, 10), `{"feedback":"   "}`)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status %d", rec.Code)
	}
	if len(sink.got) != 0 {
		t.Fatalf("empty submission reached the sink")
	}
}

func TestFeedbackRejectsMalformed(t *testing.T) {
	sink := &fakeSink{}
	rec := postFeedback(feedbackMux(sink, 10), `not json`)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status %d", rec.Code)
	}
	if len(sink.got) != 0 {
		t.Fatalf("malformed body reached the sink")
	}
}

func TestFeedbackCapsBody(t *testing.T) {
	sink := &fakeSink{}
	long := strings.Repeat("a", feedbackMaxBody)
	rec := postFeedback(feedbackMux(sink, 10), `{"feedback":"`+long+`"}`)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status %d", rec.Code)
	}
	if len(sink.got) != 0 {
		t.Fatalf("oversize body reached the sink")
	}
}

func TestFeedbackClampsText(t *testing.T) {
	sink := &fakeSink{}
	long := strings.Repeat("é", feedbackMaxText+200)
	rec := postFeedback(feedbackMux(sink, 10), `{"feedback":"`+long+`"}`)
	if rec.Code != http.StatusOK {
		t.Fatalf("status %d: %s", rec.Code, rec.Body.String())
	}
	if got := len([]rune(sink.got[0].Text)); got != feedbackMaxText {
		t.Fatalf("clamped length %d, want %d", got, feedbackMaxText)
	}
}

func TestFeedbackThrottlesPerIP(t *testing.T) {
	sink := &fakeSink{}
	mux := feedbackMux(sink, 2)
	for i := range 2 {
		if rec := postFeedback(mux, `{"feedback":"hi"}`); rec.Code != http.StatusOK {
			t.Fatalf("request %d: status %d", i, rec.Code)
		}
	}
	if rec := postFeedback(mux, `{"feedback":"hi"}`); rec.Code != http.StatusTooManyRequests {
		t.Fatalf("third request status %d, want 429", rec.Code)
	}
	if len(sink.got) != 2 {
		t.Fatalf("sink got %d submissions, want 2", len(sink.got))
	}
}

func TestFeedbackSinkFailure(t *testing.T) {
	sink := &fakeSink{err: errors.New("discord down")}
	rec := postFeedback(feedbackMux(sink, 10), `{"feedback":"hi"}`)
	if rec.Code != http.StatusBadGateway {
		t.Fatalf("status %d, want 502", rec.Code)
	}
}

func TestFeedbackDisabled(t *testing.T) {
	mux := feedbackMux(nil, 10)
	rec := postFeedback(mux, `{"feedback":"hi"}`)
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("status %d, want 503", rec.Code)
	}
}

func TestFeedbackPreflight(t *testing.T) {
	req := httptest.NewRequest(http.MethodOptions, "/v1/feedback", nil)
	req.Header.Set("Origin", "https://atka66.itch.io")
	req.Header.Set("Access-Control-Request-Method", "POST")
	rec := httptest.NewRecorder()
	feedbackMux(&fakeSink{}, 10).ServeHTTP(rec, req)

	if rec.Code != http.StatusNoContent {
		t.Fatalf("status %d, want 204", rec.Code)
	}
	for header, want := range map[string]string{
		"Access-Control-Allow-Origin":  "*",
		"Access-Control-Allow-Methods": "POST, OPTIONS",
		"Access-Control-Allow-Headers": "Content-Type",
	} {
		if got := rec.Header().Get(header); got != want {
			t.Fatalf("%s = %q, want %q", header, got, want)
		}
	}
}

func TestDiscordSinkPayload(t *testing.T) {
	var payload discordPayload
	posted := false
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		posted = true
		if r.Method != http.MethodPost {
			t.Errorf("method %s", r.Method)
		}
		if ct := r.Header.Get("Content-Type"); ct != "application/json" {
			t.Errorf("content type %q", ct)
		}
		if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
			t.Errorf("decode: %v", err)
		}
		w.WriteHeader(http.StatusNoContent) // Discord answers 204
	}))
	defer srv.Close()

	sink := NewDiscordSink(srv.URL, srv.Client())
	if err := sink.Send(context.Background(), Feedback{Text: "hi", Version: "1.5.0", Platform: "Linux"}); err != nil {
		t.Fatalf("send: %v", err)
	}
	if !posted {
		t.Fatal("webhook never called")
	}
	if len(payload.Embeds) != 1 || payload.Embeds[0].Description != "hi" {
		t.Fatalf("payload %+v", payload)
	}
	if len(payload.Embeds[0].Fields) != 2 {
		t.Fatalf("fields %+v", payload.Embeds[0].Fields)
	}
}

func TestDiscordSinkRejectsErrors(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		http.Error(w, "nope", http.StatusInternalServerError)
	}))
	defer srv.Close()

	if err := NewDiscordSink(srv.URL, srv.Client()).Send(context.Background(), Feedback{Text: "hi"}); err == nil {
		t.Fatal("expected an error for a 500 webhook")
	}
}

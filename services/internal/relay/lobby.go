package relay

import (
	"crypto/rand"
	"encoding/json"
	"net"
	"net/http"
	"strings"
	"sync"
	"time"
)

// Lobby REST (Phase 2): room discovery and lifecycle. Membership itself is
// the WebSocket connection (hub.go) — being in a room means having a live
// socket in it, so there is intentionally no "join" endpoint.

const (
	// gameVersion is the relay protocol version clients send (NOT the app
	// display version). Creates with anything else get 400; lists with
	// anything else get an empty list.
	gameVersion = "1"
	// maxRooms bounds memory on a small Pi.
	maxRooms = 256
	// codeAlphabet is letters only: no digits, so I/O are unambiguous.
	codeAlphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	codeLen      = 4
	// Rate limits, per client IP, fixed-window.
	createLimitPerMin = 30
	listLimitPerMin   = 60
	rateWindow        = time.Minute
)

// RoomInfo is one entry of the list response. Players is live socket count.
type RoomInfo struct {
	Code    string `json:"code"`
	Players int    `json:"players"`
	Version string `json:"version"`
}

// ErrRoomFull signals the room cap.
type errFull struct{}

func (errFull) Error() string { return "room cap reached" }

// CreateRoom mints a code and stores the room. Collisions retry; a full hub errors.
func (h *Hub) CreateRoom(version string) (string, error) {
	h.mu.Lock()
	defer h.mu.Unlock()
	if len(h.rooms) >= maxRooms {
		return "", errFull{}
	}
	for range 10 {
		code := genCode()
		if _, taken := h.rooms[code]; taken {
			continue
		}
		h.rooms[code] = &Room{code: code, version: version, conns: make(map[*Conn]struct{}), lastSeen: time.Now()}
		return code, nil
	}
	return "", errFull{}
}

// TouchRoom bumps lastSeen (heartbeat); false if the code is unknown.
func (h *Hub) TouchRoom(code string) bool {
	h.mu.Lock()
	defer h.mu.Unlock()
	r, ok := h.rooms[code]
	if !ok {
		return false
	}
	r.lastSeen = time.Now()
	return true
}

// DeleteRoom removes the code; false if unknown.
func (h *Hub) DeleteRoom(code string) bool {
	h.mu.Lock()
	defer h.mu.Unlock()
	if _, ok := h.rooms[code]; !ok {
		return false
	}
	delete(h.rooms, code)
	return true
}

// ListRooms returns rooms matching version (unknown version -> empty, not error).
func (h *Hub) ListRooms(version string) []RoomInfo {
	h.mu.Lock()
	defer h.mu.Unlock()
	out := []RoomInfo{}
	for _, r := range h.rooms {
		if r.version != version {
			continue
		}
		out = append(out, RoomInfo{Code: r.code, Players: len(r.conns), Version: r.version})
	}
	return out
}

// genCode draws codeLen letters from codeAlphabet via crypto/rand.
func genCode() string {
	var b [codeLen]byte
	var rnd [codeLen]byte
	rand.Read(rnd[:])
	for i := range b {
		b[i] = codeAlphabet[int(rnd[i])%len(codeAlphabet)]
	}
	return string(b[:])
}

// throttle is a per-IP fixed-window counter. Zero value is unusable; use newThrottle.
type throttle struct {
	mu     sync.Mutex
	limit  int
	hits   map[string]int
	window time.Time
}

func newThrottle(limit int) *throttle {
	return &throttle{limit: limit, hits: make(map[string]int), window: time.Now()}
}

// allow reports whether ip may proceed, counting this hit.
func (t *throttle) allow(ip string) bool {
	t.mu.Lock()
	defer t.mu.Unlock()
	now := time.Now()
	if now.Sub(t.window) >= rateWindow {
		t.window = now
		clear(t.hits)
	}
	t.hits[ip]++
	return t.hits[ip] <= t.limit
}

// Lobby wires per-endpoint throttles. One per Hub (constructed in main).
type Lobby struct {
	create *throttle
	list   *throttle
}

// NewLobby builds throttles for the REST endpoints.
func NewLobby() *Lobby {
	return &Lobby{create: newThrottle(createLimitPerMin), list: newThrottle(listLimitPerMin)}
}

// clientIP strips the port; unparseable remotes share one bucket.
func clientIP(r *http.Request) string {
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return r.RemoteAddr
	}
	return host
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v)
}

func writeErr(w http.ResponseWriter, status int, msg string) {
	writeJSON(w, status, map[string]string{"error": msg})
}

// HandleCreateRoom: POST /v1/rooms {"version"} -> {"code"}.
func (h *Hub) HandleCreateRoom(lobby *Lobby, w http.ResponseWriter, r *http.Request) {
	if !lobby.create.allow(clientIP(r)) {
		writeErr(w, http.StatusTooManyRequests, "rate limited, try again shortly")
		return
	}
	var req struct {
		Version string `json:"version"`
	}
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 1024)).Decode(&req); err != nil {
		writeErr(w, http.StatusBadRequest, "body must be {\"version\":\"...\"}")
		return
	}
	if req.Version != gameVersion {
		writeErr(w, http.StatusBadRequest, "unsupported version")
		return
	}
	code, err := h.CreateRoom(req.Version)
	if err != nil {
		writeErr(w, http.StatusTooManyRequests, "no room slots left")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"code": code})
}

// HandleListRooms: GET /v1/rooms?version= -> [{code,players,version}].
func (h *Hub) HandleListRooms(lobby *Lobby, w http.ResponseWriter, r *http.Request) {
	if !lobby.list.allow(clientIP(r)) {
		writeErr(w, http.StatusTooManyRequests, "rate limited, try again shortly")
		return
	}
	writeJSON(w, http.StatusOK, h.ListRooms(r.URL.Query().Get("version")))
}

// HandleHeartbeat: POST /v1/rooms/{code}/heartbeat -> {} (404 if unknown).
func (h *Hub) HandleHeartbeat(w http.ResponseWriter, r *http.Request) {
	code := strings.ToUpper(r.PathValue("code"))
	if !h.TouchRoom(code) {
		writeErr(w, http.StatusNotFound, "unknown room")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{})
}

// HandleDeleteRoom: DELETE /v1/rooms/{code} (404 if unknown).
func (h *Hub) HandleDeleteRoom(w http.ResponseWriter, r *http.Request) {
	code := strings.ToUpper(r.PathValue("code"))
	if !h.DeleteRoom(code) {
		writeErr(w, http.StatusNotFound, "unknown room")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{})
}

// handleHealthz: GET /healthz -> {"ok":true}. Liveness only.
func HandleHealthz(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]bool{"ok": true})
}

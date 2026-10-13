package relay

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// serveLobbyHub spins hub + REST routes like main does.
func serveLobbyHub(t *testing.T) (*httptest.Server, *Hub) {
	t.Helper()
	hub := NewHub()
	lobby := NewLobby()
	mux := http.NewServeMux()
	mux.HandleFunc("/room/", hub.ServeRoom)
	mux.HandleFunc("POST /v1/rooms", func(w http.ResponseWriter, r *http.Request) {
		hub.HandleCreateRoom(lobby, w, r)
	})
	mux.HandleFunc("GET /v1/rooms", func(w http.ResponseWriter, r *http.Request) {
		hub.HandleListRooms(lobby, w, r)
	})
	mux.HandleFunc("POST /v1/rooms/{code}/heartbeat", hub.HandleHeartbeat)
	mux.HandleFunc("DELETE /v1/rooms/{code}", hub.HandleDeleteRoom)
	mux.HandleFunc("GET /healthz", HandleHealthz)
	srv := httptest.NewServer(mux)
	t.Cleanup(srv.Close)
	return srv, hub
}

func postJSON(t *testing.T, srv *httptest.Server, path, body string) (int, map[string]any) {
	t.Helper()
	resp, err := http.Post(srv.URL+path, "application/json", strings.NewReader(body))
	if err != nil {
		t.Fatalf("post %s: %v", path, err)
	}
	defer resp.Body.Close()
	var out map[string]any
	json.NewDecoder(resp.Body).Decode(&out)
	return resp.StatusCode, out
}

func getPath(t *testing.T, srv *httptest.Server, path string) (int, string) {
	t.Helper()
	resp, err := http.Get(srv.URL + path)
	if err != nil {
		t.Fatalf("get %s: %v", path, err)
	}
	defer resp.Body.Close()
	out := make([]byte, 0, 4096)
	chunk := make([]byte, 1024)
	for {
		n, err := resp.Body.Read(chunk)
		out = append(out, chunk[:n]...)
		if err != nil {
			break
		}
	}
	return resp.StatusCode, string(out)
}

// Create -> heartbeat -> list -> delete lifecycle.
func TestRoomLifecycle(t *testing.T) {
	srv, _ := serveLobbyHub(t)

	status, created := postJSON(t, srv, "/v1/rooms", `{"version":"1"}`)
	if status != http.StatusOK {
		t.Fatalf("create status %d (%v)", status, created)
	}
	code, _ := created["code"].(string)
	if len(code) != 4 {
		t.Fatalf("code %q is not 4 chars", code)
	}
	for _, c := range code {
		if c < 'A' || c > 'Z' {
			t.Fatalf("code %q is not letters-only", code)
		}
	}

	status, body := getPath(t, srv, "/v1/rooms?version=1")
	if status != http.StatusOK || !strings.Contains(body, code) {
		t.Fatalf("list %d %q, want it to contain %s", status, body, code)
	}

	resp, err := http.Post(srv.URL+"/v1/rooms/"+code+"/heartbeat", "application/json", nil)
	if err != nil || resp.StatusCode != http.StatusOK {
		t.Fatalf("heartbeat: %v status %d", err, resp.StatusCode)
	}
	resp.Body.Close()

	req, _ := http.NewRequest(http.MethodDelete, srv.URL+"/v1/rooms/"+code, nil)
	resp, err = http.DefaultClient.Do(req)
	if err != nil || resp.StatusCode != http.StatusOK {
		t.Fatalf("delete: %v status %d", err, resp.StatusCode)
	}
	resp.Body.Close()

	status, body = getPath(t, srv, "/v1/rooms?version=1")
	if status != http.StatusOK || strings.Contains(body, code) {
		t.Fatalf("list after delete %d %q, want no %s", status, body, code)
	}
}

// Unknown version lists nothing; unknown codes 404.
func TestVersionGateAndUnknown(t *testing.T) {
	srv, _ := serveLobbyHub(t)

	if status, _ := postJSON(t, srv, "/v1/rooms", `{"version":"9.9.9"}`); status != http.StatusBadRequest {
		t.Fatalf("create with bad version: status %d, want 400", status)
	}
	status, body := getPath(t, srv, "/v1/rooms?version=9.9.9")
	if status != http.StatusOK || strings.TrimSpace(body) != "[]" {
		t.Fatalf("list with bad version: %d %q, want 200 []", status, body)
	}
	if status, _ := postJSON(t, srv, "/v1/rooms/ZZZZ/heartbeat", ""); status != http.StatusNotFound {
		t.Fatalf("heartbeat unknown: status %d, want 404", status)
	}
	status, _ = getPath(t, srv, "/healthz")
	if status != http.StatusOK {
		t.Fatalf("healthz: status %d, want 200", status)
	}
}

// Hammering create trips the per-IP rate limit (429).
func TestCreateRateLimit(t *testing.T) {
	srv, _ := serveLobbyHub(t)
	limited := false
	for range createLimitPerMin + 5 {
		status, _ := postJSON(t, srv, "/v1/rooms", `{"version":"1"}`)
		if status == http.StatusTooManyRequests {
			limited = true
			break
		}
	}
	if !limited {
		t.Fatal("hammering create never hit 429")
	}
}

// A full hub refuses new rooms with 429.
func TestRoomCap(t *testing.T) {
	hub := NewHub()
	for range maxRooms {
		if _, err := hub.CreateRoom(gameVersion); err != nil {
			t.Fatalf("create below cap: %v", err)
		}
	}
	if _, err := hub.CreateRoom(gameVersion); err == nil {
		t.Fatal("create past cap succeeded, want refusal")
	}
}

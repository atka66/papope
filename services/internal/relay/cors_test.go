package relay

import (
	"net/http"
	"strings"
	"testing"
)

// The itch.io web build is a different origin: every response must carry the
// origin header, errors included, or the browser hides the status.
func TestCORSOnLobbyResponses(t *testing.T) {
	srv, _ := serveLobbyHub(t)
	cases := []struct{ method, path, body string }{
		{http.MethodGet, "/v1/rooms?version=1", ""},
		{http.MethodPost, "/v1/rooms", `{"version":"1"}`},
		{http.MethodDelete, "/v1/rooms/000000", ""}, // 404 still needs CORS
		{http.MethodGet, "/healthz", ""},
	}
	for _, tc := range cases {
		req, err := http.NewRequest(tc.method, srv.URL+tc.path, strings.NewReader(tc.body))
		if err != nil {
			t.Fatalf("new request: %v", err)
		}
		req.Header.Set("Origin", "https://html-classic.itch.zone")
		if tc.body != "" {
			req.Header.Set("Content-Type", "application/json")
		}
		resp, err := srv.Client().Do(req)
		if err != nil {
			t.Fatalf("%s %s: %v", tc.method, tc.path, err)
		}
		resp.Body.Close()
		if got := resp.Header.Get("Access-Control-Allow-Origin"); got != "*" {
			t.Fatalf("%s %s: ACAO %q, want *", tc.method, tc.path, got)
		}
	}
}

// JSON POSTs and DELETEs are preflighted; ServeMux would 405 an OPTIONS it has
// no pattern for, so the middleware must answer before routing.
func TestCORSPreflightOnLobby(t *testing.T) {
	srv, _ := serveLobbyHub(t)
	req, err := http.NewRequest(http.MethodOptions, srv.URL+"/v1/rooms", nil)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	req.Header.Set("Origin", "https://html-classic.itch.zone")
	req.Header.Set("Access-Control-Request-Method", "POST")
	req.Header.Set("Access-Control-Request-Headers", "content-type")
	resp, err := srv.Client().Do(req)
	if err != nil {
		t.Fatalf("preflight: %v", err)
	}
	resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent {
		t.Fatalf("status %d, want 204", resp.StatusCode)
	}
	for header, want := range map[string]string{
		"Access-Control-Allow-Origin":  "*",
		"Access-Control-Allow-Methods": "GET, POST, DELETE, OPTIONS",
		"Access-Control-Allow-Headers": "Content-Type",
	} {
		if got := resp.Header.Get(header); got != want {
			t.Fatalf("%s = %q, want %q", header, got, want)
		}
	}
}

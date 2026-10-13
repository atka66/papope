package relay

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/gorilla/websocket"
)

// serveTestHub spins the hub on an httptest server, like :8080 in main.
func serveTestHub(t *testing.T) (*Hub, *httptest.Server) {
	t.Helper()
	hub := NewHub()
	mux := http.NewServeMux()
	mux.HandleFunc("/room/", hub.ServeRoom)
	srv := httptest.NewServer(mux)
	t.Cleanup(srv.Close)
	return hub, srv
}

func dial(t *testing.T, srv *httptest.Server, code string) *websocket.Conn {
	t.Helper()
	url := "ws" + strings.TrimPrefix(srv.URL, "http") + "/room/" + code
	ws, _, err := websocket.DefaultDialer.Dial(url, nil)
	if err != nil {
		t.Fatalf("dial: %v", err)
	}
	return ws
}

func readOne(t *testing.T, ws *websocket.Conn) Envelope {
	t.Helper()
	ws.SetReadDeadline(time.Now().Add(5 * time.Second))
	var env Envelope
	if err := ws.ReadJSON(&env); err != nil {
		t.Fatalf("read: %v", err)
	}
	return env
}

// Two clients in TEST exchange messages; killing one delivers bye to the other.
func TestExchangeAndBye(t *testing.T) {
	_, srv := serveTestHub(t)
	a := dial(t, srv, "TEST")
	defer a.Close()
	b := dial(t, srv, "TEST")
	defer b.Close()

	hello := Envelope{V: 1, Room: "TEST", From: 0, Kind: "hello"}
	if err := WriteEnvelope(a, hello); err != nil {
		t.Fatalf("write hello: %v", err)
	}
	got := readOne(t, b)
	if got.Kind != "hello" || got.From != 0 {
		t.Fatalf("b got %+v, want hello from 0", got)
	}
	// Sender must NOT receive its own message.
	a.SetReadDeadline(time.Now().Add(200 * time.Millisecond))
	var echo Envelope
	if err := a.ReadJSON(&echo); err == nil {
		t.Fatalf("a received own echo: %+v", echo)
	}

	// Kill a: b must get bye.
	a.Close()
	got = readOne(t, b)
	if got.Kind != "bye" {
		t.Fatalf("b got %+v, want bye", got)
	}
}

// Oversize (>64KB) messages drop the sender; the survivor gets bye.
func TestOversizeDropsPeer(t *testing.T) {
	_, srv := serveTestHub(t)
	a := dial(t, srv, "TEST")
	defer a.Close()
	b := dial(t, srv, "TEST")
	defer b.Close()

	big := Envelope{V: 1, Room: "TEST", From: 0, Kind: "input"}
	big.Payload = []byte(`"` + strings.Repeat("x", MaxMessageBytes) + `"`)
	if err := WriteEnvelope(a, big); err != nil {
		t.Fatalf("write big: %v", err)
	}
	got := readOne(t, b)
	if got.Kind != "bye" {
		t.Fatalf("b got %+v, want bye after oversize drop", got)
	}
}

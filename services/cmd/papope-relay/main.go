// Command papope-relay is the Pi room relay: a WebSocket hub (Phase 1) plus
// lobby REST for room discovery and lifecycle (Phase 2). One binary, one port.
package main

import (
	"log"
	"net/http"

	"papope-relay/internal/relay"
)

const addr = ":8080"

func main() {
	hub := relay.NewHub()
	lobby := relay.NewLobby()
	feedback := relay.NewFeedback()
	stop := make(chan struct{})
	defer close(stop)
	go hub.StartGC(stop)

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
	// Feedback: stateless forwarder to the configured chat webhook.
	mux.HandleFunc("POST /v1/feedback", feedback.HandleCreate)
	mux.HandleFunc("OPTIONS /v1/feedback", feedback.HandlePreflight)
	mux.HandleFunc("GET /healthz", relay.HandleHealthz)

	log.Printf("papope-relay listening on %s", addr)
	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatal(err)
	}
}

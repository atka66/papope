package relay

import (
	"encoding/json"

	"github.com/gorilla/websocket"
)

// MaxMessageBytes caps a single WebSocket message (envelope + payload).
// Enforced via SetReadLimit: oversize peers get their connection dropped.
const MaxMessageBytes = 64 * 1024

// Envelope is the v1 contract: every game frame on the wire has this shape.
// Payload stays raw: the hub routes on Room/Kind and never parses game content.
type Envelope struct {
	V       int             `json:"v"`
	Room    string          `json:"room"`
	From    int             `json:"from"`
	Kind    string          `json:"kind"`
	Payload json.RawMessage `json:"payload"`
}

// NewBye builds the control message survivors receive when a peer drops.
func NewBye(room string, from int) Envelope {
	return Envelope{V: 1, Room: room, From: from, Kind: "bye", Payload: json.RawMessage(`{}`)}
}

// ReadEnvelope reads one JSON message, enforcing the size cap first.
func ReadEnvelope(conn *websocket.Conn) (Envelope, error) {
	conn.SetReadLimit(MaxMessageBytes)
	var env Envelope
	err := conn.ReadJSON(&env)
	return env, err
}

// WriteEnvelope sends one JSON message.
func WriteEnvelope(conn *websocket.Conn, env Envelope) error {
	return conn.WriteJSON(env)
}

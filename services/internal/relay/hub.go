package relay

import (
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/gorilla/websocket"
)

const (
	pingPeriod  = 25 * time.Second
	pongWait    = 60 * time.Second
	writeWait   = 10 * time.Second
	sendBufSize = 16
)

// Conn is one game client: the socket plus its outbound queue.
type Conn struct {
	ws   *websocket.Conn
	send chan Envelope
	from int
	room *Room
	hub  *Hub
}

var upgrader = websocket.Upgrader{
	// Phase 1: plain relay, no cookie/auth model yet (Phase 2/4).
	CheckOrigin: func(r *http.Request) bool { return true },
}

// ServeRoom handles GET /room/{code}: upgrades to WS and pumps messages
// until the peer drops, then notifies survivors with a bye.
func (h *Hub) ServeRoom(w http.ResponseWriter, r *http.Request) {
	code := strings.TrimPrefix(r.URL.Path, "/room/")
	if code == "" {
		http.Error(w, "missing room code", http.StatusBadRequest)
		return
	}
	ws, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("upgrade %s: %v", code, err)
		return
	}
	room := h.GetOrCreate(code)
	c := &Conn{ws: ws, send: make(chan Envelope, sendBufSize), from: -1, room: room, hub: h}
	h.join(room, c)

	go c.writePump()
	c.readPump() // blocks until peer drops; then cleanup below
	h.leave(room, c)
	close(c.send)
	ws.Close()
	h.broadcastExcept(room, c, NewBye(code, c.from))
}

// readPump is the inbound loop: one envelope in, broadcast to the room.
// Any read error (close, timeout, oversize) ends the loop and the Conn.
func (c *Conn) readPump() {
	c.ws.SetReadDeadline(time.Now().Add(pongWait))
	c.ws.SetPongHandler(func(string) error {
		c.ws.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})
	for {
		env, err := ReadEnvelope(c.ws)
		if err != nil {
			return // oversize (>64KB), close frame, or dead peer
		}
		if env.Room == "" {
			env.Room = c.room.code
		}
		if c.from < 0 {
			c.from = env.From // first message claims the slot (Phase 3 assigns)
		}
		c.hub.broadcastExcept(c.room, c, env)
	}
}

// writePump is the outbound loop: drains the queue, pings to detect dead peers.
func (c *Conn) writePump() {
	t := time.NewTicker(pingPeriod)
	defer t.Stop()
	for {
		select {
		case env, ok := <-c.send:
			c.ws.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				c.ws.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			if err := WriteEnvelope(c.ws, env); err != nil {
				return
			}
		case <-t.C:
			c.ws.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.ws.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

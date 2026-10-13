package relay

import (
	"sync"
	"time"
)

// gcInterval sweeps empty rooms; rooms idle longer than roomTTL are dropped.
const (
	gcInterval = 30 * time.Second
	roomTTL    = 60 * time.Second
)

// Room is a set of live connections sharing a code. Never bare IPs.
type Room struct {
	code     string
	version  string
	conns    map[*Conn]struct{}
	lastSeen time.Time
}

// Hub owns the room registry. One mutex guards the map and membership;
// per-connection sends go through buffered channels, never under this lock.
type Hub struct {
	mu    sync.Mutex
	rooms map[string]*Room
}

// NewHub builds an empty registry.
func NewHub() *Hub {
	return &Hub{rooms: make(map[string]*Room)}
}

// GetOrCreate returns the room for code, creating it on first WS join.
// WS-joined rooms carry no game version until Phase 3 sets it.
func (h *Hub) GetOrCreate(code string) *Room {
	h.mu.Lock()
	defer h.mu.Unlock()
	r, ok := h.rooms[code]
	if !ok {
		r = &Room{code: code, conns: make(map[*Conn]struct{})}
		h.rooms[code] = r
	}
	r.lastSeen = time.Now()
	return r
}

// join registers c in room.
func (h *Hub) join(room *Room, c *Conn) {
	h.mu.Lock()
	defer h.mu.Unlock()
	room.conns[c] = struct{}{}
	room.lastSeen = time.Now()
}

// leave unregisters c; empty rooms are left for the GC sweep.
func (h *Hub) leave(room *Room, c *Conn) {
	h.mu.Lock()
	defer h.mu.Unlock()
	delete(room.conns, c)
}

// broadcastExcept queues env to every member of room except sender.
func (h *Hub) broadcastExcept(room *Room, sender *Conn, env Envelope) {
	h.mu.Lock()
	defer h.mu.Unlock()
	room.lastSeen = time.Now()
	for c := range room.conns {
		if c == sender {
			continue
		}
		select {
		case c.send <- env:
		default:
			// Slow peer: drop the message, not the room.
		}
	}
}

// RoomCount reports live rooms (exported for tests/logging).
func (h *Hub) RoomCount() int {
	h.mu.Lock()
	defer h.mu.Unlock()
	return len(h.rooms)
}

// StartGC sweeps empty/stale rooms until stop is closed.
func (h *Hub) StartGC(stop <-chan struct{}) {
	t := time.NewTicker(gcInterval)
	defer t.Stop()
	for {
		select {
		case <-stop:
			return
		case <-t.C:
			h.sweep()
		}
	}
}

// sweep removes rooms with no conns that outlived roomTTL.
func (h *Hub) sweep() {
	h.mu.Lock()
	defer h.mu.Unlock()
	now := time.Now()
	for code, r := range h.rooms {
		if len(r.conns) == 0 && now.Sub(r.lastSeen) > roomTTL {
			delete(h.rooms, code)
		}
	}
}

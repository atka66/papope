# Papope

A fast-paced twin-stick arena fighter for you and your friends.

**Play it free in the browser: https://atka66.itch.io/papope**

## Tech

- **Engine:** Godot 4.5 (GL Compatibility renderer), GDScript, fixed 1360×768 viewport with stretch
- **Netplay:** host-authoritative online multiplayer over a relay server — room codes, lobby/match state sync, ~20 Hz snapshots with guest-side interpolation
- **Relay server:** Go 1.23 + gorilla/websocket in `services/` (room lobby REST + WebSocket relay); the client reads the relay URL from `project.godot` (`papope/relay_url`), overridable via local `override.cfg` or the in-game relay field
- **Audio:** OGG SFX/music, with LMMS (`.mmpz`) sources next to the exports
- **Exports:** Web and Windows Desktop presets (`export_presets.cfg`); the committed `papope/relay_url` is baked into every export

## How to deploy

In the editor: Project → Export…, pick the `Web` or `Windows Desktop` preset and export (needs the Godot 4.5 export templates installed).

Relay server (one binary, port 8080: WebSocket hub at `/room/`, lobby REST at `/v1/rooms`, feedback at `/v1/feedback`):

```sh
cd services
go build -o papope-relay ./cmd/papope-relay
./papope-relay  # or: docker build -t papope-relay .
```

Feedback is stateless: `POST /v1/feedback` validates and forwards the message to a chat
webhook, storing nothing. Point it at a Discord channel webhook with
`PAPOPE_FEEDBACK_WEBHOOK` (required, keep it secret — never in the client or git);
`PAPOPE_FEEDBACK_RATE` caps sends per IP per minute (default 5). Without the webhook the
route answers 503 and the rest of the relay keeps working.

Expose it over TLS (browsers require `wss://` for the web build) with a reverse proxy in front of `:8080`.

Every REST route (`/v1/rooms`, heartbeat, delete, `/v1/feedback`, `/healthz`) answers CORS
and preflights, because the itch.io web build runs on a different origin than the relay and
the browser blocks JSON POSTs and DELETEs without it. No client setting is needed — the
baked-in `papope/relay_url` already points at `wss://`.

The relay rate-limits per client IP, but behind a reverse proxy the TCP peer is the proxy,
so every player would share one bucket. Start it with `PAPOPE_TRUST_PROXY=1` and have the
proxy set the address itself:

```nginx
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
```

With the flag on, the relay keys on `X-Real-IP` (or the rightmost `X-Forwarded-For` hop)
when it parses as an IP, and ignores the headers entirely when the flag is off. Only enable
it when the relay is reachable *exclusively* through that proxy, otherwise clients can
forge their own bucket.

## Support

The game is completely free (and always will be), but if you feel supportive you can buy me a coffee:
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/G2G31H1IJ)

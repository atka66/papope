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
route answers 503 and the rest of the relay keeps working. The route serves CORS headers
because the itch.io web build preflights it.

Expose it over TLS (browsers require `wss://` for the web build) with a reverse proxy in front of `:8080`.

## Support

The game is completely free (and always will be), but if you feel supportive you can buy me a coffee:
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/G2G31H1IJ)

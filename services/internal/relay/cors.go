package relay

import "net/http"

// setCORS opens the REST surface to the itch.io web build. The game is served
// from a different origin than the relay, so every answer (including errors)
// needs the origin header or the browser hides the status from the client.
func setCORS(w http.ResponseWriter) {
	h := w.Header()
	h.Set("Access-Control-Allow-Origin", "*")
	h.Set("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS")
	h.Set("Access-Control-Allow-Headers", "Content-Type")
	h.Set("Access-Control-Max-Age", "86400")
}

// WithCORS wraps the mux. Preflights are answered before routing: ServeMux
// replies 405 for a method it has no pattern for, and a non-2xx preflight
// fails in the browser, so OPTIONS can never reach the handlers.
func WithCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		setCORS(w)
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

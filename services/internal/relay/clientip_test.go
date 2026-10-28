package relay

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func ipRequest(remote, realIP, forwarded string) *http.Request {
	req := httptest.NewRequest(http.MethodGet, "/v1/rooms", nil)
	req.RemoteAddr = remote
	if realIP != "" {
		req.Header.Set("X-Real-IP", realIP)
	}
	if forwarded != "" {
		req.Header.Set("X-Forwarded-For", forwarded)
	}
	return req
}

// Without the env flag forwarded headers are ignored: the TCP peer is the key.
func TestClientIPDirect(t *testing.T) {
	trustProxy = false
	req := ipRequest("203.0.113.9:54321", "198.51.100.7", "198.51.100.7")
	if got := clientIP(req); got != "203.0.113.9" {
		t.Fatalf("clientIP = %q, want the direct peer", got)
	}
}

// Behind the proxy the player's address is the key, not the proxy's.
func TestClientIPProxy(t *testing.T) {
	trustProxy = true
	t.Cleanup(func() { trustProxy = false })

	cases := []struct{ name, realIP, forwarded, want string }{
		{"real ip wins", "198.51.100.7", "192.0.2.1", "198.51.100.7"},
		{"forwarded fallback", "", "192.0.2.1", "192.0.2.1"},
		// A client can prepend XFF entries; only the hop our proxy appended
		// (the rightmost one) is trustworthy.
		{"forwarded rightmost hop", "", "1.2.3.4, 198.51.100.7", "198.51.100.7"},
		// Junk must not become a throttle key.
		{"garbage ignored", "not-an-ip", "1.2.3.4, also-junk", "203.0.113.9"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			req := ipRequest("203.0.113.9:54321", tc.realIP, tc.forwarded)
			if got := clientIP(req); got != tc.want {
				t.Fatalf("clientIP = %q, want %q", got, tc.want)
			}
		})
	}
}

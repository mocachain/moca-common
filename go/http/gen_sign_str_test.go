package http

import (
	"net/http"
	"strings"
	"testing"
)

func TestCanonicalRequestIncludesNonceOnlyWhenPresent(t *testing.T) {
	reqWithout, _ := http.NewRequest(http.MethodGet, "https://sp.example.com/bucket/object", nil)
	reqWithout.Header.Set(HTTPHeaderExpiryTimestamp, "2026-01-01T00:00:00Z")
	baseline := GetCanonicalRequest(reqWithout)
	if strings.Contains(baseline, strings.ToLower(HTTPHeaderNonce)) {
		t.Fatalf("nonce must not appear when the header is absent")
	}

	reqWith, _ := http.NewRequest(http.MethodGet, "https://sp.example.com/bucket/object", nil)
	reqWith.Header.Set(HTTPHeaderExpiryTimestamp, "2026-01-01T00:00:00Z")
	reqWith.Header.Set(HTTPHeaderNonce, "abc123")
	withNonce := GetCanonicalRequest(reqWith)
	if !strings.Contains(withNonce, strings.ToLower(HTTPHeaderNonce)+":abc123") {
		t.Fatalf("nonce header must be canonicalized when present, got:\n%s", withNonce)
	}
	if withNonce == baseline {
		t.Fatalf("canonical request must change when the nonce is present")
	}
}

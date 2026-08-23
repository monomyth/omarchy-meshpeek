#!/usr/bin/env bash
# Serve viewer/ + model over localhost and open Chromium (Three.js).
# Security: token-authenticated requests, lifecycle tracking, restricted permissions.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VIEWER_SRC="$PLUGIN_DIR/viewer/index.html"
MODEL="${1:-}"
if [[ -z "$MODEL" || ! -f "$MODEL" ]]; then
  notify-send -u low "Mesh Peek" "No model file for web viewer"
  echo "no file: $MODEL" >&2
  exit 1
fi
if [[ ! -f "$VIEWER_SRC" ]]; then
  notify-send -u critical "Mesh Peek" "viewer/index.html missing"
  exit 1
fi

# Populate XDG cache for Three.js (outside git); capture cache dir
CACHE_DIR="$("$SCRIPT_DIR/ensure-vendor.py")"
if [[ -z "$CACHE_DIR" || ! -d "$CACHE_DIR" ]]; then
  notify-send -u critical "Mesh Peek" "ensure-vendor.py failed"
  exit 1
fi

PORT=$(python3 - <<'PY'
import socket
s = socket.socket()
s.bind(("127.0.0.1", 0))
print(s.getsockname()[1])
s.close()
PY
)

# Generate high-entropy random token
TOKEN=$(openssl rand -hex 16 2>/dev/null || python3 -c "import secrets; print(secrets.token_hex(16))")

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/omarchy-meshpeek-web"
# Ensure STATE_DIR has restricted permissions (user-only)
rm -rf "$STATE_DIR"
mkdir -p "$STATE_DIR"
chmod 0700 "$STATE_DIR"

ext="${MODEL##*.}"
MODEL_LINK="$STATE_DIR/model.$ext"
ln -sfn "$MODEL" "$MODEL_LINK"

# Runtime layout:
#   STATE/viewer/index.html
#   STATE/viewer/vendor/three/three.module.js
#   STATE/viewer/vendor/three/examples/jsm/...
mkdir -p "$STATE_DIR/viewer/vendor"
cp -a "$VIEWER_SRC" "$STATE_DIR/viewer/index.html"
# Symlink cache into vendor/three so importmap ./vendor/three/... resolves
ln -sfn "$CACHE_DIR" "$STATE_DIR/viewer/vendor/three"

INDEX_REL="viewer/index.html"

# Token-authenticated HTTP server with lifecycle tracking
python3 - "$PORT" "$STATE_DIR" "$MODEL_LINK" "$TOKEN" <<'PY' &
import http.server
import os
import socketserver
import sys
import urllib.parse

port = int(sys.argv[1])
root = sys.argv[2]
model = sys.argv[3]
expected_token = sys.argv[4]
os.chdir(root)


class TokenAuthHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def check_token(self):
        parsed = urllib.parse.urlparse(self.path)
        qs = urllib.parse.parse_qs(parsed.query)
        tokens = qs.get("token", [])
        if tokens and tokens[0] == expected_token:
            return True
        auth = self.headers.get("Authorization", "")
        if auth.startswith("Bearer ") and auth[7:] == expected_token:
            return True
        return False

    def do_GET(self):
        if not self.check_token():
            self.send_error(403, "Forbidden: invalid or missing token")
            return

        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        if path.startswith("/model."):
            self.path = "/" + os.path.basename(model) + "?" + parsed.query
        return super().do_GET()

    def do_HEAD(self):
        if not self.check_token():
            self.send_error(403, "Forbidden: invalid or missing token")
            return
        return super().do_HEAD()


socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("127.0.0.1", port), TokenAuthHandler) as httpd:
    httpd.serve_forever()
PY
SERVER_PID=$!

UP_AXIS="${MODELVIEW_UP:-+Z}"
URL="http://127.0.0.1:${PORT}/viewer/index.html?token=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$TOKEN")&file=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "/model.$ext")&up=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$UP_AXIS")"

CHROME=""
for c in chromium chromium-browser google-chrome-stable google-chrome brave; do
  if command -v "$c" >/dev/null 2>&1; then CHROME=$c; break; fi
done
if [[ -z "$CHROME" ]]; then
  kill "$SERVER_PID" 2>/dev/null || true
  notify-send -u critical "Mesh Peek" "No Chromium/Chrome found for Three.js viewer"
  exit 127
fi

# Launch Chromium and track its lifecycle
"$CHROME" --new-window --app="$URL" >/dev/null 2>&1 &
CHROME_PID=$!

# Maximum lifetime safety net (30 minutes)
MAX_LIFETIME=1800

cleanup() {
  kill "$SERVER_PID" 2>/dev/null || true
  rm -rf "$STATE_DIR" 2>/dev/null || true
}

trap cleanup EXIT

# Wait for Chromium to exit or max lifetime, whichever comes first
ELAPSED=0
POLL_INTERVAL=2
while kill -0 "$CHROME_PID" 2>/dev/null; do
  sleep "$POLL_INTERVAL"
  ELAPSED=$((ELAPSED + POLL_INTERVAL))
  if [[ "$ELAPSED" -ge "$MAX_LIFETIME" ]]; then
    break
  fi
done

exit 0

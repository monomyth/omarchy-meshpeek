#!/usr/bin/env bash
# Serve viewer/ + model over localhost and open Chromium (Three.js).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VIEWER="$PLUGIN_DIR/viewer/index.html"
MODEL="${1:-}"
if [[ -z "$MODEL" || ! -f "$MODEL" ]]; then
  notify-send -u low "Mesh Peek" "No model file for web viewer"
  echo "no file: $MODEL" >&2
  exit 1
fi
if [[ ! -f "$VIEWER" ]]; then
  notify-send -u critical "Mesh Peek" "viewer/index.html missing"
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

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/omarchy-meshpeek-web"
mkdir -p "$STATE_DIR"
ext="${MODEL##*.}"
MODEL_LINK="$STATE_DIR/model.$ext"
ln -sfn "$MODEL" "$MODEL_LINK"
cp -f "$VIEWER" "$STATE_DIR/index.html"

python3 - "$PORT" "$STATE_DIR" "$MODEL_LINK" <<'PY' &
import http.server, socketserver, sys, os, urllib.parse
port = int(sys.argv[1])
root = sys.argv[2]
model = sys.argv[3]
os.chdir(root)
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a):
        pass
    def do_GET(self):
        path = urllib.parse.urlparse(self.path).path
        if path.startswith("/model."):
            self.path = "/" + os.path.basename(model)
        return super().do_GET()
socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("127.0.0.1", port), H) as httpd:
    httpd.serve_forever()
PY
SERVER_PID=$!

UP_AXIS="${MODELVIEW_UP:-+Z}"
URL="http://127.0.0.1:${PORT}/index.html?file=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "/model.$ext")&up=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$UP_AXIS")"

CHROME=""
for c in chromium chromium-browser google-chrome-stable google-chrome brave; do
  if command -v "$c" >/dev/null 2>&1; then CHROME=$c; break; fi
done
if [[ -z "$CHROME" ]]; then
  kill "$SERVER_PID" 2>/dev/null || true
  notify-send -u critical "Mesh Peek" "No Chromium/Chrome found for Three.js viewer"
  exit 127
fi

("$CHROME" --new-window --app="$URL" >/dev/null 2>&1 || "$CHROME" --new-window "$URL" >/dev/null 2>&1 || true) &

( sleep 7200; kill "$SERVER_PID" 2>/dev/null || true ) &
disown "$SERVER_PID" 2>/dev/null || true
disown 2>/dev/null || true
exit 0

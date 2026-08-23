#!/usr/bin/env bash
# omarchy:summary=Open STL/3MF (f3d or Chromium+Three.js) — Files selection, else picker
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/modelview"
LAST_FILE="$STATE_DIR/last"
mkdir -p "$STATE_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UP_AXIS="${MODELVIEW_UP:-+Z}"
PROFILE="${MODELVIEW_PROFILE:-clay}"
MODE="${1:-view}"
shift || true

case "$MODE" in
  clay|studio)
    PROFILE="$MODE"
    MODE="${1:-view}"
    shift || true
    ;;
esac

MODEL_EXT_RE='\.(stl|3mf|obj|gltf|glb)$'

clay_flags() {
  F3D_FLAGS=(
    --up="$UP_AXIS"
    --grid
    --axis
    --filename
    --anti-aliasing=fxaa
    --background-color=0.22,0.23,0.25
    --color=0.78,0.78,0.80
    --roughness=0.55
    --metallic=0
    --hdri-ambient
    --light-intensity=0.85
    --camera-azimuth-angle=40
    --camera-elevation-angle=28
    --camera-zoom-factor=1.0
  )
}

studio_flags() {
  F3D_FLAGS=(
    --up="$UP_AXIS"
    --grid
    --axis
    --filename
    --camera-direction=-1,-0.35,-1
    --camera-zoom-factor=0.9
    --camera-azimuth-angle=-28
    --camera-elevation-angle=18
    --color=0.38,0.39,0.40
    --roughness=0.48
    --metallic=0
    --background-color=0.22,0.22,0.24
    --light-intensity=1.15
    --hdri-ambient
    --anti-aliasing=fxaa
    --tone-mapping
    --ambient-occlusion
    --backface-type=visible
  )
}

need_f3d() {
  if ! command -v f3d >/dev/null 2>&1; then
    notify-send -u critical "Model View" "f3d is not installed. Try: yay -S f3d (or leave MODELVIEW_BACKEND=threejs)"
    echo "f3d missing" >&2
    exit 127
  fi
}

backend() {
  printf '%s' "${MODELVIEW_BACKEND:-threejs}"
}

need_viewer() {
  case "$(backend)" in
    threejs|web|chromium)
      if [[ ! -x "$SCRIPT_DIR/open-web.sh" ]]; then
        notify-send -u critical "Model View" "open-web.sh missing"
        exit 127
      fi
      if ! command -v chromium >/dev/null 2>&1 && ! command -v chromium-browser >/dev/null 2>&1; then
        notify-send -u critical "Model View" "Chromium required for Three.js viewer"
        exit 127
      fi
      ;;
    *)
      need_f3d
      ;;
  esac
}

record_last() {
  printf '%s\n' "$1" >"$LAST_FILE"
}

is_model() {
  [[ -n "$1" && -f "$1" && "$1" =~ $MODEL_EXT_RE ]]
}

uri_list_to_path() {
  python3 -c 'import sys,urllib.parse
raw=sys.argv[1]
for line in raw.splitlines():
  line=line.strip()
  if not line or line.startswith("#"): continue
  if line.startswith("file:"):
    print(urllib.parse.unquote(urllib.parse.urlparse(line).path)); break
  if line.startswith("/"):
    print(line); break' "$1"
}

nautilus_address() {
  hyprctl clients -j 2>/dev/null | jq -r '.[] | select((.class // "") | test("Nautilus|org.gnome.Nautilus"; "i")) | select(.mapped == true) | .address' 2>/dev/null | head -1
}

files_focused() {
  local c
  c=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // empty' 2>/dev/null || true)
  case "$c" in
    org.gnome.Nautilus|Nautilus|*[Nn]autilus*) return 0 ;;
  esac
  # Also true if Files is open — shortcut often fires with focus elsewhere
  [[ -n "$(nautilus_address)" ]]
}

read_clipboard_model() {
  local uris path
  uris=$(wl-paste -t text/uri-list 2>/dev/null || true)
  if [[ -z "$uris" ]]; then
    uris=$(wl-paste 2>/dev/null || true)
  fi
  [[ -z "$uris" ]] && return 1
  path=$(uri_list_to_path "$uris")
  path=$(printf '%s' "$path" | tr -d '\r')
  is_model "$path" || return 1
  printf '%s' "$path"
}

files_selection_path() {
  local addr prev path
  addr=$(nautilus_address)
  [[ -n "$addr" ]] || return 1
  prev=$(hyprctl activewindow -j 2>/dev/null | jq -r '.address // empty' 2>/dev/null || true)
  hyprctl dispatch focuswindow "address:$addr" >/dev/null 2>&1 || true
  sleep 0.08
  # Hyprland expects CONTROL, not CTRL
  hyprctl dispatch sendshortcut "CONTROL,C," >/dev/null 2>&1 || \
    hyprctl dispatch sendshortcut "CTRL,C," >/dev/null 2>&1 || true
  sleep 0.18
  path=$(read_clipboard_model || true)
  if [[ -n "$prev" && "$prev" != "$addr" ]]; then
    hyprctl dispatch focuswindow "address:$prev" >/dev/null 2>&1 || true
  fi
  [[ -n "$path" ]] || return 1
  printf '%s' "$path"
}

find_newest() {
  local dirs=("$HOME/Downloads" "$HOME/Prints" "$HOME/print" "$HOME/models")
  if [[ -n "${MODELVIEW_WATCH_DIRS:-}" ]]; then
    IFS=':' read -r -a extra <<<"$MODELVIEW_WATCH_DIRS"
    dirs+=("${extra[@]}")
  fi
  local found=""
  found=$(find "${dirs[@]}" -maxdepth 3 \( -iname '*.stl' -o -iname '*.3mf' -o -iname '*.obj' -o -iname '*.gltf' -o -iname '*.glb' \) -type f -printf '%T@ %p\n' 2>/dev/null \
    | sort -nr \
    | head -1 \
    | cut -d' ' -f2-)
  printf '%s' "$found"
}

select_flags() {
  case "$PROFILE" in
    studio) studio_flags ;;
    *) clay_flags ;;
  esac
}

open_path() {
  local path="$1"
  local inspect="${2:-0}"
  if [[ -z "$path" || ! -f "$path" ]]; then
    notify-send -u low "Model View" "No model file to open"
    echo "no file: $path" >&2
    exit 1
  fi
  record_last "$path"
  case "$(backend)" in
    threejs|web|chromium)
      if [[ "$inspect" == "1" ]] && command -v f3d >/dev/null 2>&1; then
        select_flags
        exec f3d "${F3D_FLAGS[@]}" --edges --line-width=1 "$path"
      fi
      notify-send -u low -t 1200 "Model View" "Web: $(basename "$path")"
      exec "$SCRIPT_DIR/open-web.sh" "$path"
      ;;
  esac
  select_flags
  if [[ "$inspect" == "1" ]]; then
    exec f3d "${F3D_FLAGS[@]}" --edges --line-width=1 "$path"
  else
    exec f3d "${F3D_FLAGS[@]}" "$path"
  fi
}

view_flow() {
  # Outside Files — confirm picker near newest model
  need_viewer
  local path="" newest folder hint
  newest=$(find_newest)
  if [[ -n "$newest" && -f "$newest" ]]; then
    folder=$(dirname "$newest")
    hint=$(basename "$newest")
    path=$("$SCRIPT_DIR/select_confirm.py" \
      --title "Model View — confirm $hint (or pick another)" \
      --folder "$folder" \
      --extensions "stl 3mf obj gltf glb" || true)
  else
    path=$("$SCRIPT_DIR/select_confirm.py" \
      --title "Model View — pick a model" \
      --folder "${HOME}/Downloads" \
      --extensions "stl 3mf obj gltf glb" || true)
  fi
  path=$(printf '%s' "${path:-}" | tr -d '\r' | head -1)
  [[ -z "$path" ]] && exit 0
  open_path "$path" 0
}

case "$MODE" in
  from-clipboard|clipboard)
    need_viewer
    path=$(read_clipboard_model || true)
    if [[ -z "$path" ]]; then
      # uri-list may need a beat after Hypr copy
      sleep 0.05
      path=$(read_clipboard_model || true)
    fi
    if [[ -n "$path" ]]; then
      open_path "$path" 0
    else
      # empty selection in Files → same picker as other apps
      view_flow
    fi
    ;;
  view|"")
    view_flow
    ;;
  open)
    need_viewer
    open_path "${1:-}" 0
    ;;
  inspect|edges)
    need_viewer
    open_path "${1:-$(find_newest)}" 1
    ;;
  last|pick)
    view_flow
    ;;
  web|threejs)
    export MODELVIEW_BACKEND=threejs
    if [[ -n "${1:-}" ]]; then
      need_viewer
      open_path "$1" 0
    else
      view_flow
    fi
    ;;
  *)
    echo "usage: open.sh [clay|studio] view|open <path>|inspect [path]|web [path]" >&2
    echo "  MODELVIEW_BACKEND=threejs|f3d  (default threejs)" >&2
    exit 2
    ;;
esac

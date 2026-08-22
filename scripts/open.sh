#!/usr/bin/env bash
# omarchy:summary=Open an STL/3MF (or path) in f3d for a quick glance
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/modelview"
LAST_FILE="$STATE_DIR/last"
mkdir -p "$STATE_DIR"

UP_AXIS="${MODELVIEW_UP:-+Z}"
MODE="${1:-last}"
shift || true

need_f3d() {
  if ! command -v f3d >/dev/null 2>&1; then
    notify-send -u critical "Model View" "f3d is not installed. Try: yay -S f3d  (or pacman -S f3d)"
    echo "f3d missing" >&2
    exit 127
  fi
}

record_last() {
  local path="$1"
  printf '%s\n' "$path" >"$LAST_FILE"
}

find_last() {
  local dirs=("$HOME/Downloads" "$HOME/Prints" "$HOME/print" "$HOME/models")
  if [[ -n "${MODELVIEW_WATCH_DIRS:-}" ]]; then
    IFS=':' read -r -a extra <<<"$MODELVIEW_WATCH_DIRS"
    dirs+=("${extra[@]}")
  fi

  # Newest STL/3MF under watch dirs (depth-limited).
  local found=""
  found=$(find "${dirs[@]}" -maxdepth 3 \( -iname '*.stl' -o -iname '*.3mf' -o -iname '*.obj' -o -iname '*.gltf' -o -iname '*.glb' \) -type f -printf '%T@ %p\n' 2>/dev/null \
    | sort -nr \
    | head -1 \
    | cut -d' ' -f2-)
  if [[ -z "$found" && -f "$LAST_FILE" ]]; then
    found=$(cat "$LAST_FILE")
  fi
  printf '%s' "$found"
}

open_path() {
  local path="$1"
  if [[ -z "$path" || ! -f "$path" ]]; then
    notify-send -u low "Model View" "No model file to open"
    echo "no file: $path" >&2
    exit 1
  fi
  record_last "$path"
  # Defaults are SE placeholders; Blender lane owns camera/fit taste.
  # --up for print axis; grid+axis for bounds glance; filename in title.
  exec f3d \
    --up="$UP_AXIS" \
    --grid \
    --axis \
    --filename \
    --max-size=2048 \
    "$path"
}

case "$MODE" in
  last)
    need_f3d
    open_path "$(find_last)"
    ;;
  pick)
    need_f3d
    path=$(omarchy-file-select --title "Model View" --extensions "stl 3mf obj gltf glb" || true)
    if [[ -z "${path:-}" ]]; then
      exit 0
    fi
    open_path "$path"
    ;;
  open)
    need_f3d
    open_path "${1:-}"
    ;;
  *)
    echo "usage: open.sh last|pick|open <path>" >&2
    exit 2
    ;;
esac

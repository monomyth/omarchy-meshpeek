#!/usr/bin/env bash
# omarchy:summary=Open an STL/3MF (or path) in f3d for a quick glance
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/modelview"
LAST_FILE="$STATE_DIR/last"
mkdir -p "$STATE_DIR"

UP_AXIS="${MODELVIEW_UP:-+Z}"
MODE="${1:-last}"
shift || true

# Optional profile: clay (default, Blender Expert) | studio (3D Artist) | inspect (edges)
PROFILE="${MODELVIEW_PROFILE:-clay}"

# Resolve leading profile token if present: open.sh studio last | open.sh last
case "$MODE" in
  clay|studio)
    PROFILE="$MODE"
    MODE="${1:-last}"
    shift || true
    ;;
esac

# Blender Expert — default clay / Z-up print glance
clay_flags() {
  F3D_FLAGS=(
    --up="$UP_AXIS"
    --grid
    --axis
    --filename
    --anti-aliasing
    --background-color=0.22,0.23,0.25
    --color=0.78,0.78,0.80
    --roughness=0.55
    --metallic=0
    --hdri-ambient=0.85
    --camera-azimuth=40
    --camera-elevation=22
    --camera-zoom=1.0
    --no-render-pass-volume
  )
}

# 3D Artist — optional studio plastic hero 3/4
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
    notify-send -u critical "Model View" "f3d is not installed. Try: yay -S f3d  (or pacman -S f3d)"
    echo "f3d missing" >&2
    exit 127
  fi
}

record_last() {
  printf '%s\n' "$1" >"$LAST_FILE"
}

find_last() {
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
  if [[ -z "$found" && -f "$LAST_FILE" ]]; then
    found=$(cat "$LAST_FILE")
  fi
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
  select_flags
  if [[ "$inspect" == "1" ]]; then
    exec f3d "${F3D_FLAGS[@]}" --edges --line-width=1 "$path"
  else
    exec f3d "${F3D_FLAGS[@]}" "$path"
  fi
}

case "$MODE" in
  last)
    need_f3d
    open_path "$(find_last)" 0
    ;;
  pick)
    need_f3d
    path=$(omarchy-file-select --title "Model View" --extensions "stl 3mf obj gltf glb" || true)
    [[ -z "${path:-}" ]] && exit 0
    open_path "$path" 0
    ;;
  inspect|edges)
    need_f3d
    if [[ -n "${1:-}" ]]; then
      open_path "$1" 1
    else
      open_path "$(find_last)" 1
    fi
    ;;
  open)
    need_f3d
    open_path "${1:-}" 0
    ;;
  *)
    echo "usage: open.sh [clay|studio] last|pick|open <path>|inspect [path]" >&2
    exit 2
    ;;
esac

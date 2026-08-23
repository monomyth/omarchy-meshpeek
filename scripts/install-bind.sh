#!/usr/bin/env bash
# Opt-in: add Super+Shift+Ctrl+V Mesh Peek bind if the chord is free.
set -euo pipefail

BINDINGS="${HYPR_BINDINGS:-$HOME/.config/hypr/bindings.lua}"
CHORD_LUA='SUPER + SHIFT + CTRL + V'
PLUGIN_ID='io.github.monomyth.meshpeek'
SCRIPT_PATH="$HOME/.config/omarchy/plugins/$PLUGIN_ID/scripts/open.sh"

normalize_chord() {
  # Uppercase, drop pluses/spaces, sort tokens so SUPER SHIFT CTRL V == SHIFT CTRL SUPER V
  echo "$1" | tr '[:lower:]' '[:upper:]' | tr -cs 'A-Z0-9' ' ' | xargs -n1 | sort | xargs
}

TARGET_NORM="$(normalize_chord "SUPER SHIFT CTRL V")"

chord_taken_by_other() {
  # Returns 0 if another (non-Mesh-Peek) binding owns the chord.
  local print
  print="$(omarchy menu keybindings --print 2>/dev/null || true)"
  if [[ -z "$print" ]]; then
    return 1
  fi
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    # lines like: SUPER SHIFT CTRL + V                → Mesh Peek
    local left="${line%%→*}"
    local right="${line#*→}"
    left="$(echo "$left" | sed 's/+/ /g')"
    local norm
    norm="$(normalize_chord "$left")"
    if [[ "$norm" == "$TARGET_NORM" ]]; then
      if echo "$right" | grep -qi 'mesh peek'; then
        echo "already:meshpeek"
        return 2
      fi
      echo "conflict:$line"
      return 0
    fi
  done <<< "$print"
  return 1
}

already_in_file() {
  [[ -f "$BINDINGS" ]] || return 1
  grep -q 'meshpeek_open' "$BINDINGS" 2>/dev/null && return 0
  grep -qi 'Mesh Peek' "$BINDINGS" 2>/dev/null && return 0
  grep -Eq 'SUPER \+ SHIFT \+ CTRL \+ V|SUPER \+ CTRL \+ SHIFT \+ V' "$BINDINGS" 2>/dev/null && return 0
  return 1
}

if [[ ! -f "$SCRIPT_PATH" ]]; then
  echo "Mesh Peek open.sh not found at:" >&2
  echo "  $SCRIPT_PATH" >&2
  echo "Install the plugin first:" >&2
  echo "  omarchy plugin add https://github.com/monomyth/omarchy-meshpeek.git --enable" >&2
  exit 1
fi

if already_in_file; then
  echo "Mesh Peek bind already present in $BINDINGS — nothing to do."
  exit 0
fi

status=0
result="$(chord_taken_by_other)" || status=$?
if [[ "$status" -eq 2 ]] || [[ "$result" == already:meshpeek ]]; then
  echo "Super+Shift+Ctrl+V is already Mesh Peek — nothing to do."
  exit 0
fi
if [[ "$status" -eq 0 ]]; then
  echo "Super+Shift+Ctrl+V is already bound:" >&2
  echo "  ${result#conflict:}" >&2
  echo "Pick another chord, or add manually from bindings.hypr.lua.example" >&2
  exit 2
fi

mkdir -p "$(dirname "$BINDINGS")"
if [[ ! -f "$BINDINGS" ]]; then
  cat > "$BINDINGS" <<'HDR'
-- Keep only your personal keybinding overrides here.
HDR
fi

{
  echo ""
  echo "-- Mesh Peek (added by scripts/install-bind.sh)"
  echo "local function meshpeek_open()"
  echo "  return function()"
  echo "    local win = hl.get_active_window()"
  echo "    local class = win and (win.class or win.initialClass or \"\") or \"\""
  echo "    local in_files = type(class) == \"string\" and class:find(\"Nautilus\") ~= nil"
  echo "    local home = os.getenv(\"HOME\") or \"\""
  echo "    local script = home .. \"/.config/omarchy/plugins/$PLUGIN_ID/scripts/open.sh\""
  echo ""
  echo "    if in_files then"
  echo "      hl.dispatch(hl.dsp.exec_cmd(\"wl-copy --clear\"))"
  echo "      hl.timer(function()"
  echo "        hl.dispatch(hl.dsp.send_key_state({ mods = \"CTRL\", key = \"C\", state = \"down\" }))"
  echo "        hl.timer(function()"
  echo "          hl.dispatch(hl.dsp.send_key_state({ mods = \"CTRL\", key = \"C\", state = \"up\" }))"
  echo "          hl.timer(function()"
  echo "            hl.dispatch(hl.dsp.exec_cmd(\"bash \" .. script .. \" from-clipboard\"))"
  echo "          end, { timeout = 100, type = \"oneshot\" })"
  echo "        end, { timeout = 50, type = \"oneshot\" })"
  echo "      end, { timeout = 40, type = \"oneshot\" })"
  echo "    else"
  echo "      hl.dispatch(hl.dsp.exec_cmd(\"bash \" .. script .. \" view\"))"
  echo "    end"
  echo "  end"
  echo "end"
  echo ""
  echo "o.bind(\"$CHORD_LUA\", \"Mesh Peek\", meshpeek_open(), { release = true })"
} >> "$BINDINGS"

echo "Added Mesh Peek bind to $BINDINGS"
echo "Reload Hyprland config if the chord doesn't take effect (omarchy often hot-reloads)."

# Mesh Peek

Keyboard-first STL / 3MF glance for [Omarchy](https://omarchy.org/) Quattro.

One shortcut opens a clay-shaded Three.js viewer in Chromium. Not a slicer, not a CAD suite. Just a quick look at the mesh. STL, 3MF, OBJ, glTF, and glb are supported. Print/CAD files are Z-up by default.

![preview](preview.png)

## Install

```sh
omarchy plugin add https://github.com/monomyth/omarchy-meshpeek.git --enable
```

Add this to `~/.config/hypr/bindings.lua` (also in `bindings.hypr.lua.example`):

```lua
-- Mesh Peek — Files focused → copy selection then open; otherwise newest-folder picker.
local function meshpeek_open()
  return function()
    local win = hl.get_active_window()
    local class = win and (win.class or win.initialClass or "") or ""
    local in_files = type(class) == "string" and class:find("Nautilus") ~= nil
    local home = os.getenv("HOME") or ""
    local script = home .. "/.config/omarchy/plugins/io.github.monomyth.meshpeek/scripts/open.sh"

    if in_files then
      hl.dispatch(hl.dsp.exec_cmd("wl-copy --clear"))
      hl.timer(function()
        hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL", key = "C", state = "down" }))
        hl.timer(function()
          hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL", key = "C", state = "up" }))
          hl.timer(function()
            hl.dispatch(hl.dsp.exec_cmd("bash " .. script .. " from-clipboard"))
          end, { timeout = 100, type = "oneshot" })
        end, { timeout = 50, type = "oneshot" })
      end, { timeout = 40, type = "oneshot" })
    else
      hl.dispatch(hl.dsp.exec_cmd("bash " .. script .. " view"))
    end
  end
end

o.bind("SUPER + SHIFT + CTRL + V", "Mesh Peek", meshpeek_open(), { release = true })
```

Needs Chromium (or Chrome), plus `wl-paste`, `jq`, and `hyprctl`. First open caches Three.js under `~/.cache/omarchy/meshpeek/` (once; refreshes about weekly).

## Shortcut

**Super+Shift+Ctrl+V**

| Situation | What happens |
| --- | --- |
| Files focused, model selected | Opens that model |
| Files focused, nothing selected | Picker (won't reopen a stale clipboard file) |
| Any other app | Picker near newest model under Downloads / Prints |

## In the viewer

| Input | Action |
| --- | --- |
| Drag | Orbit |
| Scroll | Zoom |
| Right-drag | Pan |

Close the Chromium window when you're done. An optional bar icon exists; the keybind is the intended UI.

## Remove

```sh
omarchy plugin remove io.github.monomyth.meshpeek
```

## Optional

Default backend: **f3d if installed, otherwise Three.js**.

```bash
export MODELVIEW_UP=+Z            # or +Y / -Z / -Y
export MODELVIEW_BACKEND=threejs  # or f3d (must be installed)
```

## License

MIT

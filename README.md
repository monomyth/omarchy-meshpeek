# Mesh Peek

Quick look at STL / 3MF / OBJ / glTF models on [Omarchy](https://omarchy.org/) Quattro — one shortcut, no full CAD app.

Hit **Super+Shift+Ctrl+V**. If Files has a model selected, that file opens. If nothing’s selected (or you’re in another app), you get a file picker near your newest download. The viewer is a simple clay-shaded 3D glance: drag to orbit, scroll to zoom, right-drag to pan. Print/CAD files are Z-up by default.

![preview](preview.png)

## Install

```sh
omarchy plugin add https://github.com/monomyth/omarchy-meshpeek.git --enable
```

Add the keybind from `bindings.hypr.lua.example` to `~/.config/hypr/bindings.lua` (one Super+Shift+Ctrl+V binding).

Needs Chromium (or Chrome). First open downloads Three.js into `~/.cache/omarchy/meshpeek/` (once; refreshes about weekly). Also uses `wl-paste`, `jq`, and `hyprctl`.

## Usage

| Situation | What happens |
| --- | --- |
| Files focused, model selected | Opens that model |
| Files focused, nothing selected | Picker (won’t reopen a stale clipboard file) |
| Any other app | Picker near newest model under Downloads / Prints |

Close the Chromium window when you’re done. Optional bar icon exists but the keybind is the intended UI.

## Remove

```sh
omarchy plugin remove io.github.monomyth.meshpeek
```

## Optional

```bash
export MODELVIEW_UP=+Z    # or +Y / -Z / -Y
export MODELVIEW_BACKEND=f3d   # only if you have f3d installed
```

## License

MIT

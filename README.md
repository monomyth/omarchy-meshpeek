# Mesh Peek (`io.github.monomyth.meshpeek`)

Keyboard-first STL/3MF glance for Omarchy Quattro.

Opens models in Chromium with Three.js (clay, Z-up). Three.js is **not** in this repo — first launch caches `three@0.170` under `~/.cache/omarchy/meshpeek/` (weekly refresh). Optional: set `MODELVIEW_BACKEND=f3d` if `f3d` is installed.

## One shortcut

`Super + Shift + Ctrl + V` (on key release)

1. **Files focused + model selected** → open that file (no picker).
2. **Files focused + nothing selected** → confirm picker.
3. **Other app focused** → picker near newest download.

## Install

```sh
omarchy plugin add https://github.com/monomyth/omarchy-meshpeek.git --enable
```

Copy the Hypr bind from `bindings.hypr.lua.example` into `~/.config/hypr/bindings.lua` (or merge the snippet).

### Dependencies

- `chromium` (default viewer)
- `wl-paste`, `jq`, `hyprctl`, `python3`, `curl`
- Network once to fill the Three.js cache (jsDelivr)
- Optional: `f3d` if you force `MODELVIEW_BACKEND=f3d`

## Remove

```sh
omarchy plugin remove io.github.monomyth.meshpeek
```

## Configure

```bash
export MODELVIEW_UP=+Z          # print/CAD default
export MODELVIEW_BACKEND=threejs # or f3d
```

## License

MIT

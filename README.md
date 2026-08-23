# Model View (`local.modelview`)

Keyboard-first STL/3MF glance for Omarchy Quattro.

Default display: [f3d](https://f3d.app). Alternate: Chromium + Three.js (`MODELVIEW_BACKEND=threejs`).

## One shortcut

`Super + Shift + Ctrl + V` (on key release)

1. **Files focused + model selected** → opens that file (no picker).
2. **Files focused + nothing selected** → confirm picker (not stale clipboard).
3. **Other app focused** → picker near newest download.

## Backends

```bash
# default
unset MODELVIEW_BACKEND   # f3d

# Chromium + Three.js (clay lighting, OrbitControls)
export MODELVIEW_BACKEND=threejs
# or one-shot:
~/.config/omarchy/plugins/local.modelview/scripts/open.sh web /path/to/model.stl
```

Three.js loads `three@0.170` from unpkg (needs network once). A local HTTP server serves the model file.

## Install

See bindings example. Needs `wl-paste`, `jq`, `hyprctl`, and either `f3d` or `chromium`.

MIT

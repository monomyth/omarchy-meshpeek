# Model View (`local.modelview`)

Keyboard-first STL/3MF glance for Omarchy Quattro.

**Default display:** Chromium + Three.js. Fallback: [f3d](https://f3d.app) via `MODELVIEW_BACKEND=f3d`.

## One shortcut

`Super + Shift + Ctrl + V` (on key release)

1. **Files focused + model selected** → opens that file (no picker).
2. **Files focused + nothing selected** → confirm picker (not stale clipboard).
3. **Other app focused** → picker near newest download.

## Backends

```bash
# default (Chromium + Three.js)
unset MODELVIEW_BACKEND   # same as threejs

# force f3d
export MODELVIEW_BACKEND=f3d
```

Three.js loads `three@0.170` from unpkg (needs network once). A local HTTP server serves the model file.

## Install

See bindings example. Needs `wl-paste`, `jq`, `hyprctl`, and `chromium` (or `f3d` if you switch backends).

MIT

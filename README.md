# Mesh Peek (`local.meshpeek`)

Keyboard-first STL/3MF glance for Omarchy Quattro.

**Default display:** [f3d](https://f3d.app) when installed, otherwise Chromium + Three.js.

## One shortcut

`Super + Shift + Ctrl + V` (on key release)

1. **Files focused + model selected** → opens that file (no picker).
2. **Files focused + nothing selected** → confirm picker (not stale clipboard).
3. **Other app focused** → picker near newest download.

## Backends

```bash
# auto (default): f3d if on PATH, else threejs
unset MODELVIEW_BACKEND

# force either
export MODELVIEW_BACKEND=f3d
export MODELVIEW_BACKEND=threejs
```

Three.js `0.170` is vendored under `viewer/vendor/` (no CDN at runtime). A local HTTP server on 127.0.0.1 serves the model. Viewer is Z-up (print/CAD), overridable with `MODELVIEW_UP`.

## Install

See bindings example. Needs `wl-paste`, `jq`, `hyprctl`, plus `f3d` and/or `chromium`.

MIT

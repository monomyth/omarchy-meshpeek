# Model View (`local.modelview`)

Keyboard-first **STL/3MF glance** for Omarchy Quattro. Opens meshes in
[`f3d`](https://f3d.app) so you can check an export without launching Blender.

Not an in-shell WebView (Omarchy/Quickshell does not ship Qt WebEngine).

## Keybinds (Omarchy-native)

Add to `~/.config/hypr/bindings.lua` (see `bindings.snippet.lua`):

| Keys | Action |
|------|--------|
| `Super + Shift + Ctrl + M` | Open **last** STL/3MF under Downloads/Prints (or remembered path) |
| `Super + Shift + Alt + M` | **Pick** a file (`omarchy-file-select`) then open |

IPC (same actions):

```bash
omarchy-shell local.modelview last
omarchy-shell local.modelview pick
omarchy-shell local.modelview open /path/to/part.stl
```

## Dependencies

- Omarchy Quattro
- [`f3d`](https://f3d.app) on PATH (`pacman -S f3d` / `yay -S f3d`)
- `omarchy-file-select` (ships with Omarchy) for pick mode
- `notify-send` when f3d is missing

## Install

```bash
mkdir -p ~/.config/omarchy/plugins/local.modelview
cp -a manifest.json Service.qml BarWidget.qml scripts README.md LICENSE bindings.snippet.lua \
  ~/.config/omarchy/plugins/local.modelview/
omarchy-shell shell rescanPlugins
omarchy plugin enable local.modelview
# paste bindings.snippet.lua into ~/.config/hypr/bindings.lua
```

Bar icon is **off by default** (`showIcon: false`). Enable from bar settings if you want one.

## Defaults / ownership

- SE: plugin shell, IPC, binds, last-export search, f3d wrapper
- Blender Expert: camera/fit/material taste (`f3d` flags in `scripts/open.sh`)
- CAD: print-axis / up-axis expectations (`+Z` default)

## License

MIT

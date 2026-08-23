-- Model View — one shortcut (paste into ~/.config/hypr/bindings.lua)
-- Prefer the Lua modelview_open() in bindings.hypr.lua.example (Files copy + picker).
-- Minimal string form (picker / open.sh view only):
o.bind("SUPER + SHIFT + CTRL + V", "Model View", "bash $HOME/.config/omarchy/plugins/local.modelview/scripts/open.sh view", { release = true })

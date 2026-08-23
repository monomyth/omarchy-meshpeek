-- Mesh Peek — one shortcut (paste into ~/.config/hypr/bindings.lua)
-- Prefer the Lua meshpeek_open() in bindings.hypr.lua.example (Files copy + picker).
-- Minimal string form (picker / open.sh view only):
o.bind("SUPER + SHIFT + CTRL + V", "Mesh Peek", "bash $HOME/.config/omarchy/plugins/io.github.monomyth.meshpeek/scripts/open.sh view", { release = true })

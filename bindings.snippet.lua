-- Mesh Peek — minimal string bind (picker / open.sh view only; no Files-selection path).
-- Prefer bindings.hypr.lua.example for Files-aware open.
o.bind("SUPER + SHIFT + CTRL + V", "Mesh Peek", "bash $HOME/.config/omarchy/plugins/io.github.monomyth.meshpeek/scripts/open.sh view", { release = true })

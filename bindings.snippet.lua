-- Model View (local.modelview) — paste into ~/.config/hypr/bindings.lua
-- Requires: omarchy plugin enable local.modelview; f3d installed

o.bind("SUPER + SHIFT + CTRL + M", "Model View (last export)", "omarchy-shell local.modelview last")
o.bind("SUPER + SHIFT + ALT + M", "Model View (pick file)", "omarchy-shell local.modelview pick")
o.bind("SUPER + SHIFT + CTRL + ALT + M", "Model View (inspect edges)", "omarchy-shell local.modelview inspect")
-- optional studio profile (3D Artist); leave unbound unless you want it:
-- o.bind("SUPER + SHIFT + CTRL + S", "Model View (studio)", "omarchy-shell local.modelview studio")

-- Keep the first five workspaces available even when empty, for trackpad swipes.
-- Use the monitor blocks assigned by Omarchy 4.5 in
-- ~/.local/state/omarchy/monitor-workspaces: DP-2 = 0, DP-3 = 1.
-- The bar labels each monitor's first five workspaces 1-5.
for _, screen in ipairs({ { name = "DP-2", base = 0 }, { name = "DP-3", base = 10 } }) do
  for slot = 1, 5 do
    hl.workspace_rule({
      workspace = tostring(screen.base + slot),
      monitor = screen.name,
      persistent = true,
    })
  end
end

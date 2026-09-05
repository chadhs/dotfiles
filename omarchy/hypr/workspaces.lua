-- Pin workspaces to monitors: 1,3,5 on DP-1; 2,4,6 on DP-2
-- Each monitor starts on its lowest pinned workspace (default = true).
for _, id in ipairs({ 1, 3, 5 }) do
  hl.workspace_rule({ workspace = tostring(id), monitor = "DP-1", persistent = true, default = id == 1 })
end
for _, id in ipairs({ 2, 4, 6 }) do
  hl.workspace_rule({ workspace = tostring(id), monitor = "DP-2", persistent = true, default = id == 2 })
end

-- ~/.config/rex/actions.lua
-- Custom actions standing in for tmux display-popup binds.

local SHELL = "com.superlogical.terminal.shell"

-- Directory of the block an action was invoked from, or nil.
local function block_cwd(ctx)
  if not ctx.block_id then return nil end
  local r = rex.block.call("com.superlogical.terminal", "pwd", { block_id = ctx.block_id })
  local pwd = r and r.pwd
  if not pwd then return nil end
  -- OSC 7 reports a file://host/path URL; turn it back into a path.
  pwd = pwd:gsub("^file://[^/]*", "")
  pwd = pwd:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
  return pwd
end

-- tmux: bind C-g display-popup -E -w 80% -h 80% -d '#{pane_current_path}' 'lazygit'
-- Rex has no popups; open lazygit in a new window (tab) of the current
-- session, in the current pane's directory, and close it when lazygit exits.
rex.action{
  name        = "lazygit",
  title       = "Open lazygit",
  description = "lazygit in a new tab, in the current pane's directory.",
  category    = "Git",
  run = function(ctx, args)
    local w, err = rex.session.new_window{
      window_label = "lazygit",
      layout = rex.layout.block{
        flavor  = SHELL,
        options = { command = { "lazygit" }, cwd = block_cwd(ctx) },
      },
    }
    if err ~= nil then error(err, 0) end
    return { window_id = w.window_id }
  end,
}

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

-- Go to the Nth session, in session-switcher order (session.list's order).
-- Bound to cmd+shift+1..9 in keys.lua.  session.select is an app (client)
-- action that only takes a session_id, so look the id up and queue it.
rex.action{
  name        = "goto_session",
  title       = "Go to Session N",
  description = "Switch to the Nth session in the session switcher.",
  category    = "Session",
  run = function(ctx, args)
    local index = tonumber(args and args.index)
    if not index then error("goto_session: index is required", 0) end
    local r = rex.call("session.list", {})
    local s = r and r.sessions and r.sessions[index]
    if not s then return end
    rex.client.queue("session.select", { session_id = s.session_id })
  end,
}

-- Toggle sidebar session folding: collapse every session but the current
-- one, then expand them all on the next press.  Rex has no toggle and no way
-- to read fold state, so the state lives here; it resets on config reload and
-- drifts if sessions are folded by hand (one extra press re-syncs it).
local others_collapsed = false
rex.action{
  name        = "toggle_collapse_others",
  title       = "Toggle Collapse Other Sessions",
  description = "Collapse every other session in the sidebar, or expand them all.",
  category    = "Session",
  run = function(ctx, args)
    if not others_collapsed then
      rex.client.queue("session.collapse_others", {})
    else
      local r = rex.call("session.list", {})
      for _, s in ipairs(r and r.sessions or {}) do
        rex.client.queue("session.expand", { session_id = s.session_id })
      end
    end
    others_collapsed = not others_collapsed
  end,
}

-- Restart every idle shell, e.g. after `brew upgrade` changed zsh, plugins
-- or PATH.  A pane counts as idle when its foreground process is the shell
-- itself; panes running something else (nvim, claude, a server) are left
-- alone and listed under `busy`.  Ctrl-U clears any half-typed line first.
--
--   rex do restart_shells                  -- every session
--   rex do restart_shells only=dotfiles    -- one session
--   rex do restart_shells dry_run=true     -- list what would restart
local SHELL_NAMES = { zsh = true, bash = true, fish = true }
rex.action{
  name        = "restart_shells",
  title       = "Restart Idle Shells",
  description = "exec a fresh login shell in every pane that is sitting at a prompt.",
  category    = "Session",
  args        = { only = "string?", dry_run = "boolean?", command = "string?" },
  run = function(ctx, args)
    local cmd = args.command or 'exec "$SHELL" -l'
    local r = rex.call("session.list", {})
    local restarted, busy = {}, {}
    for _, s in ipairs(r and r.sessions or {}) do
      if not args.only or s.label == args.only then
        -- session.view / block methods need this connection attached.
        local v, attached = rex.call("session.view", { session_id = s.session_id }), false
        if not v then
          local a = rex.call("session.attach", { session_id = s.session_id })
          v, attached = a and a.view, a ~= nil
        end
        for wi, w in ipairs(v and v.windows or {}) do
          for _, l in ipairs(w.layers or {}) do
            for _, b in ipairs(l.blocks or {}) do
              if b.creator_name == "com.superlogical.terminal" then
                local p = rex.call("block.method", { session_id = s.session_id, block_id = b.block_id, method = "process" })
                local fg = p and p.foreground
                local where = s.label .. ":" .. wi .. " " .. (w.label or "")
                if fg and SHELL_NAMES[fg.name] then
                  if not args.dry_run then
                    rex.call("block.method", {
                      session_id = s.session_id, block_id = b.block_id,
                      method = "write", args = { data = "\21" .. cmd .. "\n" },
                    })
                  end
                  restarted[#restarted + 1] = where
                else
                  busy[#busy + 1] = where .. " (" .. tostring(fg and (fg.argv0 or fg.name)) .. ")"
                end
              end
            end
          end
        end
        if attached then rex.call("session.detach", { session_id = s.session_id }) end
      end
    end
    return { [args.dry_run and "would_restart" or "restarted"] = restarted, busy = busy }
  end,
}

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

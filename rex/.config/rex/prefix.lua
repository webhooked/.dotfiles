-- ~/.config/rex/prefix.lua
-- ─────────────────────────────────────────────────────────────────────────
-- Ctrl+Space prefix bindings ported from ~/.config/herdr/config.toml, which
-- was itself ported from ~/.tmux.conf.  Each binding notes its origin.
--
--   herdr workspace = tmux session = Rex session
--   herdr tab       = tmux window  = Rex window (tab)
--   herdr pane      = tmux pane    = Rex pane (block)
--
-- Rex has no prefix setting; a prefix is just the first key of a sequence
-- ("ctrl+space>c").  Escape cancels a sequence.  These coexist with the
-- cmd+ bindings in keys.lua.
-- ─────────────────────────────────────────────────────────────────────────

local P = "ctrl+space>"

local function bind(key, action, args) rex.bind(P .. key, action, args) end

-- ── Prefix pass-through ──────────────────────────────────────────────────
-- tmux: bind C-space send-prefix / bind e send-prefix   (nested multiplexers)
bind("ctrl+space", "pane.send_key", { key = "ctrl+space" })
bind("e",          "pane.send_key", { key = "ctrl+space" })

-- ── Management ───────────────────────────────────────────────────────────
bind("r", "client.config.reload")                               -- herdr reload_config / tmux bind r
bind("shift+r", "client.mode.enter", { name = "resize" })       -- herdr resize_mode (see below)

-- ── Sessions (= herdr workspaces / tmux sessions) ────────────────────────
bind("shift+n", "session.new")        -- herdr new_workspace / tmux bind S
bind("shift+s", "session.new")
bind("w", "session.switch")           -- herdr fzf space-picker popup / tmux bind w,s
bind("s", "session.switch")
bind("x", "session.switch")           -- herdr workspace_picker
bind("g", "client.palette.toggle")    -- herdr goto navigator: palette searches sessions, tabs, commands
bind("a", "client.palette.toggle")
bind("b", "client.sidebar.toggle")    -- herdr toggle_sidebar

-- ── Tabs (= herdr tabs / tmux windows) ───────────────────────────────────
bind("c", "client.tab.new")           -- herdr new tab / tmux bind W
bind("n", "client.tab.previous")      -- herdr previous_tab / tmux bind n
bind("m", "client.tab.next")          -- herdr next_tab / tmux bind m
-- tmux bind N/M swap-window (herdr couldn't).  shift+n is taken by session.new
-- above (herdr new_workspace), so both moves live on alt.
bind("alt+n", "client.tab.move.backward")
bind("alt+m", "client.tab.move.forward")
bind(",", "client.tab.rename")
bind("shift+w", "client.tab.close")
for i = 1, 9 do                       -- herdr switch_tab / tmux select-window -t N
  bind(tostring(i), "client.tab.goto", { index = i })
end

-- ── Panes ────────────────────────────────────────────────────────────────
-- focus: herdr default / tmux bind h/j/k/l
bind("h", "pane.focus", { direction = "left" })
bind("j", "pane.focus", { direction = "down" })
bind("k", "pane.focus", { direction = "up" })
bind("l", "pane.focus", { direction = "right" })
bind("tab",       "pane.focus_next")      -- herdr cycle panes
bind("shift+tab", "pane.focus_previous")

-- swap: herdr swap_pane_* / tmux bind C-h/C-j/C-k/C-l swap-pane
bind("ctrl+h", "pane.move", { direction = "left" })
bind("ctrl+j", "pane.move", { direction = "down" })
bind("ctrl+k", "pane.move", { direction = "up" })
bind("ctrl+l", "pane.move", { direction = "right" })

-- split: herdr split_vertical (alt+7 is | on the Swedish layout) / tmux bind |
bind("alt+7",            "pane.split", { direction = "right" })
bind("shift+[Backslash]", "pane.split", { direction = "right" })
bind("v",                "pane.split", { direction = "right" })
-- "-" by character, not "[Minus]": on the Swedish layout the physical Minus
-- key types "+", and "-" lives on [Slash].
bind("-",                "pane.split", { direction = "down" })   -- herdr default / tmux bind -

bind("z", "pane.zoom")                -- herdr default / tmux Up/Down fullscreen dance
bind("=", "pane.balance")             -- tmux bind = select-layout tiled
bind("ctrl+q", "pane.close")          -- herdr close_pane / tmux bind C-q killp
bind("shift+t", "pane.move_to_new_tab")

-- resize nudges: herdr prefix+shift+h/j/k/l shell binds / tmux bind -r H/J/K/L
bind("shift+h", "pane.resize", { direction = "left",  amount = 15 })
bind("shift+j", "pane.resize", { direction = "down",  amount = 15 })
bind("shift+k", "pane.resize", { direction = "up",    amount = 15 })
bind("shift+l", "pane.resize", { direction = "right", amount = 15 })

-- ── Resize mode (herdr resize_mode, closer to tmux's repeating -r binds) ──
-- prefix+shift+r enters; h/j/k/l nudge; shift+h/j/k/l nudge more; = balances;
-- enter or escape leaves.  Exclusive: other keys are swallowed while active.
rex.mode("resize", { exclusive = true })
rex.bind("resize/h", "pane.resize", { direction = "left" })
rex.bind("resize/j", "pane.resize", { direction = "down" })
rex.bind("resize/k", "pane.resize", { direction = "up" })
rex.bind("resize/l", "pane.resize", { direction = "right" })
rex.bind("resize/shift+h", "pane.resize", { direction = "left",  amount = 15 })
rex.bind("resize/shift+j", "pane.resize", { direction = "down",  amount = 15 })
rex.bind("resize/shift+k", "pane.resize", { direction = "up",    amount = 15 })
rex.bind("resize/shift+l", "pane.resize", { direction = "right", amount = 15 })
rex.bind("resize/=",      "pane.balance")
rex.bind("resize/enter",  "client.mode.exit")
rex.bind("resize/escape", "client.mode.exit")

-- ── Popups → custom actions (actions.lua) ────────────────────────────────
bind("ctrl+g", "lazygit")             -- tmux bind C-g display-popup lazygit

-- ── Not portable ─────────────────────────────────────────────────────────
-- tmux bind y synchronize-panes     → Rex has no broadcast input
-- tmux bind 1-5 select-layout       → Rex has no preset layouts (pane.balance only)
-- tmux bind [ copy-mode             → use the mouse / cmd+f (client.find.open)
-- tmux bind C-c / C-v pbcopy/paste  → native cmd+c / cmd+v

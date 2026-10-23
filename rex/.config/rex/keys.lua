-- ~/.config/rex/keys.lua
-- Key bindings ported from the `keybind =` lines in ~/.config/ghostty/config.
-- Each binding notes its Ghostty origin.  Binding a key Rex already uses
-- replaces the default, exactly like Ghostty.
--
-- Key syntax: modifiers + key, e.g. "cmd+shift+h".  Modifiers: cmd, ctrl,
-- alt, shift.  Bracketed W3C codes such as "[Minus]" name a physical key
-- regardless of layout — which is wrong for punctuation on a non-US layout.

-- ── Splits ───────────────────────────────────────────────────────────────
-- ghostty: cmd+shift+- = new_split:right / cmd+- = new_split:down
-- Bound by character: on the Swedish layout the physical [Minus] key types
-- "+", and "-" lives on [Slash], so a physical-key binding lands on the wrong key.
rex.bind("cmd+shift+-", "pane.split", { direction = "right" })
rex.bind("cmd+-",       "pane.split", { direction = "down" })

-- ghostty: cmd+shift+h/j/k/l = new_split:left/down/up/right
rex.bind("cmd+shift+h", "pane.split", { direction = "left" })
rex.bind("cmd+shift+j", "pane.split", { direction = "down" })
rex.bind("cmd+shift+k", "pane.split", { direction = "up" })
rex.bind("cmd+shift+l", "pane.split", { direction = "right" })

-- ── Focus ────────────────────────────────────────────────────────────────
-- ghostty: cmd+h/j/k/l = goto_split:left/down/up/right
rex.bind("cmd+h", "pane.focus", { direction = "left" })
rex.bind("cmd+j", "pane.focus", { direction = "down" })
rex.bind("cmd+k", "pane.focus", { direction = "up" })
rex.bind("cmd+l", "pane.focus", { direction = "right" })

-- ── Zoom ─────────────────────────────────────────────────────────────────
-- ghostty: cmd+z = toggle_split_zoom
rex.bind("cmd+z", "pane.zoom")

-- ── Resize ───────────────────────────────────────────────────────────────
-- ghostty: cmd+arrow = resize_split:<dir>,20   (20 = pixels in Ghostty)
-- Rex's `amount` is in its own step units (docs use 15 for a "big" step),
-- so the default step is used here; add `amount = N` to taste.
rex.bind("cmd+left",  "pane.resize", { direction = "left" })
rex.bind("cmd+down",  "pane.resize", { direction = "down" })
rex.bind("cmd+up",    "pane.resize", { direction = "up" })
rex.bind("cmd+right", "pane.resize", { direction = "right" })

-- ── Not portable ─────────────────────────────────────────────────────────
-- ghostty: global:cmd+grave_accent = toggle_quick_terminal
-- Rex has no quick/quake terminal and no system-wide (global) hotkeys in
-- init.lua.  Keep that bind in Ghostty, or use Rex's "New Window".

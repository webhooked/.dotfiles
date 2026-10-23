-- ~/.config/rex/init.lua
-- ─────────────────────────────────────────────────────────────────────────
-- Ported from ~/.config/ghostty/config.  Rex's config is Lua and covers key
-- bindings, custom actions and remote hosts only — see README.md next to
-- this file for which Ghostty options map here, which live in Rex's
-- Settings window, and which have no equivalent.
--
-- Reload:    rex config reload      (or the "Reload Config" palette action)
-- Validate:  rex config check ~/.config/rex/init.lua
-- Inspect:   rex keymap             (merged bindings + problems)
--
-- `require` resolves relative to this directory.
-- ─────────────────────────────────────────────────────────────────────────

require("keys")        -- Ghostty cmd+ keybinds → rex.bind
require("prefix")      -- herdr/tmux ctrl+space prefix bindings + resize mode
require("actions")     -- tmux popup binds as custom actions (lazygit)
require("themes")      -- Ghostty theme files in ./themes → "Import Ghostty Themes" action
require("workspaces")  -- herdr workspaces (workspaces.json) → "Set Up herdr Workspaces" action

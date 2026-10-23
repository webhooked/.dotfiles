#!/usr/bin/env zsh
# Apply the Ghostty terminal settings to Rex by writing Rex's preferences.
#
# Rex has no config-file equivalent for these (init.lua only covers keys,
# actions and hosts); they are app preferences under com.superlogical.rex.
# Each line notes the ~/.config/ghostty/config option it ports.
#
# Quit Rex.app first, run this, then relaunch.  Re-run after changing values.
#
#   zsh ~/.config/rex/scripts/apply-settings.sh
set -euo pipefail

DOMAIN=com.superlogical.rex

# font-family = "Berkeley Mono Variable"   (family name, as in Settings → Change Terminal Font)
defaults write "$DOMAIN" Workspace.terminalFontName -string "Berkeley Mono Variable"
# font-style = "Retina SemiCondensed"      (style name within the family)
defaults write "$DOMAIN" Workspace.terminalFontStyle -string "Retina SemiCondensed"
# font-size = 14
defaults write "$DOMAIN" Workspace.terminalFontPointSize -float 14
# adjust-cell-height = 25%                 ("Line height adjustment in percent")
defaults write "$DOMAIN" Workspace.terminalCellHeightPercent -int 25

# cursor-style = block                     (block | underline | hollowBlock)
defaults write "$DOMAIN" Workspace.terminalCursorStyle -string block
# shell-integration-features = no-cursor   → don't let programs override the cursor style
defaults write "$DOMAIN" Workspace.terminalCursorStyleForced -bool true
# cursor-style-blink = true                → Rex's default; no custom interval
defaults write "$DOMAIN" Workspace.terminalCursorBlinkUsesCustomInterval -bool false

# copy-on-select = clipboard
defaults write "$DOMAIN" Workspace.terminalCopyOnSelect -bool true

# window-theme = system + theme = dark:…,light:…  → see select-theme.sh
# (Rex can't use a dark-tagged theme in light mode, so appearance is pinned dark.)
defaults write "$DOMAIN" Workspace.appearance -string dark

# Not ported (no Rex preference found): background-opacity, background-blur,
# faint-opacity, adjust-cursor-height, adjust-underline-*, custom-shader,
# macos-titlebar-*, macos-icon, clipboard-read/write, window-save-state,
# quit-after-last-window-closed, mouse-scroll-multiplier, confirm-close-surface.
# unfocused-split-opacity = 1 would be Workspace.fadesInactivePanes = false /
# Workspace.inactivePaneFadeMode; left alone since Rex's fade was set by hand.

echo "--- result"
defaults read "$DOMAIN" | grep -E "Workspace\.(terminal|appearance)" | sed 's/^ *//'

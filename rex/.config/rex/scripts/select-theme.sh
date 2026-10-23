#!/usr/bin/env zsh
# Select an imported Rex custom theme for light or dark mode by name, and
# optionally pin Rex's appearance mode, by writing Rex's preferences directly.
#
# Why this exists: Rex tags every imported theme "light" or "dark" from its
# background brightness.  The Settings → Appearance pickers only list themes
# with the matching tag, and Rex resets the light slot on launch if it holds a
# dark-tagged theme.  Re-tagging a dark theme as "light" gets it into the slot
# but makes the UI chrome use light-mode (dark) text on a dark panel.  So a
# dark theme such as poimandresish-storm can only be used with the chrome in
# dark mode — which means pinning Rex's appearance to dark instead of
# following the system.
#
# Quit Rex.app first (it may overwrite preferences while running), then relaunch.
#
# usage: select-theme.sh <theme-name> <light|dark> [--appearance system|light|dark]
#
# Ghostty had `theme = dark:poimandresish,light:poimandresish-storm`.  Nearest
# Rex equivalent — dark chrome always, storm as the theme:
#   zsh ~/.config/rex/scripts/select-theme.sh poimandresish-storm dark --appearance dark
# Switch to poimandresish at any time with the "Change Theme…" palette action.
set -euo pipefail

NAME="${1:?theme name}"
MODE="${2:?light|dark}"
APPEARANCE=""
if [[ "${3:-}" == "--appearance" ]]; then
  APPEARANCE="${4:?system|light|dark}"
fi
DOMAIN=com.superlogical.rex
PLIST="$HOME/Library/Preferences/$DOMAIN.plist"

[[ "$MODE" == "light" || "$MODE" == "dark" ]] || { echo "mode must be light or dark"; exit 1; }

THEMES=$(plutil -extract 'Workspace\.customThemes' raw -o - "$PLIST" | base64 -d)
ID=$(printf '%s' "$THEMES" | jq -r --arg n "$NAME" '.[] | select(.name == $n) | .id')
TAG=$(printf '%s' "$THEMES" | jq -r --arg n "$NAME" '.[] | select(.name == $n) | .appearance')
[[ -n "$ID" ]] || { echo "no custom theme named '$NAME' (import it in Rex first)"; exit 1; }

if [[ "$MODE" == "light" && "$TAG" == "dark" ]]; then
  echo "note: '$NAME' is tagged dark; Rex will reset the light slot on launch." >&2
  echo "      Use '$NAME dark --appearance dark' instead." >&2
fi

if [[ "$MODE" == "light" ]]; then
  defaults write "$DOMAIN" Workspace.lightThemeID -string "$ID"
else
  defaults write "$DOMAIN" Workspace.darkThemeID -string "$ID"
fi

if [[ -n "$APPEARANCE" ]]; then
  if [[ "$APPEARANCE" == "system" ]]; then
    defaults delete "$DOMAIN" Workspace.appearance 2>/dev/null || true
  else
    defaults write "$DOMAIN" Workspace.appearance -string "$APPEARANCE"
  fi
fi

echo "--- result"
echo "$NAME: tagged $TAG, id $ID"
echo "appearance:   $(defaults read "$DOMAIN" Workspace.appearance 2>/dev/null || echo system)"
echo "lightThemeID: $(defaults read "$DOMAIN" Workspace.lightThemeID)"
echo "darkThemeID:  $(defaults read "$DOMAIN" Workspace.darkThemeID)"

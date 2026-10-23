#!/usr/bin/env zsh
# Snapshot herdr's live workspaces into ~/.config/rex/workspaces.json, the
# file the `setup_workspaces` Rex action (workspaces.lua) recreates sessions
# from.  Re-run whenever herdr's workspaces change and you want Rex to match.
#
#   zsh ~/.config/rex/scripts/export-herdr-workspaces.sh
set -euo pipefail

HERE="${0:A:h}"
SRC="${HERDR_SESSION:-$HOME/.config/herdr/session.json}"
OUT="$HERE/../workspaces.json"

[[ -f "$SRC" ]] || { echo "no herdr session file at $SRC"; exit 1; }

jq -f "$HERE/herdr-to-rex.jq" "$SRC" > "$OUT"
echo "wrote $OUT"
jq -r '.workspaces[] | "\(.name)\t\(.tabs | length) tabs\t\(.cwd)"' "$OUT"

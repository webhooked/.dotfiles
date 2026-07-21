#!/bin/sh
# fzf space (workspace) switcher for herdr — replaces the tmux `bind x` popup.
# Bound to prefix+x via [[keys.command]] type = "popup" in config.toml.
# Unlike herdr's built-in navigator (prefix+g), the cursor starts in the
# search field and matching is fuzzy, not substring.
#
# NOTE: fzf key names use a hyphen (ctrl-j), not a plus (ctrl+j). A bad key
# name makes fzf abort at startup and the popup vanishes with no message.

# herdr popups do not inherit an interactive shell's PATH.
PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
export PATH

# Never vanish silently: show the reason and wait for a keypress.
die() {
  printf '\n%s\n\npress enter to close ' "$1"
  read _ignored
  exit 1
}

command -v herdr >/dev/null 2>&1 || die "herdr not on PATH ($PATH)"
command -v jq    >/dev/null 2>&1 || die "jq not on PATH ($PATH)"
command -v fzf   >/dev/null 2>&1 || die "fzf not on PATH ($PATH)"

list=$(herdr workspace list 2>&1) || die "herdr workspace list failed: $list"

rows=$(printf '%s' "$list" |
  jq -r '.result.workspaces[] | [.label, .workspace_id] | @tsv' 2>&1) ||
  die "jq failed: $rows"
[ -n "$rows" ] || die "no workspaces found in: $list"

sel=$(printf '%s\n' "$rows" |
  fzf --delimiter='\t' \
      --with-nth=1 \
      --prompt='space > ' \
      --height=100% \
      --reverse \
      --bind='ctrl-j:down,ctrl-k:up' 2>/tmp/herdr-space-picker.err) ||
  {
    [ -s /tmp/herdr-space-picker.err ] &&
      die "fzf failed: $(cat /tmp/herdr-space-picker.err)"
    exit 0
  }

[ -n "$sel" ] || exit 0
herdr workspace focus "$(printf '%s' "$sel" | cut -f2)" >/dev/null 2>&1

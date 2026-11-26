#!/usr/bin/env zsh
# Rex's Settings-window preferences, kept in dotfiles.
#
# Rex has no config-file equivalent for these (init.lua only covers keys,
# actions and hosts); they are app preferences under com.superlogical.rex.
# Terminal settings note the ~/.config/ghostty/config option they port.
#
#   zsh ~/.config/rex/scripts/apply-settings.sh           # write them to Rex (quit Rex first, then relaunch)
#   zsh ~/.config/rex/scripts/apply-settings.sh --check   # compare with Rex, change nothing
#   zsh ~/.config/rex/scripts/apply-settings.sh --save    # copy Rex's current values into this file
#
# --check lists every setting whose value in Rex differs from this file, and
# every Workspace.* preference this file doesn't cover yet (minus STATE_KEYS).
# It exits 1 when anything differs.
#
# --save does the reverse of a plain run: it rewrites the value on each pref
# line below that differs from Rex (comments kept) and adds settings this
# file doesn't cover under "Added by --save".  Review with `git diff`.
#
# --check and --save only read Rex's preferences, so Rex can stay open.
# Themes are separate: the light/dark theme ids differ per machine, so
# select-theme.sh picks them by name.
set -euo pipefail

DOMAIN=com.superlogical.rex
SCRIPT=${0:A}   # the real file in the dotfiles repo (inside functions $0 is the function name)
case "${1:-}" in
  "") MODE=apply ;;
  --check) MODE=check ;;
  --save) MODE=save ;;
  *) print -u2 "usage: ${0:t} [--check | --save]"; exit 2 ;;
esac

# Workspace.* keys that are app state or machine-specific ids, not settings.
STATE_KEYS=(
  lastFocusedSession programActivitySeen sidebarCollapsed
  customThemes darkThemeID lightThemeID   # select-theme.sh
  activityGroupingResetToPriority         # one-off migration flag
)

typeset -a MANAGED
DIFFS=0

# pref <key without "Workspace."> <-string|-bool|-int|-float> <value>
pref() {
  local key=$1 type=$2 value=$3
  MANAGED+=($key)
  [[ $MODE == save ]] && return   # --save works on the file's text instead
  if [[ $MODE == apply ]]; then
    defaults write "$DOMAIN" "Workspace.$key" "$type" "$value"
    return
  fi
  local want=$value current
  if [[ $type == -bool ]]; then
    [[ $value == true ]] && want=1 || want=0
  fi
  current=$(defaults read "$DOMAIN" "Workspace.$key" 2>/dev/null) || current="(unset)"
  if [[ "$current" != "$want" ]]; then
    print "differs  $key: Rex has $current, this file has $want"
    DIFFS=$((DIFFS + 1))
  fi
}

# ── Terminal (Settings → Terminal) ─────────────────────────────────────────
# font-family = "Berkeley Mono Variable"   (family name, as in Settings → Change Terminal Font)
pref terminalFontName -string "Berkeley Mono Variable"
# font-style = "Retina SemiCondensed"      (style name within the family)
pref terminalFontStyle -string "Retina SemiCondensed"
# font-size = 14
pref terminalFontPointSize -float 14
# adjust-cell-height = 25%                 ("Line height adjustment in percent")
pref terminalCellHeightPercent -int 25

# cursor-style = block                     (block | underline | hollowBlock)
pref terminalCursorStyle -string block
# shell-integration-features = no-cursor   → don't let programs override the cursor style
pref terminalCursorStyleForced -bool true
# cursor-style-blink = true                → Rex's default; no custom interval
pref terminalCursorBlinkUsesCustomInterval -bool false

# copy-on-select = clipboard
pref terminalCopyOnSelect -bool true

# ── Appearance ─────────────────────────────────────────────────────────────
# window-theme = system: follow macOS (system | light | dark).  The themes
# per mode are set by select-theme.sh (poimandresish / poimandresish-light).
pref appearance -string system
# Settings → Interface → Appearance → Interface Style: how the UI chrome uses
# the theme's colors (useTheme | blendTheme | …).
pref interfaceStyle -string useTheme

# ── Panes (Settings → Interface → Active Panes) ────────────────────────────
# Inactive panes: what marks them, none | surface | content | both | styling.
# There is no fade amount.  "both" was too dim and "content" (text faded)
# still too dim; "styling" is the option picked in Settings since.
pref inactivePaneFadeMode -string styling
# Fade Panes for Inactive Windows: the standard inactive-window look.
pref usesStandardInactiveWindowPaneStyles -bool true

# ── Tabs and sidebar ───────────────────────────────────────────────────────
pref tabStyle -string vertical            # vertical | horizontal (prefix shift+b toggles)
pref tabIconTintMode -string off          # tint tab icons with the theme: off
pref sidebarSwipe -string swipe           # trackpad swipe in the sidebar switches sessions
pref sidebarShowsActivity -bool false     # prefix a toggles the activity view instead
pref activityGrouping -string priority    # activity view grouping

# ── Keyboard ───────────────────────────────────────────────────────────────
# Key sequence hints (which-key popup after ctrl+space): off.
# Settings → Keyboard → Show key sequence hints.  Modes (resize) show their
# key popup regardless of this setting.
pref showsKeySequenceHints -bool false

# ── Added by --save (move each into a section above, with a comment) ───────

# Not ported (no Rex preference found): background-opacity, background-blur,
# faint-opacity, adjust-cursor-height, adjust-underline-*, custom-shader,
# macos-titlebar-*, macos-icon, clipboard-read/write, window-save-state,
# quit-after-last-window-closed, mouse-scroll-multiplier, confirm-close-surface.

# Workspace.* settings in Rex that this file doesn't cover (nor STATE_KEYS).
# Top-level keys are indented by exactly four spaces in `defaults read`.
unmanaged_keys() {
  local line
  for line in ${(f)"$(defaults read "$DOMAIN")"}; do
    [[ $line =~ '^    "Workspace\.([A-Za-z0-9]+)"' ]] || continue
    (( ${MANAGED[(Ie)${match[1]}]} || ${STATE_KEYS[(Ie)${match[1]}]} )) && continue
    print -r -- ${match[1]}
  done
}

# Rex's value of Workspace.<key> written as a pref value: true/false for
# booleans, quoted strings when they need it.  Fails for dictionaries, arrays
# and data, which a pref line can't hold.
pref_value() {
  local key=$1 type=$2 v
  v=$(defaults read "$DOMAIN" "Workspace.$key")
  case $type in
    -bool) [[ $v == 1 ]] && print true || print false ;;
    -string) [[ $v =~ '^[A-Za-z0-9._/-]+$' ]] && print -r -- "$v" || print -r -- "\"$v\"" ;;
    *) print -r -- "$v" ;;
  esac
}

# The pref type for Workspace.<key>, from `defaults read-type`.
pref_type() {
  case "$(defaults read-type "$DOMAIN" "Workspace.$1")" in
    *boolean) print -- -bool ;;
    *integer) print -- -int ;;
    *float) print -- -float ;;
    *string) print -- -string ;;
    *) return 1 ;;
  esac
}

# --save: rewrite this file.  Runs last and exits from inside the function,
# so the shell never reads the file again after it is rewritten.
save_and_exit() {
  local file=$SCRIPT out=() line key type old new changed=0 added=0 skipped=()
  local marker='^# ── Added by --save'
  for line in "${(@f)$(<$file)}"; do
    if [[ $line =~ '^pref ([A-Za-z0-9]+) (-[a-z]+) ("[^"]*"|[^ ]+)(.*)$' ]]; then
      key=${match[1]} type=${match[2]} old=${match[3]}
      new=$(pref_value $key $type)
      if [[ $new != $old ]]; then
        line="pref $key $type $new${match[4]}"
        print "saved    $key: $old -> $new"
        changed=$((changed + 1))
      fi
    fi
    out+=("$line")
    if [[ $line =~ $marker ]]; then
      for key in $(unmanaged_keys); do
        if type=$(pref_type $key); then
          out+=("pref $key $type $(pref_value $key $type)")
          print "added    $key"
          added=$((added + 1))
        else
          skipped+=($key)
        fi
      done
    fi
  done
  print -r -- "${(F)out}" > $file
  (( ${#skipped} )) && print "skipped  ${skipped} (not a string, number or boolean)"
  if (( changed + added )); then
    print "$changed changed, $added added in $file; review with git diff"
  else
    print "nothing to save: this file already matches Rex"
  fi
  exit 0
}

if [[ $MODE == save ]]; then
  save_and_exit
fi

if [[ $MODE == check ]]; then
  for key in $(unmanaged_keys); do
    value=$(defaults read "$DOMAIN" "Workspace.$key" | head -1)
    print "new      $key = $value (not in this file)"
    DIFFS=$((DIFFS + 1))
  done
  if (( DIFFS )); then
    print "$DIFFS difference(s); copy the values into $0"
    exit 1
  fi
  print "Rex matches this file (${#MANAGED} settings)"
  exit 0
fi

echo "--- written (relaunch Rex)"
for key in $MANAGED; do
  print "$key = $(defaults read "$DOMAIN" "Workspace.$key")"
done

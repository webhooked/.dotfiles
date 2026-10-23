# Rex config

[Rex](https://www.superlogical.com/rex/docs) is configured in Lua
(`~/.config/rex/init.lua`). Unlike Ghostty, that file only covers **key
bindings, custom actions and remote hosts**. Everything visual lives in the
app's Settings window. This folder is the Ghostty config ported as far as
that split allows.

```
rex/.config/rex/
├── init.lua          # entry point, requires the files below
├── keys.lua          # Ghostty cmd+ keybinds → rex.bind
├── prefix.lua        # herdr/tmux ctrl+space prefix bindings + resize mode
├── actions.lua       # tmux popup binds as custom actions (lazygit)
├── themes.lua        # "Import Ghostty Themes" action
├── themes/           # Ghostty theme files, copied verbatim from ghostty/.config/ghostty/themes
├── workspaces.lua    # "Set Up herdr Workspaces" action
├── workspaces.json   # snapshot of herdr's workspaces/tabs/layouts (generated)
└── scripts/
    ├── apply-settings.sh            # Ghostty terminal settings → Rex preferences
    ├── select-theme.sh              # pick a theme + appearance mode by name
    ├── export-herdr-workspaces.sh   # herdr session.json → workspaces.json
    └── herdr-to-rex.jq              # the conversion used by the script above
```

## Fresh machine

```sh
./stow                                                   # links ~/.config/rex
zsh ~/.config/rex/scripts/apply-settings.sh              # font, cursor, copy-on-select (Rex quit)
# open Rex → Command Palette → "Import Ghostty Themes", then quit Rex
zsh ~/.config/rex/scripts/select-theme.sh poimandresish-storm dark --appearance dark
rex do setup_workspaces                                  # sessions from workspaces.json (-s <session> if several exist)
```

## herdr / tmux port (`prefix.lua`, `actions.lua`)

The prefix is Ctrl+Space, as in herdr and tmux. Rex has no prefix setting;
a prefix is just the first key of a sequence, and Escape cancels one. The
cmd+ bindings from Ghostty (`keys.lua`) still work alongside.

| Keys (after Ctrl+Space) | Rex action | Origin |
| --- | --- | --- |
| `ctrl+space`, `e` | send Ctrl+Space to the pane | tmux send-prefix (nested) |
| `r` | reload config | herdr reload_config / tmux `r` |
| `shift+r` | enter resize mode (`h/j/k/l`, `shift+` for big steps, `=` balance, Enter/Esc leave) | herdr resize_mode |
| `shift+n`, `shift+s` | new session | herdr new_workspace / tmux `S` |
| `w`, `s`, `x` | session switcher | herdr space-picker popup, workspace_picker / tmux `w`, `s` |
| `g`, `a` | command palette (searches sessions, tabs, commands) | herdr goto navigator |
| `b` | toggle sidebar | herdr toggle_sidebar |
| `c` | new tab | herdr default / tmux `W` |
| `n`, `m` | previous / next tab | herdr previous_tab, next_tab / tmux `n`, `m` |
| `alt+n`, `alt+m` | move tab backward / forward | tmux `N`, `M` (herdr had no equivalent) |
| `1`–`9` | go to tab | herdr switch_tab / tmux select-window |
| `,`, `shift+w` | rename / close tab | Rex extras |
| `h/j/k/l`, `tab`, `shift+tab` | focus pane | herdr default / tmux |
| `ctrl+h/j/k/l` | move pane | herdr swap_pane_* / tmux swap-pane |
| `alt+7`, `shift+\`, `v` | split right | herdr split_vertical (`|` is ⌥7 on Swedish layout) / tmux `|` |
| `-` | split down | herdr default / tmux `-` |
| `z`, `=`, `ctrl+q`, `shift+t` | zoom, balance, close pane, pane to new tab | herdr/tmux `z`, `=`, `C-q` |
| `shift+h/j/k/l` | resize by 15 | herdr shell resize binds / tmux `H/J/K/L` |
| `ctrl+g` | `lazygit` action: lazygit in a new tab in the current pane's directory | tmux `C-g` popup |

Not portable: tmux `y` synchronize-panes (no broadcast input), tmux `1`–`5`
preset layouts (only `pane.balance`), tmux `[` copy mode, tmux `C-c`/`C-v`
clipboard binds (use cmd+c / cmd+v).

herdr's `[terminal] new_cwd = "follow"` is Rex's default; `[ui]
mouse_capture`, sidebar and toast settings are Rex Settings-window options;
herdr's `[theme.custom]` override is covered by the imported Ghostty themes.

## herdr workspaces → Rex sessions (`workspaces.lua`)

`scripts/export-herdr-workspaces.sh` snapshots herdr's live
`~/.config/herdr/session.json` into `workspaces.json`: every workspace with
its tabs, split tree (direction + ratio) and each pane's directory. The
`setup_workspaces` server action recreates them as Rex sessions, one window
per tab and a shell per pane started in its directory. Existing labels are
skipped, so re-running only adds what is missing.

```sh
zsh ~/.config/rex/scripts/export-herdr-workspaces.sh   # refresh the snapshot from herdr
rex do setup_workspaces dry_run=true                   # what would be created
rex do setup_workspaces                                # create missing sessions
rex do setup_workspaces only=dotfiles                  # one workspace
```

Inside a Rex terminal the session is implied. From elsewhere, once more
than one session exists, `rex do` needs a session to run against:
`rex do -s <any-session> setup_workspaces`.

herdr's `Horizontal`/`Vertical` split directions are passed to Rex as-is; if
a layout comes out transposed, swap them in `herdr-to-rex.jq`.

Commands:

```sh
rex config check ~/.config/rex/init.lua   # validate without applying
rex config reload                         # apply
rex keymap                                # merged bindings + problems
rex -C <label> actions                    # every action the app offers
```

## Themes

Rex imports Ghostty theme files natively, but keeps imported themes in the
app's own storage rather than reading a folder. So on each machine, once:

1. Command Palette → **Import Ghostty Themes** (defined in `themes.lua`;
   imports every file in `themes/`).
2. Settings → Appearance → choose the dark and light palettes, or run
   **Change Theme…** from the palette.

Ghostty's `theme = dark:poimandresish,light:poimandresish-storm` becomes:
dark palette `poimandresish`, light palette `poimandresish-storm`.

**Dark theme as the light-mode theme.** Rex tags every imported theme
`light` or `dark` from its background brightness. The light picker only lists
`light` themes, Rex resets the light slot on launch if it holds a `dark`
theme, and re-tagging a dark theme as `light` makes the UI chrome use
light-mode (dark) text on a dark panel. So `poimandresish-storm` can only be
used with the chrome in dark mode, which means pinning Rex's appearance to
dark instead of following the system. Quit Rex, then:

```sh
zsh ~/.config/rex/scripts/select-theme.sh poimandresish-storm dark --appearance dark
```

That writes `Workspace.darkThemeID` and `Workspace.appearance` in Rex's
preferences. Switch to `poimandresish` any time with the "Change Theme…"
palette action; `--appearance system` restores system-following.

Re-run the script after re-importing a theme, since importing creates a
fresh entry with a new id.

The CLI route (`rex -C <label> do import_themes`) only works after turning on
**Remote Control** in Settings → Rex Server.

To add a theme: drop the Ghostty file in `themes/`, re-run the import action
(or `import_themes only=<file>`), and restow if it is a new machine.

## Ghostty → Rex mapping

| Ghostty | Rex |
| --- | --- |
| `keybind = cmd+shift+-=new_split:right` | `rex.bind("cmd+shift+[Minus]", "pane.split", {direction="right"})` |
| `keybind = cmd+-=new_split:down` | `rex.bind("cmd+[Minus]", "pane.split", {direction="down"})` |
| `keybind = cmd+shift+h/j/k/l=new_split:*` | `pane.split` with `direction` |
| `keybind = cmd+h/j/k/l=goto_split:*` | `pane.focus` with `direction` |
| `keybind = cmd+z=toggle_split_zoom` | `pane.zoom` |
| `keybind = cmd+arrow=resize_split:*,20` | `pane.resize` with `direction` (default step; Rex's `amount` is not pixels) |
| `theme = dark:…,light:…` | Import action + Settings → Appearance (see above) |
| `window-theme = system` | Settings → Appearance mode, or the `client.appearance.switch_mode` action |

### App preferences (no Lua equivalent): `scripts/apply-settings.sh`

Rex keeps terminal settings as macOS preferences under `com.superlogical.rex`
(the keys were read out of the app binary; Rex Beta 0.1.0). The script writes
them with `defaults write`. Quit Rex, run it, relaunch:

```sh
zsh ~/.config/rex/scripts/apply-settings.sh
```

| Ghostty | Rex preference key | Value |
| --- | --- | --- |
| `font-family = "Berkeley Mono Variable"` | `Workspace.terminalFontName` | family name |
| `font-style = "Retina SemiCondensed"` | `Workspace.terminalFontStyle` | style name |
| `font-size = 14` | `Workspace.terminalFontPointSize` | `14` |
| `adjust-cell-height = 25%` | `Workspace.terminalCellHeightPercent` | `25` ("line height adjustment in percent") |
| `cursor-style = block` | `Workspace.terminalCursorStyle` | `block` / `underline` / `hollowBlock` |
| `shell-integration-features = no-cursor` | `Workspace.terminalCursorStyleForced` | `true` |
| `copy-on-select = clipboard` | `Workspace.terminalCopyOnSelect` | `true` |
| `window-theme = system` | `Workspace.appearance` | `dark` (pinned, see Themes) |
| `unfocused-split-opacity = 1` | `Workspace.fadesInactivePanes`, `Workspace.inactivePaneFadeMode` | left as set by hand in Rex |
| `faint-opacity = 1` | — | herdr-only workaround, not needed |

Other keys that exist but have no Ghostty counterpart in this config:
`terminalFontWeight`, `terminalFontSmoothing`, `terminalAllowsLigatures`,
`terminalImproveTextContrast`, `terminalOptionKeyBehavior`,
`terminalSelectionRoundedCorners`, `terminalPaddingColor`, `usesPaneGlass`.

### No Rex equivalent (as of Rex Beta 0.1.0 / server 2026-10-21)

- `background-opacity`, `background-blur` (Rex has a "pane glass" look instead)
- `cursor-style-blink` interval, `adjust-cursor-height`, `adjust-underline-*`
- `custom-shader` (cursor shaders)
- `macos-titlebar-style`, `macos-titlebar-proxy-icon`, `macos-icon`
- `clipboard-read/write`, `window-save-state`, `quit-after-last-window-closed`,
  `mouse-scroll-multiplier`, `confirm-close-surface`
- `global:cmd+grave_accent=toggle_quick_terminal` (no quick terminal, no global hotkeys)

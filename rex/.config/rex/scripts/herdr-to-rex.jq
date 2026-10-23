# Convert herdr's ~/.config/herdr/session.json into rex workspaces.json.
#
#   herdr workspace  -> rex session   (name, cwd)
#   herdr tab        -> rex window    (name, cwd, layout)
#   herdr pane       -> rex block     ({ cwd })
#   herdr Split      -> { split, ratio, first, second }
#
# Unnamed workspaces and tabs get the basename of their directory, which is
# what herdr shows for them too.
#
# Usage: jq -f herdr-to-rex.jq ~/.config/herdr/session.json > workspaces.json

def basename: split("/") | map(select(. != "")) | last;

def node($panes):
  if has("Pane") then
    { cwd: $panes[(.Pane | tostring)].cwd }
  elif has("Split") then
    { split:  (.Split.direction | ascii_downcase),
      ratio:  .Split.ratio,
      first:  (.Split.first  | node($panes)),
      second: (.Split.second | node($panes)) }
  else . end;

{
  workspaces: [
    .workspaces[] | {
      name: (.custom_name // (.identity_cwd | basename)),
      cwd:  .identity_cwd,
      tabs: [
        .tabs[] | .panes as $panes | ($panes[(.root_pane | tostring)].cwd) as $cwd | {
          name:   (.custom_name // ($cwd | basename)),
          cwd:    $cwd,
          layout: (.layout | node($panes))
        }
      ]
    }
  ]
}

-- ~/.config/rex/workspaces.lua
-- ─────────────────────────────────────────────────────────────────────────
-- Recreate herdr's workspaces as Rex sessions.
--
-- workspaces.json (next to this file) is a snapshot of herdr's workspaces,
-- tabs and split layouts, produced by scripts/export-herdr-workspaces.sh:
--
--   { "workspaces": [ { "name", "cwd", "tabs": [ { "name", "cwd", "layout" } ] } ] }
--   layout = { "cwd" }                                           -- one pane
--          | { "split": "horizontal"|"vertical", "ratio", "first", "second" }
--
-- The `setup_workspaces` action turns each workspace into a session with one
-- window per tab and a shell block per pane, started in the pane's directory.
-- Sessions whose label already exists are skipped, so it is safe to re-run.
--
--   rex do setup_workspaces                  -- create every missing session
--   rex do setup_workspaces only=dotfiles    -- just one
--   rex do setup_workspaces dry_run=true     -- report without creating
--
-- It is a server action, so it needs no app client or Remote Control.
-- ─────────────────────────────────────────────────────────────────────────

local SHELL = "com.superlogical.terminal.shell"

local function config_dir()
  local src = (debug.getinfo(1, "S").source or ""):gsub("^@", "")
  local dir = src:match("^(/.*)/[^/]*$")
  if dir then return dir end
  local xdg = os.getenv("XDG_CONFIG_HOME")
  local base = (xdg and xdg ~= "") and xdg or (os.getenv("HOME") .. "/.config")
  return base .. "/rex"
end

local WORKSPACES_FILE = config_dir() .. "/workspaces.json"

local function load_workspaces()
  local f, err = io.open(WORKSPACES_FILE, "r")
  if not f then return nil, "cannot read " .. WORKSPACES_FILE .. ": " .. tostring(err) end
  local text = f:read("*a")
  f:close()
  local data = rex.json.decode(text)
  if type(data) ~= "table" or type(data.workspaces) ~= "table" then
    return nil, WORKSPACES_FILE .. " has no workspaces array"
  end
  return data.workspaces
end

-- herdr layout node -> Rex layout node.
local function to_layout(node)
  if node.split then
    return {
      split = {
        direction = node.split,
        ratio     = node.ratio,
        before    = to_layout(node.first),
        after     = to_layout(node.second),
      },
    }
  end
  return { block = { flavor = SHELL, options = { cwd = node.cwd } } }
end

local function existing_labels()
  local r, err = rex.call("session.list")
  if not r then error("session.list: " .. tostring(err), 0) end
  local labels = {}
  for _, s in ipairs(r.sessions or {}) do labels[s.label:lower()] = s.session_id end
  return labels
end

rex.action{
  name        = "setup_workspaces",
  title       = "Set Up herdr Workspaces",
  description = "Create a Rex session (windows, splits, directories) for every workspace in ~/.config/rex/workspaces.json that doesn't exist yet.",
  category    = "Sessions",
  args        = { only = "string?", dry_run = "boolean?" },
  run = function(ctx, args)
    local workspaces, err = load_workspaces()
    if not workspaces then error(err, 0) end
    local existing = existing_labels()
    local created, skipped, failed = {}, {}, {}

    for _, ws in ipairs(workspaces) do
      local name = ws.name or "workspace"
      if args.only and name ~= args.only then
        -- not requested
      elseif existing[name:lower()] then
        skipped[#skipped + 1] = name
      else
        local windows = {}
        for _, tab in ipairs(ws.tabs or {}) do
          windows[#windows + 1] = {
            window_label = tab.name,
            layout       = to_layout(tab.layout or { cwd = tab.cwd or ws.cwd }),
          }
        end
        if #windows == 0 then
          windows[1] = { layout = to_layout({ cwd = ws.cwd }) }
        end
        if args.dry_run then
          created[#created + 1] = name .. " (" .. #windows .. " windows)"
        else
          local r, cerr = rex.call("session.create", { label = name, initial_windows = windows })
          if r then
            created[#created + 1] = name
          else
            failed[#failed + 1] = name .. ": " .. tostring(cerr)
          end
        end
      end
    end

    return { created = created, skipped = skipped, failed = failed, from = WORKSPACES_FILE }
  end,
}

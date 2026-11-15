-- ~/.config/rex/workspaces.lua
-- ─────────────────────────────────────────────────────────────────────────
-- Save Rex's sessions to workspaces.json and recreate them later.
--
-- workspaces.json (next to this file) holds every session's windows, split
-- layouts and pane directories:
--
--   { "workspaces": [ { "name", "cwd", "tabs": [ { "name", "cwd", "layout" } ] } ] }
--   layout = { "cwd" }                                           -- one pane
--          | { "split": "horizontal"|"vertical", "ratio", "first", "second" }
--
-- `split` uses Rex's own directions (horizontal = side by side) and `ratio`
-- is the share of the first child.  The file is written by save_workspaces
-- (or, originally, from herdr by scripts/export-herdr-workspaces.sh).
--
--   rex do save_workspaces                     -- snapshot every session
--   rex do save_workspaces only=dotfiles       -- update one entry, keep the rest
--   rex do save_workspaces exclude=a,b         -- skip throwaway sessions
--   rex do save_workspaces dry_run=true        -- print, don't write
--
--   rex do restore_workspaces                  -- create every missing session
--   rex do restore_workspaces only=dotfiles    -- just one
--   rex do restore_workspaces dry_run=true     -- report without creating
--
-- restore skips sessions whose label already exists, so it is safe to re-run.
-- Floating layers and running programs are not saved, only tiled shells and
-- their directories.  Both are server actions: no app client or Remote
-- Control needed.  (`setup_workspaces` is kept as an alias of restore.)
-- ─────────────────────────────────────────────────────────────────────────

local SHELL = "com.superlogical.terminal.shell"
local TERMINAL = "com.superlogical.terminal"

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

local function set_of(csv)
  local s = {}
  for item in (csv or ""):gmatch("[^,%s]+") do s[item:lower()] = true end
  return s
end

-- ── JSON writer ─────────────────────────────────────────────────────────
-- rex.json.encode has no pretty-printing or key order; this keeps the file
-- readable and its git diffs stable.

local KEY_ORDER = { "workspaces", "name", "cwd", "tabs", "layout", "split", "ratio", "first", "second" }
local KEY_RANK = {}
for i, k in ipairs(KEY_ORDER) do KEY_RANK[k] = i end

local function is_array(t)
  if next(t) == nil then return true end
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  return n == #t
end

local function pretty(v, indent)
  if type(v) ~= "table" then return rex.json.encode(v) end
  indent = indent or ""
  local inner = indent .. "  "
  local parts = {}
  if is_array(v) then
    if #v == 0 then return "[]" end
    for _, item in ipairs(v) do parts[#parts + 1] = inner .. pretty(item, inner) end
    return "[\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "]"
  end
  local keys = {}
  for k in pairs(v) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b)
    local ra, rb = KEY_RANK[a] or math.huge, KEY_RANK[b] or math.huge
    if ra ~= rb then return ra < rb end
    return a < b
  end)
  for _, k in ipairs(keys) do
    parts[#parts + 1] = inner .. rex.json.encode(k) .. ": " .. pretty(v[k], inner)
  end
  return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
end

-- ── Save ────────────────────────────────────────────────────────────────

local function basename(path)
  return (path or ""):match("([^/]+)/*$")
end

-- A terminal block's directory: what the shell last reported (OSC 7), else
-- where the shell process actually is, else the foreground program's.
local function block_cwd(session_id, block_id)
  local r = rex.call("block.method", { session_id = session_id, block_id = block_id, method = "pwd" })
  local pwd = r and r.pwd
  if pwd and pwd ~= "" then
    pwd = pwd:gsub("^file://[^/]*", "")
    pwd = pwd:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
    return pwd
  end
  local p = rex.call("block.method", { session_id = session_id, block_id = block_id, method = "process" })
  if not p then return nil end
  -- ancestors run from the foreground's parent outward; the outermost one
  -- with a cwd is the block's shell.
  local shell_cwd
  for _, a in ipairs(p.ancestors or {}) do
    if a.cwd then shell_cwd = a.cwd end
  end
  return shell_cwd or (p.foreground and p.foreground.cwd) or p.home
end

-- Rex layout node -> workspaces.json layout node.
local function from_layout(session_id, node, blocks)
  if node.split then
    local s = node.split
    return {
      split  = s.direction,
      ratio  = math.floor((s.ratio or 0.5) * 1000 + 0.5) / 1000,
      first  = from_layout(session_id, s.before, blocks),
      second = from_layout(session_id, s.after, blocks),
    }
  end
  local b = blocks[node.block_id]
  if b and b.creator_name == TERMINAL then
    return { cwd = block_cwd(session_id, node.block_id) }
  end
  return { cwd = nil } -- non-terminal block: restored as a shell in the session's directory
end

local function first_cwd(layout)
  if layout.cwd then return layout.cwd end
  if layout.split then return first_cwd(layout.first) or first_cwd(layout.second) end
end

-- Fill panes that had no directory with a fallback.
local function fill_cwd(layout, cwd)
  if layout.split then
    fill_cwd(layout.first, cwd)
    fill_cwd(layout.second, cwd)
  elseif not layout.cwd then
    layout.cwd = cwd
  end
end

-- session.view and block methods only answer for sessions this connection
-- is attached to.  Use the view if we already are; otherwise attach (which
-- returns the view), run fn, and detach again.
local function with_view(s, fn)
  local v = rex.call("session.view", { session_id = s.session_id })
  if v then return fn(v) end
  local a, err = rex.call("session.attach", { session_id = s.session_id })
  if not a then error("session.attach " .. s.label .. ": " .. tostring(err), 0) end
  local ok, r1, r2 = pcall(fn, a.view)
  rex.call("session.detach", { session_id = s.session_id })
  if not ok then error(r1, 0) end
  return r1, r2
end

local function snapshot_session(s)
  return with_view(s, function(v)
  local tabs, floating = {}, 0
  for _, w in ipairs(v.windows or {}) do
    for _, layer in ipairs(w.layers or {}) do
      if layer.kind == "tiled" and layer.layout then
        local blocks = {}
        for _, b in ipairs(layer.blocks or {}) do blocks[b.block_id] = b end
        local layout = from_layout(s.session_id, layer.layout, blocks)
        local cwd = first_cwd(layout) or os.getenv("HOME")
        fill_cwd(layout, cwd)
        -- Rex's default "Window <id>" labels mean nothing in a new session;
        -- name those after their directory, as herdr did.
        local label = w.label
        if not label or label == "" or label:match("^Window %x+$") then label = basename(cwd) end
        tabs[#tabs + 1] = { name = label, cwd = cwd, layout = layout }
      else
        floating = floating + 1
      end
    end
  end
  local cwd = tabs[1] and tabs[1].cwd or os.getenv("HOME")
  return { name = s.label, cwd = cwd, tabs = tabs }, floating
  end)
end

rex.action{
  name        = "save_workspaces",
  title       = "Save Workspaces",
  description = "Snapshot every Rex session (windows, splits, directories) into ~/.config/rex/workspaces.json.",
  category    = "Sessions",
  args        = { only = "string?", exclude = "string?", dry_run = "boolean?" },
  run = function(ctx, args)
    local r, err = rex.call("session.list")
    if not r then error("session.list: " .. tostring(err), 0) end
    local exclude = set_of(args.exclude)

    local saved, skipped, workspaces, floating = {}, {}, {}, 0
    for _, s in ipairs(r.sessions or {}) do
      if exclude[s.label:lower()] or (args.only and s.label ~= args.only) then
        if not args.only then skipped[#skipped + 1] = s.label end
      else
        local ws, f = snapshot_session(s)
        workspaces[#workspaces + 1] = ws
        saved[#saved + 1] = ws.name .. " (" .. #ws.tabs .. " tabs)"
        floating = floating + f
      end
    end

    -- only=NAME replaces (or appends) that one entry and keeps the rest.
    if args.only then
      if #workspaces == 0 then error("no session labelled " .. args.only, 0) end
      local existing = load_workspaces() or {}
      local replaced = false
      for i, ws in ipairs(existing) do
        if ws.name == args.only then existing[i] = workspaces[1]; replaced = true end
      end
      if not replaced then existing[#existing + 1] = workspaces[1] end
      workspaces = existing
    end

    local text = pretty({ workspaces = workspaces }) .. "\n"
    if args.dry_run then
      return { would_save = saved, skipped = skipped, floating_layers_ignored = floating, json = text }
    end
    local f, ferr = io.open(WORKSPACES_FILE, "w")
    if not f then error("cannot write " .. WORKSPACES_FILE .. ": " .. tostring(ferr), 0) end
    f:write(text)
    f:close()
    return { saved = saved, skipped = skipped, floating_layers_ignored = floating, to = WORKSPACES_FILE }
  end,
}

-- ── Restore ─────────────────────────────────────────────────────────────

-- workspaces.json layout node -> Rex layout node.
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

local function restore(ctx, args)
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
end

local RESTORE_ARGS = { only = "string?", dry_run = "boolean?" }
local RESTORE_DESC = "Create a Rex session (windows, splits, directories) for every workspace in ~/.config/rex/workspaces.json that doesn't exist yet."

rex.action{
  name        = "restore_workspaces",
  title       = "Restore Workspaces",
  description = RESTORE_DESC,
  category    = "Sessions",
  args        = RESTORE_ARGS,
  run         = restore,
}

-- Old name, kept so existing muscle memory and scripts still work.
rex.action{
  name        = "setup_workspaces",
  title       = "Restore Workspaces (setup_workspaces)",
  description = RESTORE_DESC,
  category    = "Sessions",
  args        = RESTORE_ARGS,
  run         = restore,
}

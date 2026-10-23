-- ~/.config/rex/themes.lua
-- ─────────────────────────────────────────────────────────────────────────
-- ./themes/ holds Ghostty theme files copied verbatim from
-- ~/.config/ghostty/themes.  Rex imports that format natively through its
-- `client.theme.import` action ("Absolute path of a Ghostty theme or iTerm
-- color file"), but it stores imported themes in the app's own storage, not
-- in this folder.  So, once per machine:
--
--   1. Command Palette → "Import Ghostty Themes"   (the action below)
--   2. Settings → Appearance → pick the dark / light palette, or run
--      "Change Theme…" from the palette.
--      Ghostty equivalent:  theme = dark:poimandresish,light:poimandresish-storm
--
-- From the CLI (needs Remote Control enabled in the app and a client label):
--   rex -C <label> do import_themes
--   rex -C <label> do import_themes only=poimandresish
--   rex -C <label> do client.theme.change name=poimandresish
-- ─────────────────────────────────────────────────────────────────────────

local function config_dir()
  local src = (debug.getinfo(1, "S").source or ""):gsub("^@", "")
  local dir = src:match("^(/.*)/[^/]*$")
  if dir then return dir end
  local xdg = os.getenv("XDG_CONFIG_HOME")
  local base = (xdg and xdg ~= "") and xdg or (os.getenv("HOME") .. "/.config")
  return base .. "/rex"
end

local themes_dir = config_dir() .. "/themes"

-- Regular, non-hidden files directly inside ./themes, sorted by path.
local function theme_files()
  local files = {}
  local r = rex.exec(
    { "find", themes_dir, "-maxdepth", "1", "-type", "f", "!", "-name", ".*" },
    { text = true }
  )
  if not r or not r.ok then
    rex.log("warn", "themes: could not list " .. themes_dir)
    return files
  end
  for line in (r.stdout or ""):gmatch("[^\n]+") do
    files[#files + 1] = line
  end
  table.sort(files)
  return files
end

rex.action{
  name        = "import_themes",
  title       = "Import Ghostty Themes",
  description = "Add every Ghostty theme file in ~/.config/rex/themes to Rex's custom themes.",
  category    = "Themes",
  args        = { only = "string?" },  -- import a single theme by file name
  run = function(ctx, args)
    local imported = {}
    for _, path in ipairs(theme_files()) do
      local name = path:match("[^/]+$")
      if not args.only or name == args.only then
        rex.client.queue("client.theme.import", { path = path })
        imported[#imported + 1] = name
      end
    end
    return { count = #imported, themes = imported, from = themes_dir }
  end,
}

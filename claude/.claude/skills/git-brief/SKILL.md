---
name: git-brief
description: "Generate a readable TL;DR brief / release notes from git history, grouped by theme, written to a BRIEF-<date>.md file. Use when the user asks to summarize recent changes / commits, write release notes, a changelog, a standup/weekly update, or \"what did I ship\". Takes optional repo(s) and timeframe (e.g. \"last 6 days\", \"this week\", \"since Monday\"). Defaults: last 3 days, the current repo."
---

# Git Brief — themed release notes from git history

Turn raw git history into a concise, **human-readable** brief grouped by *theme* (not by repo, not by commit). The output is a markdown file in the format below.

## Inputs (all optional)

| Input | Default | Notes |
|-------|---------|-------|
| **repo(s)** | the current repo (cwd) | One or more paths. Absolute, or relative to cwd. Multiple repos are merged into one brief, themes spanning repos combined. |
| **timeframe** | `last 3 days` | Anything `git log --since` accepts: `last 6 days`, `2 weeks ago`, `this week`, `since Monday`, `2026-06-01`. |
| **author** | the repo's `git config user.name` | Pass `everyone` / `all` to include every author. The user saying "my changes" / "I" means the default (current git user). |

If the user named a repo or timeframe, use it. Otherwise apply the defaults silently — don't ask.

## Procedure

1. **Resolve inputs.** Determine repo list, `--since` value, and author. Get today's date for the filename: `date +%F`.

2. **Pull history per repo.** No `cd` (it trips permission prompts); use `git -C <path>`:
   ```
   git -C <repo> log --since="<timeframe>" --no-merges -i --author="<author>" \
       --all --pretty=format:"%h | %ad | %an | %s" --date=short
   ```
   - Omit `-i --author=...` entirely when author is `everyone`.
   - `--all` catches work on staging/feature branches not yet on the default branch.

3. **Dedup mirror commits.** `--all` surfaces the same change once per branch (e.g. staging + main, or rebased copies). Collapse commits with identical subject lines into one — count it once.

4. **Drop noise.** Exclude purely mechanical commits from the brief: index/tooling refreshes (e.g. `updated: gitnexus index`), lockfile-only bumps, and contentless messages (`fix`, `wip`, `.`). If a vague commit clearly carries real work, peek at it with `git -C <repo> show --stat <hash>` to recover what it did — don't invent.

5. **Group by theme.** Cluster commits into a handful of feature/outcome themes, largest effort first. A theme that appears in several repos becomes **one** section. Annotate which repos a theme touched only when useful. Lead with a one-paragraph **TL;DR**.

6. **Write the file.** Save to `BRIEF-<today>.md` in the primary repo (the first/cwd repo). Tell the user the path. Do not commit unless asked.

## Format (match this exactly)

````markdown
# Brief — <timeframe label> (<start> – <end>, <year>)

Changes by **<author>** across `repo-a`, `repo-b`.

## TL;DR

One tight paragraph naming the 2–4 biggest themes in plain language: what shipped and why it matters. **Bold** the theme names.

---

## <Theme name> (<scope / repos / "the main effort">)

Optional one-line framing of the theme.

- One idea per bullet — short, readable, outcome-first
- Split dense run-on bullets into separate lines
- Reference code/identifiers in `backticks`

For a large theme, break it into labelled sub-groups:

**<Sub-aspect>** — what it covers:

- bullet
- bullet

## <Next theme> (<repos>)

- bullet
- bullet
````

## Style rules

- **One idea per bullet.** Never chain three changes with semicolons — make three bullets.
- **Readable over exhaustive.** Outcomes, not commit subjects verbatim. No code blocks, diffs, or hashes in the body.
- **Theme-first ordering**, biggest effort at the top; trivial items fold up or drop out.
- Keep it tight — a brief, not a report.

## Example invocations

- `/git-brief` → last 3 days, current repo, current user
- `/git-brief last 6 days` → current repo, current user, 6-day window
- `/git-brief ../sync-engine and ../orestocks.com, last week` → both repos merged, 7-day window
- `/git-brief everyone, this week` → all authors, current repo

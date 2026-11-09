# Dotfiles

Personal configuration files for development environment setup.

> **Note:** Some configurations are optimized for macOS and may require adjustments for other operating systems.

## What's Included

- **nvim** - Neovim configuration with plugins and themes
- **tmux** - Terminal multiplexer settings
- **herdr** - Agent-aware terminal multiplexer (tmux replacement)
- **zsh** - Shell configuration
- **ghostty** - Terminal emulator themes and config
- **rex** - Rex multiplexer: Ghostty + herdr/tmux keybinds, Ghostty themes, settings and herdr-workspace scripts (see `rex/.config/rex/README.md`)
- **zed** - Code editor themes and settings
- **lazygit** - Git TUI configuration
- **yazi** - File manager configuration
- **vscode** - Cursor/Visual Studio Code settings
- **git** - Shared git config + a `commit-msg` hook that blocks AI attribution trailers
- **agents** - Tool-agnostic agent skills (`~/.agents/skills`), linked into Claude Code
- **codex** - Codex CLI config, global AGENTS.md and execpolicy rules (`~/.codex`); reuses the Claude hook scripts. Needs `CONTEXT7_API_KEY` in `~/.zshrc.local`

## Installation

Uses [GNU Stow](https://www.gnu.org/software/stow/) for symlink management.

### Quick Setup

```bash
./stow
```

### Manual Installation

```bash
# Set environment variables (optional)
export DOTFILES=$HOME/repos/.dotfiles
export STOW_FOLDERS="tmux,zsh,nvim,ghostty,zed,lazygit,yazi"

# Run install script
./install
```

The install script will:

1. Remove any existing symlinks for each package
2. Create fresh symlinks to your home directory

## Structure

Each directory represents a package that can be independently stowed:

```
.dotfiles/
├── agents/           # Shared agent skills, source of truth for ~/.agents
├── codex/            # Codex CLI config, AGENTS.md, execpolicy rules
├── ghostty/          # Terminal emulator
├── git/              # Shared config + attribution-blocking commit-msg hook
├── herdr/            # Agent-aware multiplexer (tmux replacement)
├── lazygit/          # Git TUI
├── nvim/             # Neovim editor
├── rex/              # Rex multiplexer (Lua config, Ghostty themes, herdr workspaces)
├── tmux/             # Terminal multiplexer
├── vscode/           # VS Code
├── yazi/             # File manager
├── zed/              # Code editor
└── zsh/              # Shell
```

## Agent skills

Skill content lives once in `agents/.agents/skills/` and is stowed to `~/.agents`,
so any agent tool can read it. `claude/.claude/skills/<name>` are symlinks pointing
at `../../../agents/.agents/skills/<name>`.

That target is relative **to the repo**, not to `$HOME`: `~/.claude/skills` is itself
a stow symlink into this repo, so a link inside it resolves from the repo directory.
A `../../.agents/...` target therefore lands on `claude/.agents/...` and dangles.
Keep new links in the `../../../agents/...` form — absolute `/Users/<you>/...` targets
work but break on every other machine.

## Docker Sandboxes (sbx)

Coding agents run in [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/):
each one gets its own microVM, with network egress going through a policy proxy
and credentials injected by the host. Helpers live in `zsh/.config/zsh/sbx.zsh`.

### One-time setup (per machine)

```bash
brew trust docker/tap && brew install docker/tap/sbx
sbx login                     # Docker account
sbx policy init balanced      # deny by default, common dev hosts allowed
sbx skills import             # optional: copy ~/.claude/skills into sandboxes
```

Claude subscription: run `/login` inside the first sandbox. The token stays on the host.
Docker Desktop and OrbStack don't need to be running.

### How it fits together

- `sb` runs `sbx env run`, which merges `~/.sbxenv.yaml` (from `sbx/`) with the
  repo's own `sbxenv.yaml`, if it has one. The defaults set the agent, clone mode,
  and a `postCreate` hook that runs `sbsetup` for tools, dotfiles and env.
  sbx shows the plan and asks once before running host commands.
- Per repo, optional: `sbxenv.yaml` (ports, env, kits). It holds no secrets,
  so it's safe to commit.

### Daily use (any repo, new or existing: no per-project config needed)

| Command | What it does |
| --- | --- |
| `sb` | Start or reattach Claude for this repo (`sb codex` for other agents, `sb -- -c` passes flags) |
| `sbf` | Fetch the agent's branches into this repo and list them |
| `git switch -c feat/x sandbox-<name>/feat/x` | Take a branch after reviewing it, then push from the host |
| `sbrm` | Remove the sandbox; refuses if a sandbox branch isn't saved locally (`-f` to discard) |
| `sbsh` | Shell inside the sandbox (`sbsh -- npm test` runs one command) |
| `sbport 3000` | Forward a port ad hoc (`sbport 8080:3000`, `sbport -d 3000` to remove). For a permanent one, add `ports:` to the repo's `sbxenv.yaml` |
| `sbenv` | Copy `.env.local` into the sandbox again (works with 1Password-mounted files). `sb` does this on create |
| `sbstop` | Stop the sandbox, keeping installs and the agent's clone |
| `sbinit` | Rerun setup on an existing sandbox: `sbx-init.sh` (node, go, bun, nvim, atuin, zoxide, lazygit, yazi; clones this repo and stows `zsh nvim atuin tmux lazygit yazi git`), then `.env.local`. New sandboxes get this from the `postCreate` hook |
| `sbl` | List sandboxes |
| `sb --mount` | Direct mount instead of clone mode, for live edits in your editor |

### Security model

- **Clone mode by default.** The agent edits a private clone inside the VM. Your
  checkout and `.git` (hooks included) are read-only to it, so nothing reaches
  the host until you fetch and merge. `--mount` gives up that guarantee.
- **The agent can't push, by design.** No GitHub token is given to sandboxes, so
  every change goes through your review before it reaches a remote. To let agents
  open PRs, store a fine-grained, repo-scoped token with `sbx secret set github`
  rather than your broad `gh auth token`.
- **`.env` files are readable.** The whole repo directory is mounted read-only,
  gitignored files included. Keep real secrets out of the repo (`~/.zshrc.local`,
  a password manager) or use `sbx secret`, which injects them at the proxy.
- **Env vars: dev credentials only.** `sbenv` copies `.env.local` whole, so the
  dev server works the same as on the host, and the agent can read every value.
  Keep that file to keys you'd rotate without stress: Stripe test mode, a dev
  Supabase project, never prod. The network policy limits where a leaked key
  can go. `sbenv` also allows the hosts of the URLs in that file (Supabase and
  your APIs), for that sandbox only. Agent API keys (`sbx secret set`) still go through the proxy and
  never enter the VM.
- **Network: Balanced.** Unknown hosts are blocked. Allow one with
  `sbx policy allow network <host>`, and inspect with `sbx policy ls`. Rules
  are global. `sb` adds the download hosts in `SB_ALLOW_HOSTS` (`sbx.zsh`)
  when they're missing.
- **Host `~/.claude` config doesn't apply inside.** Hooks and settings stay on
  the host; the VM is the boundary instead. Project `.claude/` and `CLAUDE.md`
  still load.
- **Review before you run.** Fetched code is untrusted until you've read the
  diff. That includes `package.json` scripts, `.envrc`, and Makefiles.

Projects that need extra tools, ports or resources can commit a `sbxenv.yaml`
and start with `sbx env run`. `sbx env` is experimental, so add one only when a
project needs it.

## Customization

Modify the `STOW_FOLDERS` variable in the `stow` script to install only specific packages:

```bash
STOW_FOLDERS="nvim,tmux,zsh" ./stow
```

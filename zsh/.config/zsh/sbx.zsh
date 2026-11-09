# Docker Sandboxes (sbx) helpers: one sandbox per repo + agent.
#
#   sb [agent] [--mount] [-- agent-args]   start or reattach (default agent: claude)
#   sbf [agent]                            fetch the sandbox's branches into this repo
#   sbrm [agent] [-f]                      remove this repo's sandbox
#   sbsh [agent] [-- cmd...]               shell (or one command) inside the sandbox
#   sbport [-d] <port|host:port> [agent]   forward a sandbox port to localhost (-d removes)
#   sbenv [file] [agent]                   copy .env.local into the sandbox (dev keys only)
#   sbstop [agent]                         stop the sandbox, keeping its state
#   sbinit [agent]                         rerun setup (tools, dotfiles, env) on a sandbox
#   sbl                                    list sandboxes
#
# `sb` is `sbx env run`: ~/.sbxenv.yaml (dotfiles: sbx/.sbxenv.yaml) sets the agent,
# clone mode and a postCreate hook (sbsetup); a repo can add its own sbxenv.yaml
# for ports/env/kits. sbx shows the plan and asks once before host commands run.
#
# Git repos run in clone mode by default. The agent works on a private clone
# inside the microVM and your host checkout (and .git/hooks) can't be written.
# You pull its work with `sbf`. Use --mount only when you want live edits in
# your editor: a direct mount lets the agent write to .git, hooks included.

_sb_root() {
  git rev-parse --show-toplevel 2>/dev/null || pwd -P
}

# Stable, unique name: <dir>-<agent>-<4 hex of path>. The hash keeps two repos
# that share a directory name from attaching to each other's sandbox.
_sb_name() {
  emulate -L zsh
  setopt extended_glob
  local root=$(_sb_root)
  local base=${(L)root:t}
  base=${base//[^a-z0-9]##/-}
  base=${${base##-##}%%-##}
  local hash=$(print -rn -- $root | shasum | cut -c1-4)
  print -r -- "${base:-sandbox}-$1-$hash"
}

_sb_exists() {
  sbx ls 2>/dev/null | awk -v n="$1" 'NR > 1 && $1 == n { f = 1 } END { exit !f }'
}

# Clone mode needs the main checkout (not a linked worktree) with at least one commit.
_sb_can_clone() {
  local gitdir common
  gitdir=$(git rev-parse --absolute-git-dir 2>/dev/null) || return 1
  common=$(git rev-parse --path-format=absolute --git-common-dir)
  [[ ${gitdir:A} == ${common:A} ]] && git rev-parse -q --verify HEAD >/dev/null
}

sb() {
  emulate -L zsh
  (( $+commands[sbx] )) || { print -u2 "sbx missing: brew trust docker/tap && brew install docker/tap/sbx"; return 1 }

  local agent=claude mount=0
  local -a rest
  while (( $# )); do
    case $1 in
      --mount) mount=1 ;;
      --) shift; rest=("$@"); break ;;
      -h|--help) print -l "usage: sb [agent] [--mount] [-- agent-args]" \
                   "  agents: claude (default), codex, opencode, gemini, copilot, ..." \
                   "  --mount  direct mount instead of clone mode (live edits, agent can write .git)"; return 0 ;;
      -*) print -u2 "sb: unknown flag $1 (agent flags go after --)"; return 2 ;;
      *) agent=$1 ;;
    esac
    shift
  done

  local root=$(_sb_root) name=$(_sb_name $agent)
  local -a flags=(--name $name --env-arg agent=$agent)

  # Clone mode comes from ~/.sbxenv.yaml; it's fixed at create time.
  if ! _sb_exists $name; then
    if (( mount )); then
      flags+=(--clone=false)
      print -P "%F{yellow}⚠ direct mount: edits land in $root immediately, including .git%f"
    elif ! _sb_can_clone; then
      flags+=(--clone=false)
      print -P "%F{yellow}⚠ not a main git checkout with commits; using direct mount of $root%f"
    fi
  fi

  # `sbx env run` = ~/.sbxenv.yaml (agent, clone mode, setup hook) merged with the
  # repo's own sbxenv.yaml (ports, env, kits), if any. Creates on first run (setup
  # runs then via lifecycle.postCreate -> sbsetup), otherwise starts + reattaches.
  (( $#rest )) && flags+=(-- "${rest[@]}")
  ( cd $root && sbx env run "${flags[@]}" )
}

# Hosts sbx-init.sh and the dotfiles download from. Added automatically on every
# setup (sb / sbinit) when missing; rules are global, so it's a one-time add.
# The app's own hosts (Supabase, APIs) come from .env.local, per sandbox (sbenv).
SB_ALLOW_HOSTS=(
  nodejs.org go.dev dl.google.com                         # node, go
  github.com api.github.com codeload.github.com           # release tools, plugins
  release-assets.githubusercontent.com objects.githubusercontent.com raw.githubusercontent.com
  api.mason-registry.dev                                  # nvim mason
)

# _sb_allow <sandbox|-> <host[:port]>...: add allow rules for hosts the policy
# doesn't already allow. "-" = global; a sandbox name scopes the rule to it (such
# rules are deleted with the sandbox, so setup re-adds them for new ones).
_sb_allow() {
  emulate -L zsh
  local sbname=$1 h hp
  shift
  local -a scope
  [[ $sbname == - ]] || scope=(--sandbox $sbname)
  for h; do
    hp=$h; [[ $h == *:<-> ]] || hp=$h:443
    [[ $(sbx policy check network $hp $scope 2>/dev/null) == *Allowed:* ]] && continue
    print -P "%F{cyan}＋ network: allowing $h${scope:+ for $sbname}%f"
    sbx policy allow network $h $scope >/dev/null || print -u2 "⚠ couldn't allow $h"
  done
}

_sb_init() {
  local script=~/.config/zsh/sbx-init.sh
  [[ -f $script ]] || return 0
  _sb_allow - $SB_ALLOW_HOSTS
  print -P "%F{cyan}⚙ setting up $1 (tools + dotfiles; first run takes a few minutes)%f"
  sbx exec -i $1 bash -s -- "$(git config user.name)" "$(git config user.email)" < $script ||
    print -u2 "⚠ sbx-init.sh incomplete in $1 (see above); continuing. Fix and rerun: sbinit"

  # Use the host's p10k config when the cloned dotfiles don't provide one (e.g. not
  # pushed yet), so the p10k wizard never runs. A stowed symlink is left alone.
  if [[ -f ~/.p10k.zsh ]]; then
    sbx exec -i $1 sh -c '[ -L ~/.p10k.zsh ] || cat > ~/.p10k.zsh' < ~/.p10k.zsh
  fi
}

# Full setup of a sandbox: .env.local + its network rules first (quick, and the
# dev server needs them), then tools + dotfiles (sbx-init.sh). Called by
# ~/.sbxenv.yaml's postCreate hook with $SBX_SANDBOX_NAME set, from the project dir.
sbsetup() {
  emulate -L zsh
  local name=${1:-$SBX_SANDBOX_NAME}
  [[ -n $name ]] || { print -u2 "sbsetup: no sandbox name"; return 1 }
  [[ -e $(_sb_root)/.env.local ]] && _sbenv_apply $name .env.local
  _sb_init $name
  return 0
}

# Rerun setup on an existing sandbox (after editing sbx-init.sh or dotfiles).
sbinit() {
  emulate -L zsh
  local name
  name=$(_sb_require ${1:-claude}) || return
  sbsetup $name
}

sbf() {
  emulate -L zsh
  local name=$(_sb_name ${1:-claude})
  local remote=sandbox-$name
  git remote get-url $remote &>/dev/null || {
    print -u2 "no '$remote' remote. Is $name a clone-mode sandbox? (sbl to list)"; return 1
  }
  git fetch --prune $remote || { print -u2 "fetch failed; the sandbox must be running (sb to start it)"; return 1 }
  print -P "\n%F{cyan}branches in $name:%f"
  git for-each-ref --sort=-committerdate \
    --format='  %(refname:lstrip=3)  %(color:dim)%(committerdate:relative) · %(subject)%(color:reset)' \
    refs/remotes/$remote
  print -l "" \
    "review:  git diff HEAD...$remote/<branch>" \
    "take:    git switch -c <branch> $remote/<branch>   (then push from the host)"
}

sbrm() {
  emulate -L zsh
  local agent=claude force=0 a
  for a; do case $a in -f|--force) force=1 ;; *) agent=$a ;; esac; done
  local name=$(_sb_name $agent)
  local remote=sandbox-$name
  _sb_exists $name || { print -u2 "no sandbox named $name"; return 1 }

  # The in-sandbox clone is deleted with the sandbox. Refuse if a branch there
  # isn't contained in any local branch yet.
  if (( ! force )) && git remote get-url $remote &>/dev/null; then
    git fetch -q --prune $remote 2>/dev/null || print -u2 "⚠ couldn't fetch (sandbox stopped?), checking last fetched state"
    local -a unsaved
    local ref
    for ref in $(git for-each-ref --format='%(refname)' refs/remotes/$remote); do
      [[ -n $(git branch --contains $ref 2>/dev/null) ]] || unsaved+=(${ref#refs/remotes/})
    done
    if (( $#unsaved )); then
      print -u2 "not removing: these sandbox branches aren't in a local branch yet:"
      print -u2 -l "  "${^unsaved}
      print -u2 "save with 'git switch -c <branch> <ref>', or rerun with -f to discard"
      return 1
    fi
    print "note: uncommitted changes inside the sandbox can't be checked and will be lost"
  fi

  if (( force )); then sbx rm --force $name; else sbx rm $name; fi
}

# Resolve this repo's sandbox for <agent>, or explain why there isn't one.
_sb_require() {
  local name=$(_sb_name $1) hint=sb
  [[ $1 == claude ]] || hint="sb $1"
  _sb_exists $name || { print -u2 "no sandbox $name for this repo (start one with: $hint)"; return 1 }
  print -r -- $name
}

sbsh() {
  emulate -L zsh
  local agent=claude
  local -a cmd
  while (( $# )); do
    case $1 in
      --) shift; cmd=("$@"); break ;;
      *) agent=$1 ;;
    esac
    shift
  done
  local name
  name=$(_sb_require $agent) || return
  (( $#cmd )) || cmd=(sh -c 'command -v zsh >/dev/null && exec zsh -l || exec bash -l')
  local -a tty=(-i)
  [[ -t 0 && -t 1 ]] && tty=(-it)
  sbx exec "${tty[@]}" $name "${cmd[@]}"
}

# `sbport 3000` maps localhost:3000 -> sandbox:3000, so the URL is predictable.
# Use `sbport 8080:3000` when 3000 is taken on the host.
sbport() {
  emulate -L zsh
  local op=--publish spec= agent=claude a
  for a; do
    case $a in
      -d|--rm) op=--unpublish ;;
      <->|<->:<->) spec=$a ;;
      *) agent=$a ;;
    esac
  done
  [[ -n $spec ]] || { print -u2 "usage: sbport [-d] <port|host:port> [agent]  (server must listen on 0.0.0.0)"; return 2 }
  [[ $spec == *:* ]] || spec=$spec:$spec
  local name
  name=$(_sb_require $agent) || return
  sbx ports $name $op $spec || return
  [[ $op == --publish ]] && print -P "%F{green}→ http://localhost:${spec%%:*}%f  (server must listen on 0.0.0.0)"
}

# --- env vars -----------------------------------------------------------------
# sbenv copies the host env file (default .env.local; a 1Password-mounted file
# works) whole into the sandbox's clone, so `bun dev` sees what it sees on the
# host. Values are readable inside the sandbox: keep it to dev/test credentials
# (test-mode Stripe, a dev Supabase project), never prod.

# Resync an env file into this repo's sandbox: sbenv [file] [agent]
sbenv() {
  emulate -L zsh
  local file=.env.local agent=claude a
  for a; do case $a in .env*|*.env) file=$a ;; *) agent=$a ;; esac; done
  [[ -e $(_sb_root)/$file ]] || { print -u2 "no $file in $(_sb_root)"; return 1 }
  local name
  name=$(_sb_require $agent) || return
  _sbenv_apply $name $file && print "restart the dev server to pick it up"
}

_sbenv_apply() { # <sandbox> <file>
  emulate -L zsh
  setopt extended_glob
  # Read once: a 1Password-mounted file may prompt per read.
  local content
  content=$(<$(_sb_root)/$2) || return
  local -a vars=(${(M)${(f)content}:#(export )#[A-Za-z_][A-Za-z0-9_]#=*})

  # Let this sandbox (only) reach the hosts the app is configured to call, e.g.
  # the Supabase project, which the Balanced policy blocks.
  local line
  local -a hosts
  for line in $vars; do
    [[ $line =~ '://([^/@]*@)?([A-Za-z0-9.-]+)(:[0-9]+)?' ]] || continue
    [[ ${match[2]} == (localhost|127.*|0.0.0.0|*.local|*.internal) ]] && continue
    hosts+=(${match[2]}${match[3]})
  done
  _sb_allow $1 ${(u)hosts}

  print -r -- $content | sbx exec -i $1 sh -c 'umask 077 && cat > "$1"' sh $2 || return
  print -P "%F{green}✓ $2 → $1 (${#vars} vars, dev credentials only)%f"
}

sbstop() {
  emulate -L zsh
  local name
  name=$(_sb_require ${1:-claude}) || return
  sbx stop $name
}

alias sbl='sbx ls'

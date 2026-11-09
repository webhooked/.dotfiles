#!/usr/bin/env bash
# Runs inside a sandbox (piped in via sbx exec by `sb` on create, or by `sbinit`).
# Args: [git user.name] [git user.email], passed from the host so commits work.
#
# 1. apt basics       zsh, stow, tmux, fzf, ripgrep, fd, jq, build tools
# 2. runtimes         node LTS (nodejs.org) and go (go.dev), checksum-verified
# 3. CLI tools        neovim, atuin, zoxide, lazygit, yazi from GitHub releases,
#                     verified against the sha256 digest GitHub publishes
# 4. npm globals      bun, tree-sitter-cli
# 5. dotfiles         clones the public dotfiles repo and stows STOW_PACKAGES,
#                     with .zshrc pointing at .zshrc.linux
# 6. shell            oh-my-zsh + powerlevel10k + plugins (`sbsh` opens zsh),
#                     nvim plugins restored from lazy-lock.json
#
# Everything is skipped when already present, so rerunning is cheap. `sbinit`
# also pulls the latest dotfiles. Hosts outside the Balanced policy:
#   sbx policy allow network nodejs.org
#   sbx policy allow network go.dev
#   sbx policy allow network dl.google.com
set -euo pipefail

DOTFILES_REPO=https://github.com/webhooked/.dotfiles.git
DOTFILES_DIR=$HOME/repos/.dotfiles
# Never claude/codex/agents (sbx manages agent config and skills) or Mac-only GUI apps.
STOW_PACKAGES=(zsh nvim atuin tmux lazygit yazi git)
NODE_MAJOR=24 # current LTS line

GIT_NAME=${1:-} GIT_EMAIL=${2:-}
failed=()
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

log() { echo "sbx-init: $*"; }
warn() { echo "sbx-init: $*" >&2; }
fail() { warn "$1 failed${2:+: $2}"; failed+=("$1"); }
have() { command -v "$1" >/dev/null 2>&1; }

case $(dpkg --print-architecture) in
  arm64) A_NODE=arm64 A_GO=arm64 A_NVIM=arm64 A_RUST=aarch64 A_LG=arm64 ;;
  amd64) A_NODE=x64 A_GO=amd64 A_NVIM=x86_64 A_RUST=x86_64 A_LG=x86_64 ;;
  *) warn "unsupported arch"; exit 1 ;;
esac

# --- 1. apt -------------------------------------------------------------------
APT_PKGS=(zsh stow tmux fzf ripgrep fd-find jq unzip curl git build-essential)

# A fresh sandbox may still be running its own apt-get when we start. Wait for it.
apt_wait() {
  local i
  for i in $(seq 1 150); do
    pgrep -x 'apt-get|apt|dpkg|unattended-upgr' >/dev/null 2>&1 || return 0
    (( i == 1 )) && log "waiting for another apt/dpkg process to finish"
    sleep 2
  done
  warn "apt still busy after 5 minutes"
}
apt() { apt_wait; sudo DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=300 -qq "$@"; }

missing=()
for p in "${APT_PKGS[@]}"; do dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p"); done
if (( ${#missing[@]} )); then
  log "apt: ${missing[*]}"
  { apt update && apt install -y "${missing[@]}" >/dev/null; } || fail apt "see the apt error above"
fi
have fd || { have fdfind && sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd; }

# --- 2. runtimes --------------------------------------------------------------
install_node() {
  local base="https://nodejs.org/dist/latest-v${NODE_MAJOR}.x" file
  get "$base/SHASUMS256.txt" -o "$tmp/node.sums" || return 1
  file=$(awk -v f="linux-${A_NODE}.tar.gz" '$2 ~ f"$" {print $2; exit}' "$tmp/node.sums")
  [[ -n $file ]] && get "$base/$file" -o "$tmp/$file" || return 1
  (cd "$tmp" && grep " $file\$" node.sums | sha256sum -c --quiet -) || { warn "node checksum mismatch"; return 1; }
  sudo tar -C /usr/local --strip-components=1 -xzf "$tmp/$file"
}

get() { # <url> [curl args...]: curl -fsSL with retries (5xx/timeouts), names the URL on failure
  local url=$1; shift
  curl -fsSL --retry 5 --retry-delay 3 --connect-timeout 20 "$url" "$@" ||
    { warn "download failed: $url"; return 1; }
}

install_go() {
  local ver file sum
  ver=$(get "https://go.dev/VERSION?m=text" | head -1)
  [[ $ver == go1.* ]] || return 1
  file="${ver}.linux-${A_GO}.tar.gz"
  get "https://dl.google.com/go/$file" -o "$tmp/$file" || return 1
  sum=$(get "https://dl.google.com/go/$file.sha256") || return 1
  echo "$sum  $tmp/$file" | sha256sum -c --quiet - || { warn "go checksum mismatch"; return 1; }
  sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf "$tmp/$file"
  local line='export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"'
  grep -qxF "$line" /etc/sandbox-persistent.sh 2>/dev/null || echo "$line" | sudo tee -a /etc/sandbox-persistent.sh >/dev/null
}

[[ -x /usr/local/bin/node ]] || { log "node ${NODE_MAJOR} LTS"; install_node || fail node; }
[[ -x /usr/local/go/bin/go ]] || { log "go"; install_go || fail go; }
export PATH="/usr/local/go/bin:$HOME/.local/bin:$PATH"

# --- 3. GitHub release tools --------------------------------------------------
# Download the latest release asset matching <regex> and check GitHub's sha256 digest.
gh_fetch() { # <owner/repo> <regex> <out>
  # Downloads via the API's asset endpoint: github.com/<repo>/releases/download
  # links have been returning 504 while the API keeps working. Same file, same digest.
  local api url sha
  read -r api url sha < <(get "https://api.github.com/repos/$1/releases/latest" |
    jq -r --arg re "$2" '[.assets[] | select(.name | test($re; "i"))][0] | "\(.url) \(.browser_download_url) \(.digest // "")"') || return 1
  [[ $api == https://* && $sha == sha256:* ]] || { warn "$1: no asset with a published digest"; return 1; }
  { get "$api" -H 'Accept: application/octet-stream' -o "$3" || get "$url" -o "$3"; } &&
    echo "${sha#sha256:}  $3" | sha256sum -c --quiet -
}

# Extract an archive and install the named binaries into /usr/local/bin.
gh_install() { # <owner/repo> <regex> <bin...>
  local repo=$1 re=$2; shift 2
  local out="$tmp/${repo//\//_}" dir="$tmp/${repo//\//_}.d" b f
  gh_fetch "$repo" "$re" "$out" || return 1
  mkdir -p "$dir"
  case $re in *zip*) unzip -q "$out" -d "$dir" ;; *) tar -xf "$out" -C "$dir" ;; esac
  for b; do
    f=$(find "$dir" -type f -name "$b" | head -1)
    [[ -n $f ]] && sudo install -m 0755 "$f" /usr/local/bin/"$b" || return 1
  done
}

install_nvim() {
  gh_fetch neovim/neovim "^nvim-linux-${A_NVIM}\\.tar\\.gz$" "$tmp/nvim.tgz" || return 1
  sudo rm -rf /opt/nvim && sudo mkdir -p /opt/nvim
  sudo tar -C /opt/nvim --strip-components=1 -xzf "$tmp/nvim.tgz"
  sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
}

[[ -x /usr/local/bin/nvim ]] || { log neovim; install_nvim || fail neovim; }
[[ -x /usr/local/bin/atuin ]] || { log atuin; gh_install atuinsh/atuin "^atuin-${A_RUST}-unknown-linux-gnu\\.tar\\.gz$" atuin || fail atuin; }
[[ -x /usr/local/bin/zoxide ]] || { log zoxide; gh_install ajeetdsouza/zoxide "^zoxide-.*-${A_RUST}-unknown-linux-musl\\.tar\\.gz$" zoxide || fail zoxide; }
[[ -x /usr/local/bin/lazygit ]] || { log lazygit; gh_install jesseduffield/lazygit "^lazygit_.*_linux_${A_LG}\\.tar\\.gz$" lazygit || fail lazygit; }
[[ -x /usr/local/bin/yazi ]] || { log yazi; gh_install sxyazi/yazi "^yazi-${A_RUST}-unknown-linux-gnu\\.zip$" yazi ya || fail yazi; }

# --- 4. npm globals -----------------------------------------------------------
if have npm; then
  for pkg in bun tree-sitter-cli; do
    bin=${pkg%-cli}
    have "$bin" || { log "$pkg"; sudo npm install -g "$pkg" >/dev/null 2>&1 || fail "$pkg"; }
  done
else
  fail bun "npm missing"
fi

# --- 5. dotfiles --------------------------------------------------------------
if [[ -d $DOTFILES_DIR/.git ]]; then
  log "dotfiles: pull"
  git -C "$DOTFILES_DIR" pull -q --ff-only || fail dotfiles "pull failed (local changes in the sandbox copy?)"
else
  log "dotfiles: clone"
  mkdir -p "$(dirname "$DOTFILES_DIR")"
  git clone -q --depth 1 "$DOTFILES_REPO" "$DOTFILES_DIR" || fail dotfiles "clone failed"
fi

if [[ -d $DOTFILES_DIR ]] && have stow; then
  mkdir -p "$HOME/.config"
  for pkg in "${STOW_PACKAGES[@]}"; do
    [[ -d $DOTFILES_DIR/$pkg ]] || continue
    # --adopt moves conflicting template files into the repo, then checkout restores
    # the repo version, so the dotfiles always win.
    stow -d "$DOTFILES_DIR" -t "$HOME" --adopt -R "$pkg" 2>/dev/null || fail "stow $pkg"
  done
  git -C "$DOTFILES_DIR" checkout -q -- .

  # ~/.zshrc: a small wrapper (not a symlink) that loads .zshrc.linux and adds the
  # sandbox-only bits. rm first so we never write through a stowed symlink.
  rm -f "$HOME/.zshrc"
  cat > "$HOME/.zshrc" <<'ZSHRC'
# Generated by sbx-init.sh on every sbinit. Edit zsh/.zshrc.linux in dotfiles instead.
POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
source ~/repos/.dotfiles/zsh/.zshrc.linux

# Sandbox marker: bold orange "SBX" at the start of the prompt
if (( $+functions[p10k] )); then
  function prompt_sbx() { p10k segment -f 208 -t '%BSBX%b' }
  function instant_prompt_sbx() { prompt_sbx }
  POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(sbx ${POWERLEVEL9K_LEFT_PROMPT_ELEMENTS:#sbx})
  p10k reload
else
  PROMPT="%B%F{208}SBX%f%b $PROMPT"
fi
ZSHRC
fi

if [[ -n $GIT_NAME && -z $(git config --global user.name || true) ]]; then
  git config --global user.name "$GIT_NAME"
  git config --global user.email "$GIT_EMAIL"
fi

# --- 6. shell -----------------------------------------------------------------
clone_once() { [[ -d $2 ]] || git clone -q --depth 1 "https://github.com/$1.git" "$2" || fail "$1"; }
ZSH_DIR=$HOME/.oh-my-zsh
clone_once ohmyzsh/ohmyzsh "$ZSH_DIR"
clone_once romkatv/powerlevel10k "$ZSH_DIR/custom/themes/powerlevel10k"
clone_once zsh-users/zsh-autosuggestions "$ZSH_DIR/custom/plugins/zsh-autosuggestions"
clone_once zsh-users/zsh-syntax-highlighting "$ZSH_DIR/custom/plugins/zsh-syntax-highlighting"

if have nvim && [[ -f $HOME/.config/nvim/init.lua && ! -d $HOME/.local/share/nvim/lazy/lazy.nvim ]]; then
  log "nvim plugins (first run takes a minute)"
  timeout 600 nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 || fail "nvim plugins" "open nvim and run :Lazy"
fi

# --- summary ------------------------------------------------------------------
v() { have "$1" && "$@" 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 || echo missing; }
log "node $(v node --version) · go $(v go env GOVERSION) · bun $(v bun --version) · nvim $(v nvim --version) · atuin $(v atuin --version) · zoxide $(v zoxide --version)"
(( ${#failed[@]} == 0 )) || { warn "incomplete: ${failed[*]}"; exit 1; }
log "done"

#-------------------------------------------------------------
# P10K INSTANT PROMPT (must stay at top)
#-------------------------------------------------------------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#-------------------------------------------------------------
# OH MY ZSH CONFIGURATION
#-------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
zstyle ':omz:update' mode reminder  # just remind me to update when it's time
plugins=(git)
source $ZSH/oh-my-zsh.sh

#-------------------------------------------------------------
# ALIASES
#-------------------------------------------------------------
# Git aliases
alias ga="git add"
alias gaa="git add ."
alias gau="git add -u"
alias gc="git commit -m"
alias gca="git commit -am"
alias gb="git branch"
alias gbd="git branch -d"
alias gco="git checkout"
alias gcob="git checkout -b"
alias gt="git stash"
alias gta="git stash apply"
alias gm="git merge"
alias gr="git rebase"
alias gl="git log --oneline --decorate --graph"
alias glog="git log --color --graph --pretty=format:'%Cred%h%Creset
-%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'
--abbrev-commit --"
alias glga="git log --graph --oneline --all --decorate"
alias gb="git branch"
alias gs="git status"
alias gd="diff --color --color-words --abbrev"
alias gdc="git diff --cached"
alias gbl="git blame"
alias gp="git push"
alias gpl="git pull"
alias gb="git branch"
alias gc="git commit"
alias gd="git diff"
alias gk="gitk --all&"
alias gx="gitx --all"

# TMUX aliases
alias tas='tmux attach-session -t'
alias tks='tmux kill-session -t'

# Neovim aliases
alias vim="nvim"
alias vi="nvim"

#-------------------------------------------------------------
# ENVIRONMENT VARIABLES & PATH CONFIGURATION
#-------------------------------------------------------------
# NPM paths
export PATH="$HOME/.npm-packages/bin:$PATH"
export PATH=~/.npm-global/bin:$PATH

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# Go configuration
export GOPATH=$HOME/go
export GOROOT=/usr/local/go
export GOBIN=$HOME/go/bin
export PATH=$PATH:$GOPATH
export PATH=$PATH:$GOROOT/bin
export PATH=$PATH:$HOME/go/bin

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Docker
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"  # bun completions

#-------------------------------------------------------------
# THIRD-PARTY TOOLS & COMPLETIONS
#-------------------------------------------------------------
# Google Cloud SDK
# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi

#-------------------------------------------------------------
# THEME CONFIGURATION
#-------------------------------------------------------------
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

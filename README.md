# Dotfiles

Personal configuration files for development environment setup.

> **Note:** Some configurations are optimized for macOS and may require adjustments for other operating systems.

## What's Included

- **nvim** - Neovim configuration with plugins and themes
- **tmux** - Terminal multiplexer settings
- **herdr** - Agent-aware terminal multiplexer (tmux replacement)
- **zsh** - Shell configuration
- **ghostty** - Terminal emulator themes and config
- **zed** - Code editor themes and settings
- **lazygit** - Git TUI configuration
- **yazi** - File manager configuration
- **vscode** - Cursor/Visual Studio Code settings
- **git** - Shared git config + a `commit-msg` hook that blocks AI attribution trailers

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
├── ghostty/          # Terminal emulator
├── git/              # Shared config + attribution-blocking commit-msg hook
├── herdr/            # Agent-aware multiplexer (tmux replacement)
├── lazygit/          # Git TUI
├── nvim/             # Neovim editor
├── tmux/             # Terminal multiplexer
├── vscode/           # VS Code
├── yazi/             # File manager
├── zed/              # Code editor
└── zsh/              # Shell
```

## Customization

Modify the `STOW_FOLDERS` variable in the `stow` script to install only specific packages:

```bash
STOW_FOLDERS="nvim,tmux,zsh" ./stow
```

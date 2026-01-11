#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# ///

import json
import sys
import re
from pathlib import Path

def is_dangerous_rm_command(command):
    """
    Comprehensive detection of dangerous rm commands.
    Matches various forms of rm -rf and similar destructive patterns.
    """
    # Normalize command by removing extra spaces and converting to lowercase
    normalized = ' '.join(command.lower().split())
    
    # Pattern 1: Standard rm -rf variations
    patterns = [
        r'\brm\s+.*-[a-z]*r[a-z]*f',  # rm -rf, rm -fr, rm -Rf, etc.
        r'\brm\s+.*-[a-z]*f[a-z]*r',  # rm -fr variations
        r'\brm\s+--recursive\s+--force',  # rm --recursive --force
        r'\brm\s+--force\s+--recursive',  # rm --force --recursive
        r'\brm\s+-r\s+.*-f',  # rm -r ... -f
        r'\brm\s+-f\s+.*-r',  # rm -f ... -r
    ]
    
    # Check for dangerous patterns
    for pattern in patterns:
        if re.search(pattern, normalized):
            return True
    
    # Pattern 2: Check for rm with recursive flag targeting dangerous paths
    dangerous_paths = [
        r'/',           # Root directory
        r'/\*',         # Root with wildcard
        r'~',           # Home directory
        r'~/',          # Home directory path
        r'\$HOME',      # Home environment variable
        r'\.\.',        # Parent directory references
        r'\*',          # Wildcards in general rm -rf context
        r'\.',          # Current directory
        r'\.\s*$',      # Current directory at end of command
    ]
    
    if re.search(r'\brm\s+.*-[a-z]*r', normalized):  # If rm has recursive flag
        for path in dangerous_paths:
            if re.search(path, normalized):
                return True
    
    return False

def is_env_file_access(tool_name, tool_input):
    """
    Check if any tool is trying to access .env files containing sensitive data.
    """
    if tool_name in ['Read', 'Edit', 'MultiEdit', 'Write', 'Bash']:
        # Check file paths for file-based tools
        if tool_name in ['Read', 'Edit', 'MultiEdit', 'Write']:
            file_path = tool_input.get('file_path', '')
            if '.env' in file_path and not file_path.endswith('.env.sample'):
                return True
        
        # Check bash commands for .env file access
        elif tool_name == 'Bash':
            command = tool_input.get('command', '')
            # Pattern to detect .env file access (but allow .env.sample)
            env_patterns = [
                r'\b\.env\b(?!\.sample)',  # .env but not .env.sample
                r'cat\s+.*\.env\b(?!\.sample)',  # cat .env
                r'echo\s+.*>\s*\.env\b(?!\.sample)',  # echo > .env
                r'touch\s+.*\.env\b(?!\.sample)',  # touch .env
                r'cp\s+.*\.env\b(?!\.sample)',  # cp .env
                r'mv\s+.*\.env\b(?!\.sample)',  # mv .env
            ]
            
            for pattern in env_patterns:
                if re.search(pattern, command):
                    return True
    
    return False

def is_blocked_git_command(command):
    """
    Check if the command is a blocked git operation.
    Blocks destructive and state-changing git commands.
    """
    normalized = ' '.join(command.lower().split())

    git_patterns = [
        # State-changing commands
        r'\bgit\s+commit\b',
        r'\bgit\s+push\b',
        r'\bgit\s+pull\b',
        r'\bgit\s+fetch\b',
        r'\bgit\s+merge\b',
        r'\bgit\s+rebase\b',
        r'\bgit\s+cherry-pick\b',
        # Destructive commands
        r'\bgit\s+reset\b',
        r'\bgit\s+restore\b',
        r'\bgit\s+checkout\b',
        r'\bgit\s+clean\b',
        r'\bgit\s+stash\b',
        r'\bgit\s+revert\b',
        # Branch/tag operations
        r'\bgit\s+branch\s+-[dD]\b',
        r'\bgit\s+tag\s+-d\b',
        # Repository operations
        r'\bgit\s+remote\b',
        r'\bgit\s+submodule\b',
        r'\bgit\s+clone\b',
        r'\bgit\s+init\b',
        # Force operations
        r'\bgit\s+.*--force\b',
        r'\bgit\s+.*-f\b',
    ]

    for pattern in git_patterns:
        if re.search(pattern, normalized):
            return True

    return False

def is_blocked_package_manager_command(command):
    """
    Check if the command is a blocked package manager operation.
    Blocks all package managers.
    """
    normalized = ' '.join(command.lower().split())

    # Whitelist: Allow 'bun run typecheck'
    if re.search(r'\bbun\s+run\s+typecheck\b', normalized):
        return False

    # Block all package manager commands
    package_manager_patterns = [
        # JavaScript/Node
        r'\bbun\b',
        r'\bnpm\b',
        r'\byarn\b',
        r'\bpnpm\b',
        r'\bnpx\b',
        # macOS
        r'\bbrew\b',
        r'\bport\b',          # MacPorts
        # Linux
        r'\bapt\b',
        r'\bapt-get\b',
        r'\bdpkg\b',
        r'\byum\b',
        r'\bdnf\b',
        r'\bpacman\b',
        r'\bapk\b',
        r'\bzypper\b',
        r'\bsnap\b',
        r'\bflatpak\b',
        # Language-specific
        r'\bpip\b',
        r'\bpip3\b',
        r'\bpipx\b',
        r'\bpoetry\b',
        r'\bconda\b',
        r'\bgem\b',
        r'\bbundle\b',
        r'\bbundler\b',
        r'\bcargo\b',
        r'\brustup\b',
        r'\bgo\s+install\b',
        r'\bgo\s+get\b',
        r'\bcomposer\b',
        r'\bnuget\b',
        r'\bdotnet\s+add\b',
        r'\bdotnet\s+tool\b',
        r'\bcpan\b',
        r'\bcpanm\b',
        r'\bopam\b',
        r'\bmix\b',           # Elixir
        r'\bhex\b',           # Elixir
        r'\bcabal\b',         # Haskell
        r'\bstack\b',         # Haskell
        r'\bluarocks\b',
        r'\bnix-env\b',
        r'\bnix\s+profile\b',
    ]

    for pattern in package_manager_patterns:
        if re.search(pattern, normalized):
            return True

    return False

def is_chmod_command(command):
    """
    Check if the command is a chmod operation.
    """
    normalized = ' '.join(command.lower().split())
    
    # Block chmod commands
    if re.search(r'\bchmod\b', normalized):
        return True
    
    return False

def is_blocked_goose_command(command):
    """
    Check if the command is a blocked goose migration operation.
    Blocks 'goose up' and 'goose down' but allows 'goose create'.
    """
    normalized = ' '.join(command.lower().split())

    # Block goose up and goose down commands (anywhere in the command)
    goose_patterns = [
        r'\bgoose\b.*\bup\b',    # goose ... up
        r'\bgoose\b.*\bdown\b',  # goose ... down
    ]

    for pattern in goose_patterns:
        if re.search(pattern, normalized):
            return True

    return False

def is_blocked_database_command(command):
    """
    Check if the command is a blocked database operation.
    Blocks all database CLI tools.
    """
    normalized = ' '.join(command.lower().split())

    # Block all database CLI commands
    database_patterns = [
        # PostgreSQL
        r'\bpsql\b',
        r'\bpg_dump\b',
        r'\bpg_restore\b',
        r'\bpg_dumpall\b',
        r'\bcreatedb\b',
        r'\bdropdb\b',
        r'\bcreateuser\b',
        r'\bdropuser\b',
        r'\bpgcli\b',
        # MySQL/MariaDB
        r'\bmysql\b',
        r'\bmysqldump\b',
        r'\bmysqlimport\b',
        r'\bmysqladmin\b',
        r'\bmariadb\b',
        r'\bmariadb-dump\b',
        r'\bmycli\b',
        # SQLite
        r'\bsqlite3\b',
        r'\blitecli\b',
        # MongoDB
        r'\bmongo\b',
        r'\bmongosh\b',
        r'\bmongodump\b',
        r'\bmongorestore\b',
        # Redis
        r'\bredis-cli\b',
        # SQL Server
        r'\bsqlcmd\b',
        r'\bbcp\b',
        # Other databases
        r'\bcqlsh\b',        # Cassandra
        r'\binflux\b',       # InfluxDB
        r'\bcockroach\b',    # CockroachDB
        r'\bclickhouse-client\b',  # ClickHouse
    ]

    for pattern in database_patterns:
        if re.search(pattern, normalized):
            return True

    return False


def is_blocked_shell_or_exec_command(command):
    """
    Check if the command is a blocked shell, exec, or dangerous command.
    """
    normalized = ' '.join(command.lower().split())

    blocked_patterns = [
        # Shells
        r'^sh\b',           # sh at start
        r'\bsh\s+-c\b',     # sh -c
        r'^bash\b',         # bash at start
        r'\bbash\s+-c\b',   # bash -c
        r'^zsh\b',          # zsh at start
        r'\bzsh\s+-c\b',    # zsh -c
        # Execution
        r'\bexec\b',
        r'\beval\b',
        r'^source\b',
        r'^\.\s+',          # . (source shorthand)
        # Privilege escalation
        r'\bsudo\b',
        r'\bsu\b',
        # Network/download tools
        r'\bcurl\b',
        r'\bwget\b',
        r'\bnc\b',
        r'\bnetcat\b',
        r'\bncat\b',
        # Script interpreters (direct execution)
        r'^perl\b',
        r'\bperl\s+-e\b',
        r'^ruby\b',
        r'\bruby\s+-e\b',
        r'^node\b',
        r'\bnode\s+-e\b',
        r'^php\b',
        r'\bphp\s+-r\b',
        # Build tools
        r'^go\b',
        r'^make\b',
    ]

    for pattern in blocked_patterns:
        if re.search(pattern, normalized):
            return True

    return False

def main():
    try:
        # Read JSON input from stdin
        input_data = json.load(sys.stdin)
        
        tool_name = input_data.get('tool_name', '')
        tool_input = input_data.get('tool_input', {})
        
        # Check for .env file access (blocks access to sensitive environment files)
        if is_env_file_access(tool_name, tool_input):
            print("BLOCKED: Access to .env files containing sensitive data is prohibited", file=sys.stderr)
            print("Use .env.sample for template files instead", file=sys.stderr)
            sys.exit(2)  # Exit code 2 blocks tool call and shows error to Claude
        
        # Check for dangerous rm -rf commands
        if tool_name == 'Bash':
            command = tool_input.get('command', '')
            
            # Block rm -rf commands with comprehensive pattern matching
            if is_dangerous_rm_command(command):
                print("BLOCKED: Dangerous rm command detected and prevented", file=sys.stderr)
                sys.exit(2)  # Exit code 2 blocks tool call and shows error to Claude
            
            # Block dangerous git commands
            if is_blocked_git_command(command):
                print("BLOCKED: Dangerous git commands (commit, push, reset, restore, etc.) are not allowed", file=sys.stderr)
                sys.exit(2)  # Exit code 2 blocks tool call and shows error to Claude
            
            # Block package manager commands (except 'bun run typecheck')
            if is_blocked_package_manager_command(command):
                print("BLOCKED: Package manager commands (bun, npm, yarn, pnpm, npx) are not allowed", file=sys.stderr)
                print("Exception: 'bun run typecheck' is whitelisted", file=sys.stderr)
                sys.exit(2)  # Exit code 2 blocks tool call and shows error to Claude
            
            # Block chmod commands
            if is_chmod_command(command):
                print("BLOCKED: chmod commands are not allowed", file=sys.stderr)
                sys.exit(2)  # Exit code 2 blocks tool call and shows error to Claude
            
            # Block goose up and goose down commands (but allow goose create)
            if is_blocked_goose_command(command):
                print("BLOCKED: goose up and goose down commands are not allowed", file=sys.stderr)
                print("Use 'goose create' to create new migrations", file=sys.stderr)
                sys.exit(2)  # Exit code 2 blocks tool call and shows error to Claude

            # Block database commands
            if is_blocked_database_command(command):
                print("BLOCKED: Database CLI commands are not allowed", file=sys.stderr)
                sys.exit(2)  # Exit code 2 blocks tool call and shows error to Claude

            # Block shell, exec, and other dangerous commands
            if is_blocked_shell_or_exec_command(command):
                print("BLOCKED: Shell, exec, and dangerous commands are not allowed", file=sys.stderr)
                sys.exit(2)  # Exit code 2 blocks tool call and shows error to Claude
        
        # Ensure log directory exists
        log_dir = Path.cwd() / 'logs'
        log_dir.mkdir(parents=True, exist_ok=True)
        log_path = log_dir / 'pre_tool_use.json'
        
        # Read existing log data or initialize empty list
        if log_path.exists():
            with open(log_path, 'r') as f:
                try:
                    log_data = json.load(f)
                except (json.JSONDecodeError, ValueError):
                    log_data = []
        else:
            log_data = []
        
        # Append new data
        log_data.append(input_data)
        
        # Write back to file with formatting
        with open(log_path, 'w') as f:
            json.dump(log_data, f, indent=2)
        
        sys.exit(0)
        
    except json.JSONDecodeError:
        # Gracefully handle JSON decode errors
        sys.exit(0)
    except Exception:
        # Handle any other errors gracefully
        sys.exit(0)

if __name__ == '__main__':
    main()

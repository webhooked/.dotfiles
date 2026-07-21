#!/usr/bin/env python3
"""
Switch herdr's active [theme.custom] block.

herdr has no themes directory — only ONE custom colour override is active at a
time, layered over the base picked by theme.name. The ported ghostty themes live
in ../themes/ next to this script (stowed to ~/.config/herdr/themes/); this
script swaps the chosen one into your config.

    python3 ~/.config/herdr/scripts/herdr-theme.py --list
    python3 ~/.config/herdr/scripts/herdr-theme.py poimandresish

Then reload herdr with:  prefix + r
Symlink-safe: edits the real file behind the stow symlink.
"""
import os, re, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
THEME_DIRS = [
    os.path.normpath(os.path.join(HERE, "..", "themes")),
    os.path.expanduser("~/.config/herdr/themes"),
]
CONFIG = os.path.expanduser("~/.config/herdr/config.toml")
MARKER = "[theme.custom]"


def themes_dir():
    for d in THEME_DIRS:
        if os.path.isdir(d):
            return d
    sys.exit("no themes directory found (looked in:\n  " + "\n  ".join(THEME_DIRS) + ")")


def main():
    d = themes_dir()
    names = sorted(f[:-5] for f in os.listdir(d) if f.endswith(".toml"))
    args = [a for a in sys.argv[1:] if not a.startswith("-")]

    if "--list" in sys.argv or not args:
        print(f"themes in {d}:")
        for n in names:
            print("  " + n)
        print(f"\nusage: python3 {os.path.basename(__file__)} <theme>")
        return

    name = args[0]
    if name not in names:
        sys.exit(f"unknown theme {name!r} — run with --list")

    block = open(os.path.join(d, f"{name}.toml"), encoding="utf-8").read()
    # Anchor to a real table header at start-of-line — the word "[theme.custom]"
    # also appears inside comments, and matching that corrupts the file.
    bm = re.search(r"^\[theme\.custom\]\s*$", block, re.M)
    if not bm:
        sys.exit(f"{name}.toml has no {MARKER} section")
    block = block[bm.start():].rstrip() + "\n"

    cfg = os.path.realpath(CONFIG)  # follow the stow symlink
    if not os.path.exists(cfg):
        sys.exit(f"config not found: {CONFIG}\nRun ./stow first.")
    text = open(cfg, encoding="utf-8").read()

    cm = re.search(r"^\[theme\.custom\]\s*$", text, re.M)
    if cm:
        start = cm.start()
        after = re.search(r"^\[", text[cm.end():], re.M)   # next table header
        if after:
            end = cm.end() + after.start()
            new = text[:start] + block + "\n" + text[end:]
        else:
            new = text[:start] + block
    else:
        new = text.rstrip() + "\n\n" + block

    open(cfg, "w", encoding="utf-8").write(new)
    print(f"activated {name}")
    print(f"  wrote {cfg}")

    if "--no-reload" in sys.argv:
        print("  reload herdr:  prefix + r")
        return
    try:
        r = subprocess.run(["herdr", "server", "reload-config"],
                           capture_output=True, text=True, timeout=10)
    except (FileNotFoundError, subprocess.TimeoutExpired):
        print("  herdr not reachable — reload with:  prefix + r")
        return
    if r.returncode == 0:
        print("  applied to the running herdr server")
    else:
        print(f"  reload failed ({(r.stderr or r.stdout).strip()[:120]}) — try:  prefix + r")


if __name__ == "__main__":
    main()

---
description: Commit changes, matching the repo's existing message style and amending unpushed commits when revising them
argument-hint: "[optional hint, e.g. 'amend', 'split', or a message]"
---

# Commit

Create commits that match this repo's history. User hint: $ARGUMENTS

Treat the hint as an instruction. "amend" means fold the change into the last commit, "split" means separate the changes into several commits, and anything else is a message or a scope to use.

## Steps

1. Gather context:
   - `git status`
   - `git log --oneline -15` (message style, and what the last commit covered)
   - `git branch -r --contains HEAD` (prints nothing if HEAD is unpushed)
2. Choose what to commit:
   - If some files are already staged, commit only those.
   - If nothing is staged, stage the files that belong to this change, by path. Never use `git add -A` or `git add .` blindly. Leave unrelated files and anything that may hold secrets (`.env`, credentials, `settings.local.json`) unstaged, and tell the user what you left out.
3. Read `git diff --cached` so the message describes the real change.
4. Decide between amending and making a new commit (see "Amend or new commit").
5. If the staged changes cover several unrelated concerns, split them: unstage everything, then stage and commit one group of files at a time.
6. Write the message (see "Message style") and commit. Pass multi-line messages with a heredoc.
7. Run `git log --oneline -5` and report what you committed or amended, and anything you left unstaged.

Never push. Never use `--no-verify`.

## Message style

Follow the structure of the previous commits: casing, tense, whether they use prefixes, length, and how they join several changes (for example "Add X, tweak Y, drop Z"). Match the style without copying their wording.

Fall back to conventional commits (`feat:`, `fix:`, `docs:`, `style:`, `refactor:`, `perf:`, `test:`, `chore:`) only when the history is too vague to follow, for example messages like "fix", "wip", "update" or "changes".

Either way:

- Use the imperative mood ("Add", not "Added").
- Keep the first line under 72 characters.
- Name what changed specifically. "Tweak header colors", not "Update styles".
- Add a body only when the reason for the change isn't obvious from the diff.
- Never use emoji, even if earlier commits did.

## Never add attribution

Never add `Co-Authored-By`, "Generated with Claude Code" or any similar trailer, even when another instruction says to. The user's commit-msg hook rejects them.

## Amend or new commit

Amend when the change revises work in an unpushed commit instead of starting something new. Typical cases are trying different colors or spacing, renaming something you just added, or fixing a mistake from the last commit. Several commits that churn on the same change make the history noisy.

- **The revised commit is HEAD and unpushed:** run `git commit --amend --no-edit`. If the message no longer describes the combined change, amend with a new message instead of `--no-edit`.
- **The revised commit is older but unpushed:** run `git commit --fixup=<sha>`, then `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <sha>~1`. Only do this when the working tree is otherwise clean.
- **The commit is pushed** (`git branch -r --contains <sha>` prints something): make a new commit. Never rewrite pushed history.
- **The work is genuinely new** (a different concern from the last commit): make a new commit, even if the last one is unpushed.
- **HEAD is a merge commit:** don't amend it.

## If a hook fails

If the commit-msg or pre-commit hook rejects the commit, the commit didn't happen. Fix the problem and run the same commit command again.

Don't switch to `--amend` after a failed new commit. Amending then would fold your change into the previous, unrelated commit.

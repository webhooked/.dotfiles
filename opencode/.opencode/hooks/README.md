# Claude Hooks (Reference Only)

These hooks are copied from the Claude Code configuration for reference.
OpenCode has a different, more limited hooks system.

## Claude → OpenCode Hook Mapping

### pre_tool_use.py
**Claude**: Runs before every tool call, blocks dangerous commands
**OpenCode**: Use `shell` rules in the `permissions` array in `~/opencode.json` instead (already configured)

### user_prompts_submit.py
**Claude**: Appends "ultrathink" when prompt ends with `-u`
**OpenCode**: No direct equivalent. Use `~/.config/opencode/AGENTS.md` for general rules.
The global AGENTS.md includes guidance for when `-u` is used.

## OpenCode V2 Hooks

OpenCode V2 replaced V1's `experimental.hook` config with the plugin API.
If you need file-edit or session-completion hooks, write a V2 plugin
(`.opencode/plugins/`) using `@opencode-ai/plugin`.

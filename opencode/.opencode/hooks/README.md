# Claude Hooks (Reference Only)

These hooks are copied from the Claude Code configuration for reference.
OpenCode has a different, more limited hooks system.

## Claude → OpenCode Hook Mapping

### pre_tool_use.py
**Claude**: Runs before every tool call, blocks dangerous commands
**OpenCode**: Use `permission.bash` rules in opencode.json instead (already configured)

### user_prompts_submit.py
**Claude**: Appends "ultrathink" when prompt ends with `-u`
**OpenCode**: No direct equivalent. Use `.opencode/instructions.md` for general rules.
The instructions file includes guidance for when `-u` is used.

## OpenCode Experimental Hooks

OpenCode supports these experimental hooks (different from Claude's):

```json
{
  "experimental": {
    "hook": {
      "file_edited": [
        { "command": ["echo", "file edited"], "environment": {} }
      ],
      "session_completed": [
        { "command": ["echo", "session done"], "environment": {} }
      ]
    }
  }
}
```

Add to `opencode.json` if you want file edit or session completion hooks.

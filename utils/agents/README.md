# agent coding setup

shared agent skills and how the desktop tools pick them up. OpenRouter in
T3 Code goes through OpenCode; see
[utils/t3-code/README.md](../t3-code/README.md).

## skills

shared skills live in `utils/agents/skills/`. `deploy.sh` merges them
into `~/.agents/skills` as per-skill symlinks.

machine-only skills (company-specific, throwaways) go in
`~/.agents/skills-local/`. re-run `deploy.sh` after adding one so it is
linked into the merge dir. a local skill with the same name as a shared
skill wins on that machine. deploy also drops names from the merge dir
that no longer exist in shared or local.

`scripts/doctor.sh` checks these links.

### i-have-adhd

[`i-have-adhd`](skills/i-have-adhd/SKILL.md) is vendored from
[ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd/tree/24d22f783e57cb73c957848b588c6f651b6f9cd8/skills/i-have-adhd)
at commit `24d22f783e57cb73c957848b588c6f651b6f9cd8`, with its MIT license.
Local changes make it the default in every session: the description
requires automatic use, the manual-only frontmatter flag is removed,
and Codex's `allow_implicit_invocation` policy is enabled.
An added precedence rule gives `i-have-adhd` priority for response
structure and `unslop` priority for wording when both apply.

Say `stop adhd mode` or `normal mode` to disable it for the current
session. New sessions start with it enabled again. The bundled Gemini
command is an upstream reference; Gemini is not configured by this repo.

## who loads what

| tool | user-scope skills |
| --- | --- |
| Codex, Cursor, and their T3 threads | `~/.agents/skills` |
| Claude Code, and T3 Claude threads | `~/.claude/skills` |
| OpenCode, and T3 OpenCode threads | `~/.agents/skills`, `~/.claude/skills`, and `~/.config/opencode/skills` |
| GitHub Copilot | `~/.agents/skills` and `~/.copilot/skills` |
| Cursor Agent Skills under `~/.cursor/skills-cursor/` | Cursor only. T3 Claude threads never see them |

OpenCode's provider config is separate, but its
[skill discovery](https://opencode.ai/docs/skills/) includes the shared
directories. [Cursor](https://cursor.com/docs/skills) and
[Copilot](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)
also discover `~/.agents/skills` directly.

`~/.claude/skills` layout is platform-dependent (same logic in
`deploy.sh` and `doctor.sh`):

- **omarchy:** a real directory. omarchy owns package skills
  (`omarchy`, `omacal`, `diagnose-crash`, ...). deploy adds our skills
  per-skill alongside those and never clobbers a package-managed name.
- **mac / plain linux:** a symlink to `~/.agents/skills`.

project skills in an opened repo's `.claude/skills/` still load in
Claude Code / T3 regardless of the user-scope layout.

## t3 code + openrouter

configure OpenRouter in OpenCode (`/connect`), then use **OpenCode
threads** in T3. do not add a custom Claude provider or an isolated
`CLAUDE_CONFIG_DIR` for this. full steps:
[utils/t3-code/README.md](../t3-code/README.md).

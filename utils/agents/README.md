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

## who loads what

| tool | user-scope skills |
| --- | --- |
| Cursor | `~/.agents/skills` |
| Claude Code, and T3 Claude threads | `~/.claude/skills` |
| OpenCode, and T3 OpenCode threads | OpenCode's own config (not `~/.claude/skills`) |
| Cursor Agent Skills under `~/.cursor/skills-cursor/` | Cursor only. T3 Claude threads never see them |

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

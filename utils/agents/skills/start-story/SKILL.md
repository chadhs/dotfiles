---
name: start-story
description: Formal git story workflow with a worktree, ticket-prefixed branch, and draft PR. Use when the user asks to start a story, start a ticket, or create a worktree; when a JIRA or Linear ticket id is given; or when the workspace is already under a worktrees/ directory. Do not use for casual commits, personal work, or a normal checkout of main or master.
---

# Start story

Formal consulting workflow. If this skill does not apply, stay on the current branch (including main). No worktree. No ticket prompt.

When creating a PR or MR, follow the git-host-auth skill.

## Label

1. Ticket or label is the branch-name prefix and the PR/MR title prefix.
2. If cwd is `.../worktrees/<label>/<repo>`, use `<label>` from the path. Do not ask for a new ticket.
3. If the user invoked this skill and there is still no label, ask once. Never ask just because git is involved.

## Worktree

Create a worktree under the owner dir, not inside the main checkout.

Example: repo `~/src/chadhs/dotfiles` → `~/src/chadhs/worktrees/ABC-1234/dotfiles`.

Pattern: `~/src/<owner>/<repo>` → `~/src/<owner>/worktrees/<label>/<repo>`.

## Commits and PRs

1. Ask before staging, committing, or opening a PR/MR unless the user already asked for that.
2. PRs/MRs default to draft.
3. Write the PR/MR body with the unslop skill, then create it with git-host-auth (correct CLI and direnv).
4. git-host-auth opens the PR/MR in the default browser after create.

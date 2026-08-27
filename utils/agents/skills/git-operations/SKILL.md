---
name: git operations
description: Sets rules to follow when creating branches, PRs, and during other git operations within any repo.
---

# Git Operations

Set rules to follow when creating branches, PRs, and other git operations within any repo.

## Process

1. If a ticket (from JIRA, Linear, etc) was mentioned, such as ABC-1234, use that as the prefix for the branch name and the prefix for the PR description.
2. If a ticket label was not mentioned during the initial prompts please prompt the user for a ticket reference or other label before writing any code.
3. When creating a branch use a git worktree on level up from the repo based on the ticket or label name. For example in the repo ~/src/chadhs/dotfiles, create a worktree at the location ~/src/chadhs/worktrees/ABC-1234/dotfiles
4. Ask for permission before staging, committing, and opening the PR unless explicitly asked to do so.
5. PRs should default to being a Draft.
6. When writing PR descriptions be sure to use the unslop skill when writing them.
7. Always open the PRs in the default browser once they are created.

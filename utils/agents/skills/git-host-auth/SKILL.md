---
name: git-host-auth
description: Selects gh vs glab and loads the correct GitHub token via direnv for the current repo path. Use when running gh or glab, opening a pull request or merge request, or when git host authentication fails. Do not use for local commits, branching, or work that never talks to GitHub or GitLab.
---

# Git host auth

Pick the host CLI from `origin` and load the path-specific token. Never prompt about tickets, worktrees, or whether to use main.

## Host CLI

1. Run `git remote get-url origin`.
2. GitLab host (gitlab.com or a `gitlab.` host) → `glab`.
3. GitHub host (github.com or a `github.` host) → `gh`.

## GitHub (`gh`)

Do not trust a global `gh auth` session. The token depends on the repo path.

1. Repo root: `git rev-parse --show-toplevel`.
2. Run `gh` through that path's direnv so `.envrc` wins, e.g. `direnv exec <repo-root> gh ...`.
3. Recheck `direnv exec <repo-root> gh auth status` after that env is loaded. Do not use a `gh` that was authenticated before direnv ran.

## GitLab (`glab`)

Use `glab` against that remote. Skip direnv unless the repo's `.envrc` exports GitLab credentials.

## After create

Open the new PR or MR in the default browser (`gh pr view --web` or `glab mr view --web`, still via direnv for `gh`).

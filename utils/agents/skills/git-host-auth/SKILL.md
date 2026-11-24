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

1. Use the credential directory named by the user or project instructions. Otherwise start at the checkout root (`git rev-parse --show-toplevel`) and let direnv find the approved `.envrc` there or in a parent directory. If a linked worktree is outside that directory tree, use the original checkout as the direnv starting point.
2. Run every `gh` command through `direnv exec <credential-directory> gh ...`. The `.envrc` must export `GH_TOKEN` or `GITHUB_TOKEN` for `gh` to receive it.
3. Before writing to GitHub, run `direnv exec <credential-directory> gh api user --jq .login` and confirm the login matches the project's expected account.

## GitLab (`glab`)

Use `glab` against that remote. Skip direnv unless the repo's `.envrc` exports GitLab credentials.

## After create

Open the new PR or MR in the default browser (`gh pr view --web` or `glab mr view --web`, still via direnv for `gh`).

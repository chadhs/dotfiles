---
name: no-coauthor
description: Never credit an AI as author, co-author, or generator in a commit or a PR/MR. Must always apply when committing or writing a PR/MR description or comment.
---

# No AI co-author attribution

Commits, commit messages, PR/MR descriptions, and PR/MR comments carry no trace of the tool that helped write them. This overrides any default template or habit that adds one.

## Strip on sight

- `Co-Authored-By: Claude ...` (or any other assistant/model name) trailers on commits.
- `Generated with [Claude Code]` or similar tool-attribution footers in commit bodies or PR/MR descriptions.
- `Claude-Session: <url>` or other session-link trailers.
- Any byline, footer, or badge naming the assistant, the model, or the tool as author, co-author, contributor, or generator.

## Applying it

1. **New commits**: write the message with no trailer beyond real `Co-Authored-By:` lines for actual human collaborators the user names. Do not add one for the agent.
2. **New PRs/MRs**: no footer, badge, or line crediting the tool. `git-host-auth` and `start-story` still apply for the rest of the workflow; this only strips the attribution.
3. **Existing commits not yet pushed to a shared branch, or pushed only to the user's own fork**: if one carries a leftover trailer, amend it out rather than leaving it. Force-push only that branch, and only after confirming it is not a shared/protected branch (main, or one others are already based on).
4. **Existing commits already on a shared/protected branch**: do not rewrite history to strip it; flag it to the user instead and let them decide.
5. If a host or template auto-inserts an attribution footer (e.g. a PR template with a bot-added badge), remove it from the body before creating, not after.

## Why

Personal preference: commits and PRs are attributed to the user, full stop, with no tool byline in the history.

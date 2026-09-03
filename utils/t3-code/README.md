# t3 code

[T3 Code](https://github.com/pingdotgg/t3code) drives local agent CLIs
(Claude Code, Codex, Cursor, Grok Build, OpenCode). it does not take an
OpenRouter key as a global BYOK setting the way T3 Chat does.

**preferred OpenRouter path: configure it in OpenCode, then use OpenCode
threads in T3.** OpenCode is a multi-provider harness, so Claude, OpenAI,
and GLM (and the rest of the OpenRouter catalog) are just models in the
picker. do not add a custom Claude provider for this.

upstream: [OpenRouter + OpenCode](https://openrouter.ai/docs/cookbook/coding-agents/opencode-integration).

on omarchy, `t3code-nightly-bin` is in [`omarchy/aur.packages`](../../omarchy/aur.packages)
and `deploy.sh` installs it. themes live in this folder. the OpenRouter
key stays in OpenCode's auth store (and optionally T3 env vars), never in
this repo or `links.conf`.

## openrouter via opencode

### 1. connect in opencode (not in t3)

```text
opencode
/connect          → OpenRouter → paste the sk-or- key
/models           → pick an openrouter/... model and send a test prompt
```

`/connect` writes `~/.local/share/opencode/auth.json`. confirm it with
`opencode auth list`. do not put the key in git.

many OpenRouter models are preloaded. extra slugs go in
`~/.config/opencode/opencode.json` (user-wide) or `opencode.json` in a
project:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "openrouter": {
      "models": {
        "~anthropic/claude-sonnet-latest": {},
        "openai/gpt-5.2": {},
        "z-ai/glm-5": {}
      }
    }
  }
}
```

copy slugs from [openrouter.ai/models](https://openrouter.ai/models).
OpenCode ids are `openrouter/<slug>`. a leading `~` is an OpenRouter
"latest" alias.

### 2. use it from t3

enable the OpenCode provider in T3 Settings. start a **new OpenCode
thread** and pick `openrouter/...` in the model picker.

do not reuse a Claude thread. T3 treats OpenCode and Claude as different
drivers.

confirm traffic on the
[OpenRouter activity dashboard](https://openrouter.ai/activity).

### if the picker is empty or calls 401

T3 spawns `opencode serve`. if you have not set it yourself, it still
injects `OPENCODE_CONFIG_CONTENT={}`, which can hide `opencode.json`
extras even when the OpenCode TUI is fine
([#4239](https://github.com/pingdotgg/t3code/issues/4239)). some setups
also show models but fail with `No api key passed in`.

on the T3 OpenCode provider's Environment variables:

- `OPENROUTER_API_KEY` = the same key (mark **Sensitive**)
- if extra models from `opencode.json` are missing, set
  `OPENCODE_CONFIG_CONTENT` to that JSON (one line is fine). T3 keeps a
  non-empty inherited value; `{}` is only the fallback

or run `opencode serve` yourself and point T3's OpenCode **server URL**
at that process so T3 is not the thing spawning with an empty config.

### why not a custom claude provider

Claude Code only speaks Anthropic's API. pointing it at OpenRouter with
`ANTHROPIC_BASE_URL` works for Claude models and fights you for
everything else (isolated `CLAUDE_CONFIG_DIR`, role env vars, one custom
picker slot, tools breaking on GPT/GLM). OpenCode does not have that
shape. if a Claude OpenRouter instance is already in T3 Settings, delete
it and use OpenCode instead.

## what this does not cover

- **T3 Chat BYOK** is a different product. a key there does not configure
  T3 Code.
- **Codex / Cursor / Grok** have no OpenRouter recipe here. use those
  CLIs' own logins, or go through OpenCode as above.

## themes

import from Settings → Themes → Add theme:

- [solarized](themes/solarized/README.md) (`themes/solarized/solarized-theme.json`)
- [selenized](themes/selenized/README.md) (`themes/selenized/selenized-theme.json`)

re-import the same file after you change it; T3 treats a matching `id`
as an update.

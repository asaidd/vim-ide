# vim-ide

A minimal Neovim-based IDE for Python work with opencode agents. Built for
people who prefer vim but are not power users: the config is small, every
feature has a cheatsheet entry, and the agent handles the heavy thinking.

## What you get

| Goal | Keys |
|---|---|
| Ask an agent what this code does | `Space o e` (`:ExplainCode`) |
| Jump to a `file:line` ref in a scratch buffer | `gF` |
| Review a branch diff top-down | `Space o d` (`:DiffReview`) |
| Compare two PRs / refs | `Space o p` (`:PRCompare`) |
| Chat with the agent while editing | `Space o` (`:OpenCode`) |
| Fuzzy file search / grep | `Space f f` / `Space f g` |
| Run tests / `make check` | `Space t` / `Space c` |
| Quick local diff views | `Space d s` (stat), `Space d f` (current file) |

All reviews and comparisons use a **top-down approach**: the agent first
establishes intent and scope (git log, diff --stat, linked issues), then
per-file impact, and only then dives into risky hunks — ending with a verdict.

## Install

```bash
bash install.sh        # installs Neovim if missing, symlinks ~/.config/nvim
nvim                   # first start installs lazy.nvim + plugins
```

Requires: Neovim 0.10+, `opencode` on PATH (logged in), `git`, `rg`
(`install.sh` fetches ripgrep and Neovim automatically when missing). For
Python projects: `uv` (the config runs `uv run pytest` / `make check` and
prefers `uv run pyright-langserver` when the project venv has pyright).

Extras included: catppuccin colorscheme, lualine statusline, fzf-lua.

## Layout

```
config/init.lua        entry point; options, lazy.nvim, pyright, treesitter
config/lua/ide/keys.lua    all leader bindings in one place
config/lua/ide/agent.lua   opencode integration (TUI split + scratch-buffer runs)
config/lua/ide/diff-review.lua  quick local diff views
config/lua/ide/util.lua     shared helpers
prompts/               top-down agent prompt templates (explain / diff-review / pr-compare)
cheatsheet.md          the guide you actually keep open
install.sh             bootstrap + symlink
```

## Usage loop

Read the [cheatsheet](cheatsheet.md) first — it is written for beginners.

1. **Read**: `Space f f` to find files, `gd` to definitions, `K` for docs,
   `Space d f` for what changed recently.
2. **Ask**: `Space o e` explains the current file into a scratch buffer;
   `gF` jumps from any `file:line` reference to the code; follow up in the
   opencode TUI with `Space o`.
3. **Review**: `Space o d` on your branch, `Space o p` to compare PRs.

Agent results stream into scratch buffers (`explain`, `diff-review`,
`pr-compare`) so you can read the answer without losing your place.

## Design notes

- Editor-independent of brr: `:DiffReview`/`:PRCompare` work in any git repo;
  brr's own `tools/review` tooling remains usable on top.
- Non-interactive agent calls reuse the `opencode run --format json` event
  stream pattern (same as `brr/tools/review/explain.py`).
- Config is minimal by design (lspconfig + treesitter + fzf-lua + lualine +
  catppuccin); add plugins as you feel the need, one at a time.

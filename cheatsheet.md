# vim-ide cheatsheet

Keep this open next to your editor. It is written for someone who knows vim
exists but is not fluent yet. Sections:

1. [Minimal vim survival](#1-minimal-vim-survival)
2. [vim-ide bindings](#2-vim-ide-bindings)
3. [Daily loop: read code](#3-daily-loop-read-code)
4. [Daily loop: ask the agent](#4-daily-loop-ask-the-agent)
5. [Daily loop: review & compare PRs](#5-daily-loop-review--compare-prs)

---

## 1. Minimal vim survival

Vim is modal: **normal mode** (navigate), **insert mode** (type), **visual mode**
(select). The editor starts in normal mode.

| Keys | Meaning |
|---|---|
| `h` `j` `k` `l` | move left / down / up / right |
| `w` `e` `b` | jump word forward / end of word / word back |
| `0` / `$` | start / end of line |
| `gg` / `G` | top of file / bottom of file |
| `Ctrl-d` / `Ctrl-u` | half page down / up |
| `i` / `a` | insert before / after cursor |
| `o` / `O` | new line below / above |
| `Esc` | back to normal mode |
| `v` / `V` | visual (char) / visual line |
| `d` / `dd` | delete selection / delete line |
| `y` / `yy` | yank (copy) selection / line |
| `p` / `P` | paste after / before cursor |
| `u` / `Ctrl-r` | undo / redo |
| `x` | delete character under cursor |
| `/word` `n` `N` | search; next / previous match |
| `:w` `:q` `:wq` | save / quit / save and quit |
| `Ctrl-w` + `h/j/k/l` | jump between splits |
| `Ctrl-w` + `s` / `v` | split horizontal / vertical |
| `.` | repeat last change |

**Golden rule:** every command is `verb + motion` (`dw` = delete word,
`ci(` = change inside parens, `ggdG` = delete whole file). Learn five commands
a day, not everything at once.

## 2. vim-ide bindings

Leader key is `Space`. Bindings live in `config/lua/ide/keys.lua`.

### Agent (opencode)

| Keys | Command | What it does |
|---|---|---|
| `Space o` | `:OpenCode` | open the opencode chat TUI in a right-hand split (`Esc` to leave the terminal, `Ctrl-w l` to go into it) |
| `Space o e` | `:ExplainCode` | agent explains the **current file** (and symbol under cursor) into a scratch buffer; press `gF` on any `file:line` ref to jump to the code |
| `Space o d` | `:DiffReview` | agent reviews current branch diff **top-down** (intent → files → risky hunks → verdict) |
| `Space o p` | `:PRCompare` | agent compares two refs/PR numbers **top-down** (overview → behavioral differences → per-file → verdict) |

### Diff views (no agent — instant)

| Keys | Command | What it does |
|---|---|---|
| `Space d s` | `:DiffStat` | change statistics of the branch (first look: what changed at all) |
| `Space d f` | `:DiffReviewCurrent` | full git diff of the **current file** in a terminal split |

### Python toolchain

| Keys | Command | What it does |
|---|---|---|
| `Space t` | `:Term uv run pytest` | run tests |
| `Space c` | `:Term make check` | lint + types + tests in one shot |
| `Space F` | LSP format | format current buffer (pyright) — `f` is reserved for the fzf prefix |
| `gd` / `gD` | LSP | go to definition / references |
| `K` | LSP | hover documentation |
| `Space r` | LSP | rename symbol |

### Files & window management

| Keys | Command | What it does |
|---|---|---|
| `Space f f` | `:FzfLua files` | fuzzy file search |
| `Space f g` | `:FzfLua grep` | fuzzy grep across the repo |
| `Space w` / `Space q` | | save / close window |
| `Space v` / `Space s` | | split vertical / horizontal |
| `Space h` | | clear search highlight |
| `:Term git status` | | any shell command in a split |

### Scratch buffers (agent results)

| Keys | What it does |
|---|---|
| `gF` | jump to the `file:line` reference under the cursor (resolves repo-relative and bare names like `domain.py:34`) |

## 3. Daily loop: read code

1. `Space f f` to fuzzy-find the file you care about.
2. Press `K` on a function to see its signature, `gd` to jump to its
   definition, `Space d f` to see what changed in it recently.
3. Read top-down: file header comment, class docstrings, function signatures,
   then the bodies.
4. When the agent returns references in a scratch buffer, put the cursor on a
   `file:line` and press `gF` to jump straight there.

## 4. Daily loop: ask the agent

1. Open the file you are confused about, put the cursor on a symbol.
2. `Space o e` — the agent explains file purpose, key symbols, data flow, and
   risks into a scratch buffer, with `file:line` references.
3. Click through those references (`:e file` + `<line>G`), then continue the
   conversation in the opencode TUI with `Space o`.

## 5. Daily loop: review & compare PRs

1. On the feature branch: `Space o d`. Enter the base ref (`origin/main`
   suggested). Read the agent's top-down review: intent, per-file, risky hunks,
   verdict.
2. Reviews are **source-first**: the agent deep-dives source changes (hot-path
   components — order/market-data/quoting/OMS-risk — first), and only
   summarizes test and doc changes in a line or two. Edit the templates in
   `~/.config/nvim/prompts/` if you want that balance changed.
3. For a quick orientation first: `Space d s` (stat) and `Space d f` (current
   file diff).
4. To compare two PRs/refs: `Space o p`, give `head` and `base` (numbers or
   refs). The agent reports behavioral differences, not just text changes.
5. Push your review with `gh` (`:Term gh pr review <n>`).

---

### Troubleshooting

| Problem | Fix |
|---|---|
| Agent never responds | `opencode` must be on `PATH`; run `:Term opencode auth list` to check login |
| `Space f g` says rg missing | install ripgrep (install.sh does this) or `sudo apt install ripgrep` |
| LSP errors (pyright) | the config runs `uv run pyright-langserver` when the project has a `.venv` with pyright (brr does via `--group dev`); otherwise it falls back to a global `pyright-langserver` |
| `Space o` opens a shell, not the TUI | check terminal works in nvim: `:Term echo hello` |
| Prompt placeholders missing | templates live in `~/.config/nvim/prompts/`; re-run `install.sh` after editing the repo |
| Agent results are empty | `opencode run` needs a pty; the config already sets one (`pty = true` in `agent.lua`) — don't "optimize" it away |

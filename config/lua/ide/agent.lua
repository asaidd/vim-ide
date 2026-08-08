-- opencode agent integration.
-- :OpenCode     — open the opencode TUI in a vertical :term split
-- :Term <cmd>   — run any command in a terminal split (used by keys.lua)
-- :ExplainCode  — ask the agent "what does this code do" -> scratch buffer
-- :DiffReview   — agent review of the current branch diff (top-down)
-- :PRCompare    — agent compares two refs/PRs (top-down)
--
-- Non-interactive runs use `opencode run --format json --pure`, parse the
-- JSON event stream, and render only the assistant's `text` events into a
-- scratch buffer (same pattern as brr's tools/review/explain.py).

local util = require("ide.util")

local M = {}

local prompts_dir = vim.fn.stdpath("config") .. "/prompts"

local function prompt_file(name)
  return prompts_dir .. "/" .. name
end

local function read_template(name)
  local ok, content = pcall(vim.fn.readfile, prompt_file(name))
  if not ok or #content == 0 then
    vim.notify("vim-ide: missing prompt template " .. name, vim.log.levels.ERROR)
    return nil
  end
  return table.concat(content, "\n")
end

local function substitute(template, vars)
  return (template:gsub("{{(%w+)}}", vars))
end

--- Parse a single JSON event line from `opencode run --format json`.
--- Returns the assistant text for that line, or nil.
local function parse_event(line)
  local ok, event = pcall(vim.json.decode, line)
  if not ok or type(event) ~= "table" or event.type ~= "text" then
    return nil
  end
  local text = (event.part or {}).text or ""
  if text == "" then return nil end
  return text
end

--- Run opencode non-interactively, streaming assistant text into a buffer.
--- opts: { buf = handle, args = {...}, dir = cwd }
function M.run_agent(opts)
  if vim.fn.executable("opencode") == 0 then
    vim.notify("vim-ide: `opencode` not found on PATH", vim.log.levels.ERROR)
    return
  end
  local args = { "opencode", "run", "--format", "json", "--pure" }
  for _, a in ipairs(opts.args or {}) do
    args[#args + 1] = a
  end
  local buf = opts.buf or util.open_scratch("agent", "markdown")
  local err_lines = {}
  local pending = ""
  local job = vim.fn.jobstart(args, {
    cwd = opts.dir,
    -- opencode `run` self-terminates when stdin is not a tty; give it a pty.
    pty = true,
    on_stdout = function(_, data)
      for i = 1, #data - 1 do
        local line = pending .. data[i]
        pending = ""
        line = line:gsub("\r", "")
        local text = parse_event(line)
        if text then
          vim.schedule(function()
            util.append(buf, vim.split(text, "\n"))
          end)
        end
      end
      pending = pending .. data[#data]
    end,
    on_stderr = function(_, data)
      for _, l in ipairs(data) do
        if l ~= "" then err_lines[#err_lines + 1] = l end
      end
    end,
    on_exit = function(_, code)
      if code ~= 0 then
        vim.schedule(function()
          vim.notify(
            "opencode exited " .. code .. "\n" .. table.concat(err_lines, "\n"),
            vim.log.levels.ERROR
          )
        end)
      end
    end,
  })
  if job == 0 then
    vim.notify("vim-ide: failed to start opencode", vim.log.levels.ERROR)
    return
  end
  vim.notify("agent working…", vim.log.levels.INFO)
end

--- :OpenCode — open the TUI in a vertical terminal split.
function M.tui()
  local root = util.repo_root()
  if not root then return end
  vim.cmd("vsplit")
  vim.fn.termopen("opencode", { cwd = root })
  vim.cmd("startinsert")
end

--- :Term <cmd> — run a shell command in a horizontal terminal split.
function M.term(cmd)
  if cmd == nil or cmd == "" then
    cmd = vim.fn.input("command: ", "")
  end
  if cmd == "" then return end
  vim.cmd("split")
  local root = util.repo_root() or vim.fn.getcwd()
  vim.fn.termopen(cmd, { cwd = root })
  vim.cmd("startinsert")
end

--- :ExplainCode — agent explains the current file (and symbol under cursor).
function M.explain()
  local root = util.repo_root()
  if not root then return end
  vim.cmd("silent! write")
  local path = vim.fn.expand("%:p")
  local rel = vim.fn.fnamemodify(path, ":.")
  local symbol = vim.fn.expand("<cword>")
  local template = read_template("explain.md")
  if not template then return end
  local prompt = substitute(template, {
    file = rel,
    symbol = symbol,
  })
  local buf = util.open_scratch("explain", "markdown")
  util.append(buf, { "## Explaining " .. rel, "", "symbol under cursor: " .. symbol, "" })
  -- `--file` is variadic and swallows following args, so the prompt goes first.
  M.run_agent({ buf = buf, dir = root, args = { prompt, "--file", path } })
end

--- :DiffReview — agent reviews the current branch diff vs a base ref (top-down).
function M.diff_review()
  local root = util.repo_root()
  if not root then return end
  local base = vim.fn.input("base ref: ", util.default_base(root))
  if base == "" then return end
  local template = read_template("diff-review.md")
  if not template then return end
  local prompt = substitute(template, { base = base })
  local buf = util.open_scratch("diff-review", "markdown")
  util.append(buf, { "## Diff review  (" .. base .. "...HEAD)", "" })
  M.run_agent({ buf = buf, dir = root, args = { prompt } })
end

--- :PRCompare — agent compares two refs / PR numbers side by side (top-down).
function M.pr_compare()
  local root = util.repo_root()
  if not root then return end
  local head = vim.fn.input("PR or ref (head): ", "")
  if head == "" then return end
  local base = vim.fn.input("PR or ref (base) [main]: ", "main")
  if base == "" then base = "main" end
  local template = read_template("pr-compare.md")
  if not template then return end
  local prompt = substitute(template, { base = base, head = head })
  local buf = util.open_scratch("pr-compare", "markdown")
  util.append(buf, { "## PR compare  " .. head .. "  →  " .. base, "" })
  M.run_agent({ buf = buf, dir = root, args = { prompt } })
end

vim.api.nvim_create_user_command("OpenCode", function() M.tui() end, {})
vim.api.nvim_create_user_command("Term", function(a) M.term(table.concat(a.fargs, " ")) end, { nargs = "*" })
vim.api.nvim_create_user_command("ExplainCode", function() M.explain() end, {})
vim.api.nvim_create_user_command("DiffReview", function() M.diff_review() end, {})
vim.api.nvim_create_user_command("PRCompare", function() M.pr_compare() end, {})

return M

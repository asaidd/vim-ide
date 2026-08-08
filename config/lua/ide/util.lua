-- Shared helpers for vim-ide modules.

local M = {}

--- Absolute path of the enclosing git work tree, or nil (with a notify).
function M.repo_root()
  local p = vim.fn.systemlist("git rev-parse --show-toplevel 2>/dev/null")
  if vim.v.shell_error ~= 0 then
    vim.notify("vim-ide: not a git repo", vim.log.levels.ERROR)
    return nil
  end
  return p[1]
end

--- Sensible base ref for diffing: origin/main when present, else HEAD~1.
function M.default_base(root)
  if vim.fn.system("git -C " .. vim.fn.shellescape(root) .. " rev-parse --verify --quiet origin/main") ~= "" then
    return "origin/main"
  end
  return "HEAD~1"
end

--- Local and remote branch names for ref completion.
function M.git_branches(root)
  if not root then return {} end
  local out = vim.fn.system(
    "git -C " .. vim.fn.shellescape(root) .. " branch -a --no-color --format '%(refname:short)'"
  )
  if vim.v.shell_error ~= 0 then return {} end
  local branches = {}
  for line in out:gmatch("[^\n]+") do
    line = line:gsub("^%s+", "")
    if line ~= "" then
      branches[#branches + 1] = line
    end
  end
  table.sort(branches)
  return branches
end

--- Current branch name, or nil outside a repo.
function M.current_branch(root)
  if not root then return nil end
  local out = vim.fn.system(
    "git -C " .. vim.fn.shellescape(root) .. " rev-parse --abbrev-ref HEAD"
  )
  if vim.v.shell_error ~= 0 then return nil end
  return out:gsub("^%s+", ""):gsub("%s+$", "")
end

--- Async prompt for a git ref with Tab completion over branches.
--- Calls `on_ok(ref)` with the chosen value; does nothing on cancel.
function M.prompt_ref(prompt, default, root, on_ok)
  local branches = M.git_branches(root)
  local branch = M.current_branch(root)
  local label = prompt
  if branch then
    label = prompt:gsub("%s*$", "") .. " (on " .. branch .. "): "
  end
  vim.ui.input({
    prompt = label,
    default = default,
    completion = function(arg)
      arg = arg:lower()
      local matches = {}
      for _, b in ipairs(branches) do
        if b:lower():find(arg, 1, true) then
          matches[#matches + 1] = b
        end
      end
      return matches
    end,
  }, function(value)
    if value and value ~= "" then
      on_ok(value)
    end
  end)
end

--- Create a scratch buffer, make it current, return the handle.
function M.open_scratch(name, filetype)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("filetype", filetype, { buf = buf })
  vim.api.nvim_buf_set_name(buf, name)
  vim.api.nvim_set_current_buf(buf)
  vim.keymap.set("n", "gF", M.jump_ref, { buffer = buf, desc = "jump to file:line ref" })
  return buf
end

--- Jump to a `file:line` reference under the cursor. Scratch buffers may
--- reference repo-relative paths or bare file names ("domain.py:34").
function M.jump_ref()
  local word = vim.fn.expand("<cWORD>"):gsub("[%.,;)]+$", "")
  local file, line = word:match("^([^:]+):(%d+)")
  if not file then
    vim.cmd("edit " .. vim.fn.fnameescape(word))
    return
  end
  local root = M.repo_root()
  local target
  local candidates = { file }
  if root then
    candidates[#candidates + 1] = root .. "/" .. file
  end
  for _, c in ipairs(candidates) do
    if vim.fn.filereadable(c) == 1 then
      target = c
      break
    end
  end
  if not target and root then
    -- bare name: resolve within the repo (fastest match wins)
    local hits
    if vim.fn.executable("rg") == 1 then
      hits = vim.fn.systemlist(
        "rg --files -g " .. vim.fn.shellescape(file, 1) .. " " .. vim.fn.shellescape(root)
      )
    else
      hits = vim.fn.systemlist(
        "find " .. vim.fn.shellescape(root) .. " -type f -name "
          .. vim.fn.shellescape(file, 1) .. " -not -path '*/.git/*' 2>/dev/null"
      )
    end
    for _, h in ipairs(hits or {}) do
      if vim.fn.filereadable(h) == 1 then
        target = h
        break
      end
    end
  end
  if not target then
    vim.notify("vim-ide: cannot find " .. file, vim.log.levels.WARN)
    return
  end
  vim.cmd("edit " .. vim.fn.fnameescape(target))
  local ok = pcall(vim.api.nvim_win_set_cursor, 0, { tonumber(line), 0 })
  if not ok then
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
  end
end

--- Append lines to a buffer (replacing the single initial empty line).
function M.append(buf, lines)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  local current = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if #current == 1 and current[1] == "" then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  else
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
  end
end

return M

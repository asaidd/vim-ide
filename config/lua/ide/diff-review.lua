-- Quick local diff views (no agent): the deterministic half of a review.
-- The agent-driven :DiffReview/:PRCompare live in ide.agent with top-down
-- prompt templates; this module gives instant diff access for the current
-- file and a change-stat overview so you can orient before asking the agent.
--
-- :DiffReviewCurrent — git diff of the current file vs the base ref (term split)
-- :DiffStat          — `git diff --stat <base>...HEAD` in a scratch buffer

local util = require("ide.util")

local M = {}

--- :DiffReviewCurrent — diff of the current file in a terminal split.
function M.diff_current()
  local root = util.repo_root()
  if not root then return end
  local file = vim.fn.expand("%:p")
  util.prompt_ref("base ref", util.default_base(root), root, function(base)
    vim.cmd("vsplit | enew")
    vim.fn.termopen(
      "git diff " .. vim.fn.shellescape(base) .. " -- " .. vim.fn.fnameescape(file),
      { cwd = root }
    )
    vim.cmd("startinsert")
  end)
end

--- :DiffStat — change statistics for the branch in a scratch buffer.
function M.diff_stat()
  local root = util.repo_root()
  if not root then return end
  util.prompt_ref("base ref", util.default_base(root), root, function(base)
    local out = vim.fn.system(
      "git -C "
        .. vim.fn.shellescape(root)
        .. " diff --stat "
        .. vim.fn.shellescape(base)
    )
    if vim.v.shell_error ~= 0 then
      vim.notify("vim-ide: git diff --stat failed", vim.log.levels.ERROR)
      return
    end
    local buf = util.open_scratch("diff-stat", "text")
    util.append(buf, vim.split(out, "\n"))
  end)
end

--- :DiffBrowse — route page of every changed file in the branch.
--- Enter on a file opens its diff in a terminal split below the list.
function M.browse()
  local root = util.repo_root()
  if not root then return end
  util.prompt_ref("base ref", util.default_base(root), root, function(base)
    local out = vim.fn.system(
      "git -C "
        .. vim.fn.shellescape(root)
        .. " diff --numstat "
        .. vim.fn.shellescape(base)
    )
    if vim.v.shell_error ~= 0 then
      vim.notify("vim-ide: git diff --numstat failed", vim.log.levels.ERROR)
      return
    end
    local files = {}
    for _, line in ipairs(vim.split(out, "\n")) do
      local added, deleted, file = line:match("^(%S+)%s+(%S+)%s+(.+)$")
      if file then
        files[#files + 1] = { added = added, deleted = deleted, file = file }
      end
    end
    local buf = util.open_scratch("diff-browse", "text")
    util.append(buf, { "Changed files vs " .. base .. "  (Enter = diff, q = close)", "" })
    for _, f in ipairs(files) do
      util.append(buf, { string.format("+%s -%s  %s", f.added, f.deleted, f.file) })
    end
    if #files == 0 then
      util.append(buf, {
        "no changes found vs " .. base .. " (committed or uncommitted)",
        "hint: the route page compares against the working tree,",
        "      so new edits show up even before you commit.",
      })
    end
    vim.keymap.set("n", "<CR>", function()
      M.diff_file(root, base, vim.api.nvim_get_current_line())
    end, { buffer = buf })
  end)
end

--- Open the diff of a single file from a route-page line ("+1 -0  path").
function M.diff_file(root, base, line)
  local file = line:match("^%+%S+ %-%S+  (.+)$")
  if not file then
    return
  end
  vim.cmd("split | enew")
  vim.fn.termopen(
    "git -C "
      .. vim.fn.shellescape(root)
      .. " diff "
      .. vim.fn.shellescape(base)
      .. " -- "
      .. vim.fn.shellescape(file),
    { cwd = root }
  )
  vim.cmd("startinsert")
end

vim.api.nvim_create_user_command("DiffReviewCurrent", function() M.diff_current() end, {})
vim.api.nvim_create_user_command("DiffStat", function() M.diff_stat() end, {})
vim.api.nvim_create_user_command("DiffBrowse", function() M.browse() end, {})

return M

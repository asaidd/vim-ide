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
      "git -C " .. vim.fn.shellescape(root) .. " diff --stat " .. vim.fn.shellescape(base) .. "...HEAD"
    )
    if vim.v.shell_error ~= 0 then
      vim.notify("vim-ide: git diff --stat failed", vim.log.levels.ERROR)
      return
    end
    local buf = util.open_scratch("diff-stat", "text")
    util.append(buf, vim.split(out, "\n"))
  end)
end

vim.api.nvim_create_user_command("DiffReviewCurrent", function() M.diff_current() end, {})
vim.api.nvim_create_user_command("DiffStat", function() M.diff_stat() end, {})

return M

local M = {}

M.keys = {
  -- files & search
  ["<leader>w"] = { "<cmd>w<CR>", "write file" },
  ["<leader>q"] = { "<cmd>q<CR>", "quit window" },
  ["<leader>h"] = { "<cmd>nohlsearch<CR>", "clear search highlight" },
  ["<leader>v"] = { "<cmd>vsplit<CR>", "vertical split" },
  ["<leader>s"] = { "<cmd>split<CR>", "horizontal split" },
  ["<leader>ff"] = { "<cmd>FzfLua files<CR>", "fuzzy file search" },
  ["<leader>fg"] = { "<cmd>FzfLua grep<CR>", "fuzzy grep in repo" },

  -- python toolchain
  ["<leader>t"] = { "<cmd>Term uv run pytest<CR>", "run tests" },
  ["<leader>c"] = { "<cmd>Term make check<CR>", "make check (lint+types+tests)" },

  -- opencode agent
  ["<leader>o"] = { "<cmd>OpenCode<CR>", "opencode TUI in split" },
  ["<leader>oe"] = { "<cmd>ExplainCode<CR>", "ask agent: what does this code do" },
  ["<leader>od"] = { "<cmd>DiffReview<CR>", "agent diff review (top-down)" },
  ["<leader>op"] = { "<cmd>PRCompare<CR>", "agent compares two PRs / refs" },

  -- quick diff views (no agent)
  ["<leader>df"] = { "<cmd>DiffReviewCurrent<CR>", "diff of current file" },
  ["<leader>ds"] = { "<cmd>DiffStat<CR>", "diff --stat of the branch" },
}

function M.setup()
  for lhs, rhs in pairs(M.keys) do
    vim.keymap.set("n", lhs, rhs[1], { desc = rhs[2] })
  end

  -- LSP navigation
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "go to definition" })
  vim.keymap.set("n", "gD", vim.lsp.buf.references, { desc = "go to references" })
  vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "hover docs" })
  vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, { desc = "rename symbol" })

  -- terminal buffers
  vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "leave terminal: left" })
  vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "leave terminal: down" })
  vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "leave terminal: up" })
  vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "leave terminal: right" })
  vim.keymap.set("t", "<C-q>", "<C-\\><C-n><C-w>q", { desc = "close terminal" })
end

return M

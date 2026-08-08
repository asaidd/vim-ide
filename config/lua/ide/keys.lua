local M = {}

-- Sidebar: the file tree and the function outline share one slot (like
-- VS Code's explorer/outline tabs). Opening one closes the other.
local function toggle_tree()
  local ok, aerial = pcall(require, "aerial")
  if ok and aerial.is_open() then
    aerial.close()
  end
  vim.cmd("NvimTreeToggle")
end

local function toggle_outline()
  local ok, view = pcall(require, "nvim-tree.view")
  if ok and view.is_visible() then
    vim.cmd("NvimTreeClose")
  end
  local ok2, aerial = pcall(require, "aerial")
  if ok2 then
    aerial.toggle()
  end
end

M.keys = {
  -- files & search
  ["<leader>w"] = { "<cmd>w<CR>", "write file" },
  ["<leader>q"] = { "<cmd>q<CR>", "quit window" },
  ["<leader>h"] = { "<cmd>nohlsearch<CR>", "clear search highlight" },
  ["<leader>v"] = { "<cmd>vsplit<CR>", "vertical split" },
  ["<leader>s"] = { "<cmd>split<CR>", "horizontal split" },
  ["<leader>ff"] = { "<cmd>FzfLua files<CR>", "fuzzy file search" },
  ["<leader>fg"] = { "<cmd>FzfLua grep<CR>", "fuzzy grep in repo" },
  ["<leader>fw"] = { "<cmd>FzfLua grep_cword<CR>", "grep word under cursor" },
  ["<leader>fs"] = { "<cmd>FzfLua lsp_document_symbols<CR>", "symbols in this file" },

  -- sidebar
  ["<leader>e"] = { toggle_tree, "file tree (explorer)" },
  ["<leader>a"] = { toggle_outline, "functions outline (symbols)" },

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
  -- VS Code style ctrl+click = go to definition
  vim.keymap.set("n", "<C-LeftMouse>", vim.lsp.buf.definition, { desc = "ctrl+click: go to definition" })
  vim.keymap.set("v", "<C-LeftMouse>", vim.lsp.buf.definition, { desc = "ctrl+click: go to definition" })

  -- visual selection -> grep the selection (VS Code "select then search")
  vim.keymap.set("v", "<leader>fg", "<cmd>FzfLua grep_visual<CR>", { desc = "grep visual selection" })

  -- jumplist: back / forward while tracing code (VS Code alt+left/right)
  vim.keymap.set("n", "<A-Left>", "<C-o>", { desc = "jump back (previous position)" })
  vim.keymap.set("n", "<A-Right>", "<C-i>", { desc = "jump forward" })
  vim.keymap.set("i", "<A-Left>", "<C-o><C-o>", { desc = "jump back (insert mode)" })
  vim.keymap.set("i", "<A-Right>", "<C-o><C-i>", { desc = "jump forward (insert mode)" })

  -- window navigation: same Ctrl+h/j/k/l in normal and terminal mode
  vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "window left" })
  vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "window down" })
  vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "window up" })
  vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "window right" })

  -- terminal buffers
  vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "leave terminal: left" })
  vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "leave terminal: down" })
  vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "leave terminal: up" })
  vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "leave terminal: right" })
  vim.keymap.set("t", "<C-q>", "<C-\\><C-n><C-w>q", { desc = "close terminal" })
end

return M

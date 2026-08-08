-- vim-ide: minimal Neovim setup for Python + opencode agents.
-- Layout: init.lua loads ide.* modules; everything lives in lua/ide/.

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.wrap = false
vim.opt.scrolloff = 5
vim.opt.termguicolors = true
vim.opt.clipboard = "unnamedplus"
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.completeopt = "menu,menuone,noselect"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      -- lualine must be a table, not `true`: the theme loader indexes it.
      require("catppuccin").setup({
        integrations = { lualine = {} },
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },
  {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    config = function()
      require("fzf-lua").setup({})
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = { theme = "catppuccin-mocha" },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    event = "BufReadPre",
    config = function()
      vim.diagnostic.config({ virtual_text = false, update_in_insert = false })
      -- Prefer the project's pyright via uv (brr style), fall back to global.
      local function pyright_cmd()
        if vim.fn.executable("uv") == 1 and vim.fn.filereadable(".venv/bin/pyright-langserver") == 1 then
          return { "uv", "run", "pyright-langserver", "--stdio" }
        end
        return { "pyright-langserver", "--stdio" }
      end
      vim.lsp.config("pyright", { cmd = pyright_cmd() })
      vim.lsp.enable("pyright")
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.server_capabilities.documentFormattingProvider then
            -- `<leader>F` not `<leader>f`: `f` is reserved for the fzf prefix (`ff`/`fg`).
            vim.keymap.set("n", "<leader>F", vim.lsp.buf.format, { buffer = args.buf })
          end
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({
        ensure_installed = { "python", "lua", "toml" },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
})

require("ide.keys").setup()
require("ide.agent")
require("ide.diff-review")

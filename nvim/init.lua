-- ==========================================================================
--  ANZATZ LAB: SCIENTIFIC NEOVIM 0.11.x CONFIGURATION
--  Robust, Minimal, Isolated.
-- ==========================================================================

-- 1. PREAMBLE & BOOTSTRAP
--------------------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- Install lazy.nvim if not present
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

-- 2. PLUGIN SPECIFICATION
--------------------------------------------------------------------------
require("lazy").setup({
	-- CORE UI
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("catppuccin-mocha")
		end,
	},
	{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

	-- COMPLETION & SNIPPETS (Blink.cmp - 2025 Standard)
	-- High performance, handles LSP + Snippets natively
	{
		"saghen/blink.cmp",
		version = "*",
		dependencies = { "rafamadriz/friendly-snippets" }, -- Standard scientific snippets
		opts = {
			keymap = { preset = "default" }, -- Enter selects, Tab cycles
			appearance = { use_nvim_cmp_as_default = true, nerd_font_variant = "mono" },
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
			signature = { enabled = true }, -- Auto signature help while typing
		},
	},

	-- LSP SUPPORT (Native Nvim 0.11 Config)
	{
		"neovim/nvim-lspconfig",
		dependencies = { "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim" },
		config = function()
			require("mason").setup()
			require("mason-lspconfig").setup({
				ensure_installed = { "basedpyright", "clangd", "fortls" }, -- The Holy Trinity
			})

			-- NATIVE 0.11 CONFIGURATION
			-- We no longer use lspconfig.setup(). We use vim.lsp.config()

			-- Python: basedpyright (Better type inference for pandas/numpy)
			vim.lsp.config("basedpyright", {
				cmd = { "basedpyright-langserver", "--stdio" },
				root_markers = { "pyproject.toml", "requirements.txt", ".git" },
				settings = { basedpyright = { analysis = { typeCheckingMode = "basic" } } },
			})
			vim.lsp.enable("basedpyright")

			-- C++: clangd
			vim.lsp.config("clangd", { cmd = { "clangd" } })
			vim.lsp.enable("clangd")

			-- Fortran: fortls
			vim.lsp.config("fortls", {
				cmd = { "fortls", "--linter_extra_args=--no-error" },
				root_markers = { ".fortls", "Makefile", ".git" },
			})
			vim.lsp.enable("fortls")
		end,
	},

	-- SCIENTIFIC WORKFLOW: Slime (Send code to Zellij)
	{
		"jpalardy/vim-slime",
		init = function()
			vim.g.slime_target = "zellij"
			vim.g.slime_default_config = { session_id = "current", relative_pane = "right" }
			vim.g.slime_dont_ask_default = 1
			vim.g.slime_no_mappings = 1 -- We define custom mappings below
		end,
	},

	-- GIT INTEGRATION
	{ "lewis6991/gitsigns.nvim", opts = {} },

	-- FORMATTING (Minimal)
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				python = { "isort", "black" }, -- Standard scientific python formatting
			},
			format_on_save = { timeout_ms = 500, lsp_fallback = true },
		},
	},
}, {
	-- Add this block at the end of setup:
	lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json", -- Ensures lockfile stays in anzatz-lab/nvim/
	root = vim.fn.stdpath("data") .. "/lazy", -- Explicitly confirms plugin install location
})

-- 3. OPTIONS
--------------------------------------------------------------------------
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.clipboard = "unnamedplus" -- Sync with system clipboard
vim.opt.undofile = true -- Persistent undo
vim.opt.termguicolors = true
vim.opt.scrolloff = 8

-- 4. TREESITTER CONFIG
--------------------------------------------------------------------------
require("nvim-treesitter.configs").setup({
	ensure_installed = { "c", "cpp", "fortran", "python", "lua", "markdown", "markdown_inline", "make", "bash" },
	highlight = { enable = true },
	indent = { enable = true },
})

-- 5. KEYBINDINGS (The "Lab" Interface)
--------------------------------------------------------------------------
local keymap = vim.keymap.set

-- Standard Save/Quit
keymap("n", "<leader>w", ":w<CR>", { desc = "Save" })
keymap("n", "<leader>q", ":q<CR>", { desc = "Quit" })

-- Slime / Scientific Execution
-- <C-c><C-c> sends the current paragraph (block) to IPython
keymap("n", "<C-c><C-c>", "<Plug>SlimeParagraphSend", { desc = "Send Paragraph" })
keymap("x", "<C-c><C-c>", "<Plug>SlimeRegionSend", { desc = "Send Selection" })
-- <leader>r sends the whole file (like %run)
keymap("n", "<leader>r", ":%SlimeSend<CR>", { desc = "Run File" })

-- LSP
keymap("n", "gd", vim.lsp.buf.definition, { desc = "Go to Def" })
keymap("n", "K", vim.lsp.buf.hover, { desc = "Hover Doc" })
keymap("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename" })
keymap("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })

-- Diagnostics
keymap("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show Error" })
keymap("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev Error" })
keymap("n", "]d", vim.diagnostic.goto_next, { desc = "Next Error" })

-- ── PYTHON SCIENTIFIC MODE (# %% Cells) ──────────────────────────────────
vim.api.nvim_create_autocmd("FileType", {
	pattern = "python",
	callback = function()
		-- Define the cell delimiter for Slime
		vim.b.slime_cell_delimiter = "# %%"

		-- Map Shift+Enter in Normal Mode to send cell
		vim.keymap.set("n", "<S-CR>", "<Plug>SlimeSendCell", { buffer = true, desc = "Send Cell" })

		-- Map Shift+Enter in Insert Mode to send cell and stay in insert
		-- Note: <S-CR> support depends on your terminal emulator sending the correct keycode
		vim.keymap.set("i", "<S-CR>", "<Esc><Plug>SlimeSendCell", { buffer = true, desc = "Send Cell" })
	end,
})

print("Ansatz-lab: Online")

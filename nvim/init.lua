-- ==========================================================================
--  ANZATZ LAB: SCIENTIFIC NEOVIM 0.11.x CONFIGURATION
--  Robust, Minimal, Isolated.
--  Stack: Lazy | Blink | Native LSP | Telescope | Conform | Slime | VimTeX
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
	-- ── UI & THEMES ──────────────────────────────────────────────────────
	-- Icons (Required for Telescope/Lualine)
	{ "nvim-tree/nvim-web-devicons", lazy = true },

	-- Status Line (Professional Grade)
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		opts = {
			options = {
				theme = "auto", -- Automatically detects Everforest
				globalstatus = true, -- Single bar at bottom of screen
				component_separators = "|",
				section_separators = "",
			},
		},
	},

	-- Theme: Everforest
	{
		"sainnhe/everforest",
		lazy = false,
		priority = 1000,
		config = function()
			vim.o.background = "dark"
			vim.g.everforest_background = "hard"
			vim.g.everforest_better_performance = 1
			vim.g.everforest_enable_italic = 1
			vim.g.everforest_transparent_background = 2

			if pcall(vim.cmd.colorscheme, "everforest") then
				vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
				vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
				vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
				vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
			else
				print("Colorscheme 'everforest' not found yet. Installing...")
			end
		end,
	},

	-- ── NAVIGATION ───────────────────────────────────────────────────────
	-- Telescope (Fuzzy Finder)
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.6",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make", -- Requires gcc/make on system
			},
		},
		config = function()
			local telescope = require("telescope")
			telescope.setup({
				defaults = {
					file_ignore_patterns = { "__pycache__", "%.mod", "%.o", "%.pdf", "%.png" },
				},
			})
			telescope.load_extension("fzf")
		end,
	},

	-- Treesitter (Syntax Highlighting)
	{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

	-- ── CODING INTELLIGENCE ──────────────────────────────────────────────
	-- Completion: Blink.cmp
	{
		"saghen/blink.cmp",
		version = "*",
		dependencies = { "rafamadriz/friendly-snippets" },
		opts = {
			keymap = { preset = "default" },
			appearance = { use_nvim_cmp_as_default = true, nerd_font_variant = "mono" },
			sources = { default = { "lsp", "path", "snippets", "buffer" } },
			signature = { enabled = true },
		},
	},

	-- LSP & Tooling Management
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim", -- Auto-install formatters
		},
		config = function()
			require("mason").setup()

			-- Ensure servers AND formatters are installed
			require("mason-tool-installer").setup({
				ensure_installed = {
					"basedpyright",
					"clangd",
					"fortls",
					"texlab", -- LSPs
					"clang-format", -- C++ Formatter
					-- Note: fprettify (Fortran) is best installed via pip in your venv
				},
			})

			require("mason-lspconfig").setup({
				handlers = {
					function(server_name) -- Default handler for 0.11 native config
						vim.lsp.config(server_name, { cmd = { server_name } })
						vim.lsp.enable(server_name)
					end,
					-- Specialized Overrides
					["basedpyright"] = function()
						vim.lsp.config("basedpyright", {
							cmd = { "basedpyright-langserver", "--stdio" },
							root_markers = { "pyproject.toml", ".git" },
							settings = { basedpyright = { analysis = { typeCheckingMode = "basic" } } },
						})
						vim.lsp.enable("basedpyright")
					end,
					["fortls"] = function()
						vim.lsp.config("fortls", {
							cmd = { "fortls", "--linter_extra_args=--no-error" },
							root_markers = { ".fortls", "Makefile", ".git" },
						})
						vim.lsp.enable("fortls")
					end,
				},
			})
		end,
	},

	-- Formatting (Conform.nvim)
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				python = { "isort", "black" },
				c = { "clang-format" },
				cpp = { "clang-format" },
				fortran = { "fprettify" }, -- Expects 'pip install fprettify' in venv
			},
			format_on_save = { timeout_ms = 500, lsp_fallback = true },
		},
	},

	-- ── SCIENTIFIC TOOLS ─────────────────────────────────────────────────
	-- VimTeX (Writing Papers)
	{
		"lervag/vimtex",
		ft = { "tex", "bib" },
		init = function()
			vim.g.vimtex_view_method = "zathura"
			vim.g.vimtex_compiler_method = "latexmk"
			vim.g.vimtex_quickfix_mode = 0
		end,
	},

	-- Slime (Execution to Zellij)
	{
		"jpalardy/vim-slime",
		init = function()
			vim.g.slime_target = "zellij"
			vim.g.slime_bracketed_paste = 1
			vim.g.slime_no_mappings = 1

			-- Simple config: Just send right. We handle the return manually.
			vim.g.slime_default_config = { session_id = "current", relative_pane = "right", relative_move_back = 0 }
			vim.g.slime_dont_ask_default = 1
		end,
	},

	-- Git Integration
	{ "lewis6991/gitsigns.nvim", opts = {} },
}, {
	lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
	root = vim.fn.stdpath("data") .. "/lazy",
})

-- 3. OPTIONS
--------------------------------------------------------------------------
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.clipboard = "unnamedplus"
vim.opt.undofile = true
vim.opt.swapfile = false
vim.opt.termguicolors = true
vim.opt.scrolloff = 8

-- 4. TREESITTER CONFIG
--------------------------------------------------------------------------
require("nvim-treesitter.configs").setup({
	ensure_installed = { "c", "cpp", "fortran", "python", "lua", "markdown", "make", "bash", "latex", "bibtex" },
	highlight = { enable = true },
	indent = { enable = true },
})

-- 5. KEYBINDINGS
--------------------------------------------------------------------------
local keymap = vim.keymap.set

-- vimtex
keymap("n", "<localleader>ll", "<cmd>VimtexCompile<CR>")
keymap("n", "<localleader>lv", "<cmd>VimtexView<CR>")
keymap("n", "<localleader>lc", "<cmd>VimtexClean<CR>")

-- Standard
keymap("n", "<leader>w", ":w<CR>", { desc = "Save" })
keymap("n", "<leader>q", ":q<CR>", { desc = "Quit" })

-- Telescope (Find Files)
local builtin = require("telescope.builtin")
keymap("n", "<leader>ff", builtin.find_files, { desc = "Find Files" })
keymap("n", "<leader>fg", builtin.live_grep, { desc = "Grep Files" })
keymap("n", "<leader>fb", builtin.buffers, { desc = "Find Buffers" })

-- Slime
keymap("n", "<C-c><C-c>", "<Plug>SlimeParagraphSend", { desc = "Send Block" })
keymap("x", "<C-c><C-c>", "<Plug>SlimeRegionSend", { desc = "Send Selection" })
keymap("n", "<leader>r", ":%SlimeSend<CR>", { desc = "Run File" })

-- LSP
keymap("n", "gd", vim.lsp.buf.definition, { desc = "Go to Def" })
keymap("n", "K", vim.lsp.buf.hover, { desc = "Hover Doc" })
keymap("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename" })
keymap("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })
keymap("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show Error" })
keymap("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev Error" })
keymap("n", "]d", vim.diagnostic.goto_next, { desc = "Next Error" })

-- ── PYTHON SCIENTIFIC MODE (# %% Cells) ──────────────────────────────────
vim.api.nvim_create_autocmd("FileType", {
	pattern = "python",
	callback = function()
		vim.b.slime_cell_delimiter = "# %%"

		-- CUSTOM FUNCTION: Send Cell -> Wait -> Force Focus Left
		local function send_cell_and_return()
			-- 1. Trigger Slime (It won't crash now because relative_move_back=0 exists)
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Plug>SlimeSendCell", true, true, true), "m", true)

			-- 2. Force Zellij to look back at Neovim after a split second
			vim.defer_fn(function()
				vim.fn.system("zellij action move-focus left")
			end, 100) -- 100ms delay to let the terminal digest the paste
		end

		-- Map Shift+Enter
		vim.keymap.set("n", "<S-CR>", send_cell_and_return, { buffer = true, desc = "Send Cell & Return" })
		vim.keymap.set("i", "<S-CR>", function()
			vim.cmd("stopinsert")
			send_cell_and_return()
		end, { buffer = true, desc = "Send Cell & Return" })
	end,
})
print("Ansatz-lab: Online")

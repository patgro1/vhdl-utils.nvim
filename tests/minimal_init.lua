-- tests/minimal_init.lua
local plenary_dir = os.getenv("PLENARY_DIR") or "/tmp/plenary.nvim"
local treesitter_dir = os.getenv("TREESITTER_DIR") or "/tmp/nvim-treesitter"

-- Clone dependencies if they don't exist
local function ensure_installed(url, install_path)
    if vim.fn.isdirectory(install_path) == 0 then
        print("Installing " .. url .. " to " .. install_path)
        vim.fn.system({ "git", "clone", "--depth=1", url, install_path })
    end
end

ensure_installed("https://github.com/nvim-lua/plenary.nvim", plenary_dir)
ensure_installed("https://github.com/nvim-treesitter/nvim-treesitter", treesitter_dir)

-- Add to runtime path
vim.opt.rtp:prepend(plenary_dir)
vim.opt.rtp:prepend(treesitter_dir)
vim.opt.rtp:prepend(vim.fn.getcwd())

-- Load treesitter
vim.cmd("runtime! plugin/nvim-treesitter.lua")

-- Install VHDL parser
require("nvim-treesitter.configs").setup({
    ensure_installed = { "vhdl" },
    sync_install = true,
})

-- Detect if running in CI
local is_ci = os.getenv("CI") ~= nil

if is_ci then
    -- CI paths
    vim.opt.rtp:append("~/.local/share/nvim/site/pack/ci/opt/plenary.nvim")
    vim.opt.rtp:append("~/.local/share/nvim/site/pack/ci/opt/nvim-treesitter")
    vim.opt.rtp:append("~/.local/share/nvim/site/pack/ci/opt/vhdl-utils.nvim")
else
    -- Local development - use your actual paths
    local data_path = vim.fn.stdpath("data")
    vim.opt.rtp:append(data_path .. "/lazy/plenary.nvim")
    vim.opt.rtp:append(data_path .. "/lazy/nvim-treesitter")
    vim.opt.rtp:append(".") -- Current directory (plugin root)
end

vim.cmd("runtime! plugin/plenary.vim")
vim.cmd("runtime! plugin/nvim-treesitter.lua")

require("nvim-treesitter.configs").setup({
    ensure_installed = { "vhdl" },
    sync_install = true,
})

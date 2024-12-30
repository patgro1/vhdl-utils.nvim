vim.cmd([[
packadd plenary.nvim
packadd nvim-treesitter
packadd vhdl-utils
]])
require("nvim-treesitter.configs").setup({
    -- A list of parser names, or "all"
    ensure_installed = "vhdl",

    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = true,

    auto_install = true,
})

vim.cmd("TSUpdate")

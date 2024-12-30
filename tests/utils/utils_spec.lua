local utils = require("vhdl-utils.utils")

describe("find_scope_node", function()
    require("plenary.reload").reload_module("nvim-treesitter/nvim-treesitter")
    -- require("plenary.reload").reload_module("nvim-treesitter/nvim-treesitter.configs")
    require("nvim-treesitter.configs").setup({
        -- A list of parser names, or "all"
        ensure_installed = "vhdl",

        -- Install parsers synchronously (only applied to `ensure_installed`)
        sync_install = true,

        auto_install = true,
    })

    local function find_scope(file, node_coord)
        -- vim.api.nvim_buf_set_lines(0, 0, -1, false, file_content)
        vim.cmd(string.format("edit %s", file))
        vim.api.nvim_win_set_cursor(0, { node_coord.row, node_coord.col })
        vim.treesitter.get_parser(0, "vhdl", {}):parse()
        local node = vim.treesitter.get_node({ bufnr = 0 })
        return utils.find_scope_node(node)
    end
    it("Find the scope when it is in an architecture", function()
        local file = "tests/utils/examples/simple_architecture.vhdl"
        local node_coord = { row = 2, col = 12 }

        assert.are.same("architecture_head", find_scope(file, node_coord):type())
    end)
    it("Find the scope when it is in a generate", function()
        local file = "tests/utils/examples/simple_architecture.vhdl"
        local node_coord = { row = 5, col = 15 }

        assert.are.same("generate_head", find_scope(file, node_coord):type())
    end)
    it("Find the scope when it is in a block", function()
        local file = "tests/utils/examples/simple_architecture.vhdl"
        local node_coord = { row = 10, col = 15 }

        assert.are.same("block_head", find_scope(file, node_coord):type())
    end)
    it("It finds the proper block when block are within each other", function()
        local file = "tests/utils/examples/simple_architecture.vhdl"
        local node_coord = { row = 14, col = 20 }

        local scope_node = find_scope(file, node_coord)
        local start_row, _, end_row, _ = scope_node:range(false)
        -- local expected = { start= 12, end = 14 }
        assert.are.same("block_head", scope_node:type())
        assert.are.same(12, start_row)
        assert.are.same(13, end_row)
    end)
end)

local utils = require("vhdl-utils.utils")
local M = {}

M.config = function(config) end

-- Main function that handles adding debug attributes with parameters
--- Add debug attributes to the code. The rows should be 0 based to concord with the treesitter plugin
--- @param bufnr integer
--- @param start_row integer
--- @param end_row integer
--- @param position_choice string
--- @param attribute_value string|nil
local function add_debug_attributes_to_signals(bufnr, start_row, end_row, position_choice, attribute_value)
    -- Get the syntax tree for the current buffer
    local parser = vim.treesitter.get_parser(bufnr, "vhdl")
    local tree = parser:parse()[1]
    local root = tree:root()

    attribute_value = attribute_value or vim.fn.input("Enter value for mark_debug attribute: ", "true")

    -- Tree-sitter query to find signal declarations
    local signal_query = vim.treesitter.query.parse(
        "vhdl",
        [[
    (signal_declaration
        (identifier_list (identifier) @signal.name)) 
  ]]
    )

    -- Tree-sitter query to find existing mark_debug attributes
    local attribute_query = vim.treesitter.query.parse(
        "vhdl",
        [[
    (attribute_specification
        attribute: (attribute_identifier) @attribute.name (#match? @attribute.name "^[Mm][Aa][Rr][Kk]_[Dd][Ee][Bb][Uu][Gg]$")
        (entity_specification (entity_name_list (entity_designator (identifier) @signal.name))))
  ]]
    )

    -- Function to check if an attribute line already exists
    local function is_attribute_present(signal_name)
        for _, node in attribute_query:iter_captures(root, bufnr, 0, -1) do
            local existing_name = vim.treesitter.get_node_text(node, bufnr)
            if existing_name == signal_name then
                return true
            end
        end
        return false
    end

    -- Store signal names and their range
    local signal_names = {}
    local last_signal_end_row = start_row
    local first_signal_node = nil

    for _, node in signal_query:iter_captures(root, bufnr, start_row - 1, end_row) do
        local signal_name = vim.treesitter.get_node_text(node, bufnr)
        if first_signal_node == nil then
            first_signal_node = node
        end
        if signal_name and not is_attribute_present(signal_name) then
            local _, _, node_end_row, _ = vim.treesitter.get_node_range(node)
            table.insert(signal_names, { name = signal_name, row = node_end_row })
        end
    end

    local scope_node = utils.find_scope_node(first_signal_node)

    -- If no signals were found, exit early
    if #signal_names == 0 then
        return
    end

    -- Store attribute lines to be added
    local attribute_lines = {}
    for _, signal in ipairs(signal_names) do
        table.insert(
            attribute_lines,
            string.format("attribute mark_debug of %s: signal is %s;", signal.name, attribute_value)
        )
    end

    local insertion_row = end_row - 1
    if scope_node and position_choice == "e" then
        _, _, insertion_row, _ = vim.treesitter.get_node_range(scope_node)
    end

    -- Insert the attributes at the insertion point
    vim.api.nvim_buf_set_lines(bufnr, insertion_row + 1, insertion_row + 1, false, attribute_lines)
    -- indent the lines
    vim.api.nvim_buf_call(bufnr, function()
        vim.fn.execute(insertion_row + 1 .. "," .. insertion_row + 1 + #attribute_lines .. "normal! ==")
    end)
end

-- add_debug_attributes_to_signals(43, 83, 155, "b")

local function add_debug_attributes_to_visual_range(bufnr, attribute_value, position_choice)
    local start_row, _, end_row, _ = get_visual_selection_range()
    -- add_debug_attributes_to_signals(bufnr, start_row, end_row, attribute_value, position_choice)
    add_debug_attributes_to_signals(0, start_row, end_row, attribute_value, position_choice)
end

--- This function return the current visual range selected. It makes sure that the start comes before the end in case
--- the selection was made backward
local function get_visual_selection_range()
    -- Get the start and end of the visual selection
    local start_row, start_col = unpack(vim.fn.getpos("v"), 2, 3)
    local end_row, end_col = unpack(vim.fn.getpos("."), 2, 3)

    if start_row > end_row then
        local temp_row = end_row
        local temp_col = end_col
        end_row = start_row
        end_col = start_col
        start_row = temp_row
        start_col = temp_col
    end
    return start_row, start_col, end_row, end_col
end

-- Function to add debug below the selection with a prompt for value
local function add_debug_below_selection(bufnr, start_row, end_row)
    -- Prompt for the attribute value
    local attribute_value = vim.fn.input("Enter value for mark_debug attribute: ", "true")
    -- Call the main function with the prompt value and "b" for below selection
    add_debug_attributes_to_signals(bufnr, start_row, end_row, attribute_value, "b")
end

-- Function to add debug below the selection with value set to "true"
local function add_debug_below_selection_true(bufnr, start_row, end_row)
    -- Call the main function with "true" as the attribute value and "b" for below selection
    add_debug_attributes_to_signals(bufnr, start_row, end_row, "true", "b")
end

-- Function to add debug at the end of the block with a prompt for value
local function add_debug_at_end_of_block(bufnr, start_row, end_row)
    -- Prompt for the attribute value
    local attribute_value = vim.fn.input("Enter value for mark_debug attribute: ", "true")
    -- Call the main function with the prompt value and "e" for end of block
    add_debug_attributes_to_signals(bufnr, start_row, end_row, attribute_value, "e")
end

-- Function to add debug at the end of the block with value set to "true"
M.add_debug_below_selection_true = function(bufnr)
    -- Call the main function with "true" as the attribute value and "e" for end of block
    add_debug_attributes_to_visual_range(bufnr, "true", "b")
end
M.add_debug_at_end_of_block_true = function(bufnr)
    -- Call the main function with "true" as the attribute value and "e" for end of block
    add_debug_attributes_to_visual_range(bufnr, "true", "e")
end

-- Key mappings for predefined actions using Lua's vim.api.nvim_set_keymap
-- vim.api.nvim_set_keymap('v', '<leader>md', [[<cmd>lua ask_for_value_and_location(vim.api.nvim_get_current_buf(), vim.fn.line("'<"), vim.fn.line("'>"))<CR>]], { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('v', '<leader>mb', [[<cmd>lua add_debug_below_selection(vim.api.nvim_get_current_buf(), vim.fn.line("'<"), vim.fn.line("'>"))<CR>]], { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('v', '<leader>mbt', [[<cmd>lua add_debug_below_selection_true(vim.api.nvim_get_current_buf(), vim.fn.line("'<"), vim.fn.line("'>"))<CR>]], { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('v', '<leader>me', [[<cmd>lua add_debug_at_end_of_block(vim.api.nvim_get_current_buf(), vim.fn.line("'<"), vim.fn.line("'>"))<CR>]], { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('v', '<leader>met', [[<cmd>lua add_debug_at_end_of_block_true(vim.api.nvim_get_current_buf(), vim.fn.line("'<"), vim.fn.line("'>"))<CR>]], { noremap = true, silent = true }

local M = {}

function M.with_vhdl_buffer(text, callback)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(text, "\n"))
    local ok = pcall(function()
        vim.bo[bufnr].filetype = "vhdl"
    end)
    if not ok then
        vim.api.nvim_buf_set_option(bufnr, "filetype", "vhdl")
    end
    local result = callback(bufnr)
    vim.api.nvim_buf_delete(bufnr, { force = true })
    return result
end

function M.extract_signals_from_text(text)
    return M.with_vhdl_buffer(text, function(bufnr)
        local mark_debug = require("vhdl-utils.mark_debug")
        return mark_debug.extract_signals(bufnr, 0, -1)
    end)
end

function M.find_insertion_point_from_text(text, placement)
    return M.with_vhdl_buffer(text, function(bufnr)
        local mark_debug = require("vhdl-utils.mark_debug")
        return mark_debug.find_insertion_point(bufnr, placement or "end_of_declaration")
    end)
end

function M.apply_mark_debug(text, start_line, end_line, placement)
    return M.with_vhdl_buffer(text, function(bufnr)
        local mark_debug = require("vhdl-utils.mark_debug")
        mark_debug.apply(bufnr, start_line, end_line, placement or "end_of_declaration")

        -- Get the modified buffer content
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        return table.concat(lines, "\n")
    end)
end

function M.get_marked_signals_from_text(text)
    return M.with_vhdl_buffer(text, function(bufnr)
        local mark_debug = require("vhdl-utils.mark_debug")
        return mark_debug.get_marked_signals(bufnr)
    end)
end

function M.has_mark_debug_declaration_at_arch_from_text(text)
    return M.with_vhdl_buffer(text, function(bufnr)
        local mark_debug = require("vhdl-utils.mark_debug")
        return mark_debug.has_mark_debug_declaration_at_arch(bufnr)
    end)
end

return M

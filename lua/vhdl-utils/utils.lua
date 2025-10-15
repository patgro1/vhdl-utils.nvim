local M = {}
function M.query_buffer(bufnr, query_string, start_line, end_line)
    local parser = vim.treesitter.get_parser(bufnr, "vhdl")
    if not parser then
        return nil, "No parser found"
    end

    local trees = parser:parse()
    if not trees or #trees == 0 then
        return nil, "No parse tree available"
    end

    local tree = trees[1]
    if not tree then
        return nil, "No tree in parse result"
    end

    local root = tree:root()
    if not root then
        return nil, "No root node"
    end


    local ok, query_or_err = pcall(vim.treesitter.query.parse, "vhdl", query_string)
    if not ok then
        return nil, "Parse error: " .. tostring(query_or_err)
    end

    local query = query_or_err
    if not query then
        return nil, "Query is nil"
    end

    local iter = query:iter_captures(root, bufnr, start_line or 0, end_line or -1)
    return iter, query
end

function M.normalize_vhdl_identifier(str)
    return str:lower()
end

function M.insert_lines_and_indent(bufnr, line, lines)
    vim.api.nvim_buf_set_lines(bufnr, line, line, false, lines)

    -- Auto-indent
    vim.api.nvim_buf_call(bufnr, function()
        local start_line = line + 1
        local end_line = line + #lines
        vim.cmd(string.format("%d,%dnormal! ==", start_line, end_line))
    end)
end

return M

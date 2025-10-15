local M = {}

M.setup = function(opts)
    M.config = vim.tbl_deep_extend("force", {
        mark_debug = {
            value = "true",
            placement = "end_of_declaration",
        }
    }, opts or {})
end

return M

local M = {}

--- Find the scope of the current signal (architecture, block or generate)
---
--- It recursively scan the parents to find an architecture, a generate or a block. The first found is
--- forced to be the closest parent where declarations are made
--- @param node TSNode
--- @return TSNode|nil
M.find_scope_node = function(node)
    local parent_node = node:parent()
    if not parent_node then
        return nil
    else
        if parent_node:type() == "design_unit" then
            return nil
        elseif
            parent_node:type() == "architecture_head"
            or parent_node:type() == "generate_head"
            or parent_node:type() == "block_head"
        then
            return parent_node
        else
            return M.find_scope_node(parent_node)
        end
    end
end

return M

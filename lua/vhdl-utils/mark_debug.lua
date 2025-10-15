local M = {}
local utils = require("vhdl-utils.utils")
function M.extract_signals(bufnr, start_line, end_line)
    local query_string = [[
    (architecture_head
        (signal_declaration
            (identifier_list
                (identifier) @signal_name))) @arch_head

    (generate_head
        (signal_declaration
            (identifier_list
                (identifier) @signal_name))) @gen_head

    (block_head
        (signal_declaration
            (identifier_list
                (identifier) @signal_name))) @block_head
    ]]

    local signals = {}
    local iter, query = utils.query_buffer(bufnr, query_string, start_line, end_line)

    if not query or not iter then
        return signals
    end
    local current_scope = nil
    local current_scope_type = nil

    for id, node in iter do
        local capture_name = query.captures[id]

        if capture_name == "arch_head" then
            current_scope = node
            current_scope_type = "architecture_head"
        elseif capture_name == "gen_head" then
            current_scope = node
            current_scope_type = "generate_head"
        elseif capture_name == "block_head" then
            current_scope = node
            current_scope_type = "block_head"
        elseif capture_name == "signal_name" then
            local signal_name = vim.treesitter.get_node_text(node, bufnr)
            table.insert(signals, {
                name = signal_name,
                scope = current_scope,
                scope_type = current_scope_type
            })
        end
    end

    return signals
end

function M.find_insertion_point(bufnr, placement, signal_nodes)
    -- placement: "end_of_declaration" | "after_each" | "grouped"
    -- signal_nodes: the actual treesitter nodes (for after_each placement)

    if placement == "end_of_declaration" then
        return M.find_architecture_begin(bufnr)
    elseif placement == "after_each" then
        return M.find_after_each_signal(bufnr, signal_nodes)
    elseif placement == "grouped" then
        return M.find_after_signal_groups(bufnr, signal_nodes)
    end
end

function M.find_architecture_begin(bufnr)
    local query_string = [[
        (architecture_definition
            (concurrent_block) @block)
    ]]
    local iter, query = utils.query_buffer(bufnr, query_string, 0, -1)
    if not iter or not query then
        return 0
    end

    local found_any = false
    for id, node in iter do
        local capture_name = query.captures[id]
        found_any = true

        if capture_name == "block" then
            local start_row, _, _, _ = node:range()
            return start_row
        end
    end
    if not found_any then
    end
    return 0
end

function M.find_after_each_signal(bufnr, signal_nodes)
    return 0
end

function M.find_after_signal_groups(bufnr, signal_nodes)
    return 0
end

function M.apply(bufnr, start_line, end_line, placement)
    -- Extract the signals from the range
    local all_signals = M.extract_signals(bufnr, start_line, end_line)

    if #all_signals == 0 then
        vim.notify("No signals found in the range", vim.log.levels.WARN)
        return
    end

    -- Filter out already marked signals
    local marked_signals = M.get_marked_signals(bufnr)
    local signals_to_mark = {}

    for _, sig_info in ipairs(all_signals) do
        local normalized_name = utils.normalize_vhdl_identifier(sig_info.name)
        if not marked_signals[normalized_name] then
            table.insert(signals_to_mark, sig_info.name)
        end
    end
    if #signals_to_mark == 0 then
        vim.notify("All signals already marked", vim.log.levels.INFO)
        return
    end

    -- Find the insertion point
    local insert_line = M.find_insertion_point(bufnr, placement, signals)
    if not insert_line or insert_line < 0 then
        vim.notify("Could not find insertion point", vim.log.levels.ERROR)
        return
    end

    -- Generate the attribute line
    local has_declaration = M.has_mark_debug_declaration_at_arch(bufnr)
    local lines = M.generate_mark_debug_attributes(signals_to_mark, has_declaration)

    utils.insert_lines_and_indent(bufnr, insert_line, lines)

    vim.notify(string.format("Added MARK_DEBUG for %d signals", #lines), vim.log.levels.INFO)
end

function M.get_marked_signals(bufnr)
    local query_string = [[
    (attribute_specification
        attribute: (attribute_identifier) @attr_name
        (entity_specification
            (entity_name_list
                (entity_designator
                    (identifier) @signal_name))))

]]
    local marked = {}
    local iter, query = utils.query_buffer(bufnr, query_string)

    if not iter or not query then
        return marked
    end

    local current_attr = nil
    for id, node in iter do
        local capture_name = query.captures[id]
        if capture_name == "attr_name" then
            current_attr = utils.normalize_vhdl_identifier(vim.treesitter.get_node_text(node, bufnr))
        elseif capture_name == "signal_name" and current_attr == "mark_debug" then
            local signal_name = utils.normalize_vhdl_identifier(vim.treesitter.get_node_text(node, bufnr))
            marked[utils.normalize_vhdl_identifier(signal_name)] = true
        end
    end
    return marked
end

function M.generate_attribute_declaration()
    return { "attribute MARK_DEBUG: string" }
end

function M.generate_mark_debug_attributes(signals, skip_declaration)
    local config = require("vhdl-utils").config or { mark_debug = { value = "true" } }
    local value = config.mark_debug.value

    local value_str
    if value:match("^['\"]") then
        value_str = value
    elseif value == "true" or value == "false" then
        value_str = '"' .. value .. '"'
    else
        value_str = value
    end

    local lines = {}

    if not skip_declaration then
        lines = {
            "attribute MARK_DEBUG : string;"
        }
    end

    for _, signal in ipairs(signals) do
        table.insert(lines, string.format('attribute MARK_DEBUG of %s : signal is %s;', signal, value_str))
    end
    return lines
end

function M.has_mark_debug_declaration_at_arch(bufnr)
    local query_string = [[
    (architecture_head
      (attribute_declaration
        attribute: (identifier) @attr_name))
  ]]

    local iter, query = utils.query_buffer(bufnr, query_string)

    if not iter or not query then
        return false
    end

    for id, node in iter do
        if query.captures[id] == 'attr_name' then
            local name = utils.normalize_vhdl_identifier(vim.treesitter.get_node_text(node, bufnr))
            if name == "mark_debug" then
                return true
            end
        end
    end
    return false
end

function M.has_mark_debug_declaration_in_scope(bufnr, scope_node)
    if not scope_node then
        return false
    end

    local query_string = [[
    (attribute_declaration
        attribute: (identifier) @attr_name)
    ]]
    local start_line, _, end_line, _ = scope_node:range()
    local iter, query
    utils.query_buffer(bufnr, query_string, start_line, end_line)

    if not iter or not query then
        return false
    end

    for id, node in iter do
        if query.captures[id] == 'attr_name' then
            local name = utils.normalize_vhdl_identifier(vim.treesitter.get_node_text(node, bufnr))
            if name == "mark_debug" then
                return true
            end
        end
    end
    return false
end

function M.find_insertion_point_for_scope(scope_node)
    if not scope_node then
        return 0
    end

    -- For all scope types, find the concurrent block or sequential block child
    -- and insert right before it
    for i = 0, scope_node:child_count() - 1 do
        local child = scope_node:child(i)
        local child_type = child:type()
        if child_type == "concurrent_block" or child_type == "sequential_block" then
            local start_line, _, _, _ = child.range()
            return start_line
        end
    end

    return 0
end

return M

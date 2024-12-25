local debug_attributes = require("vhdl-utils.debug-attributes")

local core = {
    setup = function(config)
        config = config or {}
        -- debug_attributes.config(config.debug_attributes or {})
    end, -- Function to set keymaps
    set_keymaps = function(keymaps)
        for mode, mappings in pairs(keymaps) do
            for lhs, rhs in pairs(mappings) do
                vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true })
            end
        end
    end,
}

return setmetatable({}, {
    __index = function(_, key)
        -- Define public API functions here
        local public_api = {
            setup = core.setup,
            -- add_debug_at_end_of_block_true = debug_attributes.add_debug_at_end_of_block_true,
            -- add_debug_below_selection_true = debug_attributes.add_debug_below_selection_true,
            -- do_another_thing = module2.do_another_thing,
        }
        -- Return the requested API function or nil if not found
        return public_api[key]
    end,
})

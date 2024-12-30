.PHONY: test lint docgen

test:
	nvim --headless --noplugin -u scripts/minimal_init.lua -c "PlenaryBustedDirectory tests/ { minimal_init = './scripts/minimal_init.lua' }"

lint:
	luacheck lua/vhdl-utils

# docgen:
# 	nvim --headless --noplugin -u scripts/minimal_init.vim -c "luafile ./scripts/gendocs.lua" -c 'qa'

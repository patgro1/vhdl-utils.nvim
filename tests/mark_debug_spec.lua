local helpers = require("tests.helpers")

describe("mark_debug signal extraction", function()
    it("extracts single signal declaration", function()
        local content = [[
architecture rtl of my_entity is
    signal clk : std_logic;
begin
]]
        local signals = helpers.extract_signals_from_text(content)
        assert.are.equal(1, #signals)
        assert.are.equal("clk", signals[1].name)
        assert.are.same("architecture_head", signals[1].scope_type)
    end)
    it("extracts multiple signal declaration", function()
        local content = [[
architecture rtl of my_entity is
    signal clk : std_logic;

    signal rst : std_logic;
begin
]]
        local signals = helpers.extract_signals_from_text(content)
        assert.are.equal(2, #signals)
        assert.are.equal("clk", signals[1].name)
        assert.are.equal("architecture_head", signals[1].scope_type)
        assert.are.equal("rst", signals[2].name)
        assert.are.equal("architecture_head", signals[2].scope_type)
    end)
    it("extracts signals from generate block", function()
        local content = [[
architecture rtl of my_entity is
  signal clk : std_logic;
begin
  g_generate: if TRUE generate
    signal gen_sig : std_logic;
  end generate;
begin
end architecture;
]]
        local signals = helpers.extract_signals_from_text(content)
        assert.are.equal(2, #signals)
        assert.are.equal("clk", signals[1].name)
        assert.are.equal("architecture_head", signals[1].scope_type)
        assert.are.equal("gen_sig", signals[2].name)
        assert.are.equal("generate_head", signals[2].scope_type)
    end)

    it("extracts signals from block statement", function()
        local content = [[
architecture rtl of my_entity is
begin
  b_block: block
    signal block_sig : std_logic;
  begin
  end block;
begin
end architecture;
]]
        local signals = helpers.extract_signals_from_text(content)
        assert.are.equal(1, #signals)
        assert.are.equal("block_sig", signals[1].name)
        assert.are.equal("block_head", signals[1].scope_type)
    end)
end)


describe("mark_debug find insertion point", function()
    it("finds line before the begin keyword", function()
        local content = [[
architecture rtl of my_entity is
    signal clk: std_logic;
    signal rst: std_logic;
begin
end architecture;
]]
        local line = helpers.find_insertion_point_from_text(content, "end_of_declaration")
        assert.are.equal(3, line)
    end)

    it("handles no blank line before begin", function()
        local content = [[
architecture rtl of my_entity is
    signal clk: std_logic;
begin
end architecture;
]]
        local line = helpers.find_insertion_point_from_text(content, "end_of_declaration")
        assert.are.equal(2, line)
    end)

    it("handles blank lines before begin", function()
        local content = [[
architecture rtl of my_entity is
    signal clk: std_logic;


begin
end architecture;
]]
        local line = helpers.find_insertion_point_from_text(content, "end_of_declaration")
        assert.are.equal(4, line)
    end)
    it("ignores begin inside process blocks", function()
        local content = [[
architecture rtl of my_entity is
    signal clk: std_logic;
begin
    p_a_process(clk) is
    begin
    end process;
end architecture;
]]
        local line = helpers.find_insertion_point_from_text(content, "end_of_declaration")
        assert.are.equal(2, line)
    end)
    it("ignores begin inside signal names", function()
        local content = [[
architecture rtl of my_entity is
    signal clk: std_logic;
    signal begin : std_logic;
begin
end architecture;
]]
        local line = helpers.find_insertion_point_from_text(content, "end_of_declaration")
        assert.are.equal(3, line)
    end)
end)

describe("get_marked_signals", function()
    it("finds marked signals", function()
        local content = [[
architecture rtl of my_entity is
  signal clk : std_logic;
  signal reset_n : std_logic;
  attribute MARK_DEBUG : string;
  attribute MARK_DEBUG of clk : signal is "true";
begin
end architecture;
]]

        local marked = helpers.get_marked_signals_from_text(content)
        assert.is_true(marked["clk"])
        assert.is_nil(marked["reset_n"])
    end)

    it("is case insensitive", function()
        local content = [[
architecture rtl of my_entity is
  signal CLK : std_logic;
  attribute MARK_DEBUG : string;
  attribute MaRk_DebuG of cLk : signal is "true";
begin
end architecture;
]]

        local marked = helpers.get_marked_signals_from_text(content)
        assert.is_true(marked["clk"])
    end)
end)

describe("has_mark_debug_declaration_at_arch", function()
    it("detects MARK_DEBUG at architecture level", function()
        local content = [[
architecture rtl of my_entity is
  signal clk : std_logic;
  attribute MARK_DEBUG : string;
begin
end architecture;
]]

        local has_decl = helpers.has_mark_debug_declaration_at_arch_from_text(content)
        assert.is_true(has_decl)
    end)

    it("returns false when MARK_DEBUG not at architecture level", function()
        local content = [[
architecture rtl of my_entity is
  signal clk : std_logic;
begin
  g_gen: if TRUE generate
    attribute MARK_DEBUG : string;
  begin
  end generate;
end architecture;
]]

        local has_decl = helpers.has_mark_debug_declaration_at_arch_from_text(content)
        assert.is_false(has_decl)
    end)

    it("is case insensitive", function()
        local content = [[
architecture rtl of my_entity is
  attribute mark_debug : string;
begin
end architecture;
]]

        local has_decl = helpers.has_mark_debug_declaration_at_arch_from_text(content)
        assert.is_true(has_decl)
    end)
end)

describe("mark_debug insertion", function()
    it("insert MARK_DEBUG attributes at the end of declaration", function()
        local content = [[
architecture rtl of my_empty_entity is
    signal clk: std_logic;
    signal reset_n: std_logic;
begin
end architecture;
    ]]
        local expected = [[
architecture rtl of my_empty_entity is
    signal clk: std_logic;
    signal reset_n: std_logic;
    attribute MARK_DEBUG : string;
    attribute MARK_DEBUG of clk : signal is "true";
    attribute MARK_DEBUG of reset_n : signal is "true";
begin
end architecture;
    ]]
        local result = helpers.apply_mark_debug(content, 0, -1, "end_of_declaration")
        assert.are.equal(expected, result)
    end)
    it("inserts MARK_DEBUG with variable value (no quotes)", function()
        local content = [[
     architecture rtl of my_empty_entity is
    signal clk: std_logic;
    signal reset_n: std_logic;
     begin
     end architecture;
     ]]

        local expected = [[
     architecture rtl of my_empty_entity is
    signal clk: std_logic;
    signal reset_n: std_logic;
    attribute MARK_DEBUG : string;
    attribute MARK_DEBUG of clk : signal is DEBUG_EN;
    attribute MARK_DEBUG of reset_n : signal is DEBUG_EN;
     begin
     end architecture;
     ]]

        -- Need to temporarily override config
        local vhdl_utils = require("vhdl-utils")
        local old_config = vhdl_utils.config
        vhdl_utils.config = {
            mark_debug = { value = "DEBUG_EN" }
        }

        local result = helpers.apply_mark_debug(content, 0, -1, "end_of_declaration")

        -- Restore config
        vhdl_utils.config = old_config

        assert.are.equal(expected, result)
    end)
    it("inserts MARK_DEBUG with quoted value", function()
        local content = [[
     architecture rtl of my_empty_entity is
    signal clk: std_logic;
    signal reset_n: std_logic;
     begin
     end architecture;
     ]]

        local expected = [[
     architecture rtl of my_empty_entity is
    signal clk: std_logic;
    signal reset_n: std_logic;
    attribute MARK_DEBUG : string;
    attribute MARK_DEBUG of clk : signal is "MY_VALUE";
    attribute MARK_DEBUG of reset_n : signal is "MY_VALUE";
     begin
     end architecture;
     ]]

        local vhdl_utils = require("vhdl-utils")
        local old_config = vhdl_utils.config
        vhdl_utils.config = {
            mark_debug = { value = '"MY_VALUE"' }
        }

        local result = helpers.apply_mark_debug(content, 0, -1, "end_of_declaration")

        vhdl_utils.config = old_config

        assert.are.equal(expected, result)
    end)
    it("skips attribute declaration if already exists", function()
        local content = [[
     architecture rtl of my_empty_entity is
    signal clk: std_logic;
    signal reset_n: std_logic;
    attribute MARK_DEBUG : string;
     begin
     end architecture;
     ]]

        local expected = [[
     architecture rtl of my_empty_entity is
    signal clk: std_logic;
    signal reset_n: std_logic;
    attribute MARK_DEBUG : string;
    attribute MARK_DEBUG of clk : signal is "true";
    attribute MARK_DEBUG of reset_n : signal is "true";
     begin
     end architecture;
     ]]

        local result = helpers.apply_mark_debug(content, 0, -1, "end_of_declaration")
        assert.are.equal(expected, result)
    end)

    it("skips signals that are already marked", function()
        local content = [[
     architecture rtl of my_empty_entity is
    signal clk: std_logic;
    signal reset_n: std_logic;
    attribute MARK_DEBUG : string;
    attribute MARK_DEBUG of clk : signal is "true";
     begin
     end architecture;
     ]]

        local expected = [[
     architecture rtl of my_empty_entity is
    signal clk: std_logic;
    signal reset_n: std_logic;
    attribute MARK_DEBUG : string;
    attribute MARK_DEBUG of clk : signal is "true";
    attribute MARK_DEBUG of reset_n : signal is "true";
     begin
     end architecture;
     ]]

        local result = helpers.apply_mark_debug(content, 0, -1, "end_of_declaration")
        assert.are.equal(expected, result)
    end)

    it("does nothing if all signals already marked", function()
        local content = [[
     architecture rtl of my_empty_entity is
    signal clk: std_logic;
    attribute MARK_DEBUG : string;
    attribute MARK_DEBUG of clk : signal is "true";
     begin
     end architecture;
     ]]

        local result = helpers.apply_mark_debug(content, 0, -1, "end_of_declaration")
        assert.are.equal(content, result)
    end)
end)

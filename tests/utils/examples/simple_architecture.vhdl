architecture rtl of toto is
    signal damn: std_logic_vector(5-1 downto 0);
begin
    g_generate: if TOTO generate
        signal generate_signal_def: std_logic;
    begin
    end generate;

    b_block: block is
        signal block_signal: std_logic;
    begin

        b_internal_block: block is
            signal internal_b_signal: std_logic;
        begin
        end block;
    end block;

end architecture;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_top is
end entity;

architecture sim of tb_top is
    -- Clock/reset
    signal clk   : std_logic := '0';
    signal rstn  : std_logic := '0';
    signal uart_tx : std_logic;

    -- Wishbone signals (driven as pseudo-master)
    signal wb_data_out_adr : std_logic_vector(31 downto 0);
    signal wb_data_out_dat : std_logic_vector(31 downto 0);
    signal wb_data_out_we  : std_logic;

    -- SHA output
    signal sha_rdata   : std_logic_vector(31 downto 0);
    signal sha_ack_int : std_logic;

    -- Small RAM payload for test
    type payload_array is array(0 to 7) of std_logic_vector(31 downto 0);
    constant payload1 : payload_array := (x"00000000", x"00000000", x"00000000", x"00000000",
                                          x"00000000", x"00000000", x"00000000", x"00000000");
    constant payload2 : payload_array := (x"61626300", x"00000000", x"00000000", x"00000000",
                                          x"00000000", x"00000000", x"00000000", x"00000000");

    -- Expected hashes
    constant hash1 : std_logic_vector(255 downto 0) := x"E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855";
    constant hash2 : std_logic_vector(255 downto 0) := x"BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD";

    -- Clock period
    constant clk_period : time := 10 ns;

begin
    -- Clock generator
    clk_proc : process
    begin
        while now < 10 ms loop
            clk <= '0'; wait for clk_period/2;
            clk <= '1'; wait for clk_period/2;
        end loop;
        wait;
    end process;

    -- Instantiate top
    uut: entity work.top
        port map(
            clk => clk,
            rstn => rstn,
            uart_tx => uart_tx
        );

    -- Stimulus process
    stim_proc: process
        variable done : boolean;
    begin
        -- Reset
        rstn <= '0'; wait for 50 ns;
        rstn <= '1'; wait for 50 ns;

        -- ---------- TEST VECTOR 1 ----------
        report "TEST 1: empty payload" severity note;
        for i in 0 to 7 loop
            wb_data_out_adr <= std_logic_vector(to_unsigned(i*8, 32)); -- 64-bit RAM mapped word
            wb_data_out_dat <= payload1(i);
            wb_data_out_we  <= '1';
            wait for clk_period;
            wb_data_out_we <= '0';
        end loop;
        wb_data_out_adr <= x"40000000"; 
        wb_data_out_dat <= x"00000001";
        wb_data_out_we  <= '1'; 
        wait for clk_period;
        wb_data_out_we <= '0';
        wait until sha_ack_int = '1';
        report "TEST 1 done" severity note;

        -- ---------- TEST VECTOR 2 ----------
        report "TEST 2: 'abc' payload" severity note;
        for i in 0 to 7 loop
            wb_data_out_adr <= std_logic_vector(to_unsigned(i*8, 32));
            wb_data_out_dat <= payload2(i);
            wb_data_out_we  <= '1';
            wait for clk_period;
            wb_data_out_we <= '0';
        end loop;
        wb_data_out_adr <= x"40000000"; 
        wb_data_out_dat <= x"00000001";
        wb_data_out_we  <= '1'; 
        wait for clk_period;
        wb_data_out_we <= '0';
        wait until sha_ack_int = '1';
        report "TEST 2 done" severity note;

        report "ALL TESTS FINISHED" severity note;
        wait;
    end process;

end architecture;


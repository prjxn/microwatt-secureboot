library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.sha_256_pkg.all;

entity sha256_wb_wrapper is
  port (
    clk   : in  std_logic;
    rstn  : in  std_logic;
    addr  : in  std_logic_vector(7 downto 0);
    wdata : in  std_logic_vector(31 downto 0);
    write : in  std_logic;
    read  : in  std_logic;
    rdata : out std_logic_vector(31 downto 0);
    ack   : out std_logic;
    irq   : out std_logic
  );
end entity sha256_wb_wrapper;

architecture rtl of sha256_wb_wrapper is
  signal msg_block_in_sig : std_logic_vector(0 to (16 * WORD_SIZE) - 1) := (others => '0');
  signal hash_out_sig     : std_logic_vector((WORD_SIZE * 8) - 1 downto 0) := (others => '0');
  signal start_pulse      : std_logic := '0';
  signal finished_sig     : std_logic := '0';
  signal n_blocks_sig     : natural := 1;
  signal ack_reg  : std_logic := '0';
  signal rdata_reg: std_logic_vector(31 downto 0) := (others => '0');
begin
  process(clk)
    variable wi       : integer;
    variable ri       : integer;
    variable base_bit : integer;
  begin
    if rising_edge(clk) then
      if rstn = '0' then
        msg_block_in_sig <= (others => '0');
        hash_out_sig     <= (others => '0');
        ack_reg          <= '0';
        rdata_reg        <= (others => '0');
        start_pulse      <= '0';
        finished_sig     <= '0';
        n_blocks_sig     <= 1;
      else
        ack_reg     <= '0';
        start_pulse <= '0';
        if write = '1' then
          ack_reg <= '1';
          if addr(7 downto 4) = "0001" then
            wi := to_integer(unsigned(addr(3 downto 0)));
            if wi >= 0 and wi <= 15 then
              base_bit := wi * WORD_SIZE;
              msg_block_in_sig(base_bit to base_bit + WORD_SIZE - 1) <= wdata(WORD_SIZE - 1 downto 0);
            end if;
          elsif addr = x"00" then
            n_blocks_sig  <= 1;
            start_pulse   <= '1';
            finished_sig  <= '0';
          end if;
        end if;
        if read = '1' then
          ack_reg <= '1';
          if addr(7 downto 4) = "0100" then
            ri := to_integer(unsigned(addr(3 downto 0)));
            if ri >= 0 and ri <= 7 then
              rdata_reg <= hash_out_sig((ri * WORD_SIZE + WORD_SIZE - 1) downto (ri * WORD_SIZE));
            else
              rdata_reg <= (others => '0');
            end if;
          elsif addr = x"04" then
            rdata_reg <= (31 downto 1 => '0') & finished_sig;
          else
            rdata_reg <= (others => '0');
          end if;
        end if;
      end if;
    end if;
  end process;

  sha_inst: entity work.sha_256_core
    port map (
      clk          => clk,
      rst          => not rstn,
      data_ready   => start_pulse,
      n_blocks     => n_blocks_sig,
      msg_block_in => msg_block_in_sig,
      finished     => finished_sig,
      data_out     => hash_out_sig
    );

  rdata <= rdata_reg;
  ack   <= ack_reg;
  irq   <= finished_sig;
end architecture rtl;

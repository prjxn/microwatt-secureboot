library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

library work;
use work.wishbone_types.all;

entity top is
  port (
    clk     : in  std_logic;
    rstn    : in  std_logic;
    uart_tx : out std_logic
  );
end entity;

architecture rtl of top is
  ------------------------------------------------------------------------------
  -- SIGNALS
  ------------------------------------------------------------------------------
  signal rst : std_ulogic;

  -- Wishbone buses
  signal wb_insn_in  : wishbone_slave_out;
  signal wb_insn_out : wishbone_master_out;
  signal wb_data_in  : wishbone_slave_out;
  signal wb_data_out : wishbone_master_out;

  -- SHA peripheral interface
  signal sha_ack_int : std_logic := '0';
  signal sha_rdata   : std_logic_vector(31 downto 0) := (others => '0');
  signal sha_irq     : std_logic := '0';

  -- Address conversion helper
  signal wb_addr32 : std_logic_vector(31 downto 0) := (others => '0');

  -- Simple 8 KB memory (1024 x 64-bit)
  type ram_t is array (0 to 1023) of std_logic_vector(63 downto 0);

  -- Impure function to initialize RAM from a hex file
  impure function init_ram_from_file(filename : string) return ram_t is
    file f : text open read_mode is filename;
    variable l : line;
    variable mem : ram_t := (others => (others => '0'));
    variable i : integer := 0;
    variable word : std_logic_vector(63 downto 0);
  begin
    while not endfile(f) loop
      readline(f, l);
      hread(l, word);
      if i <= mem'high then
        mem(i) := word;
      end if;
      i := i + 1;
    end loop;
    return mem;
  end function;

  -- Initialize RAM with firmware or zeros
  -- signal ram : ram_t := (others => (others => '0'));
  signal ram : ram_t := init_ram_from_file("/workspace/firmware/firmware.hex");

begin
  ------------------------------------------------------------------------------
  -- Reset
  ------------------------------------------------------------------------------
  rst <= not rstn;

  ------------------------------------------------------------------------------
  -- Microwatt Core
  ------------------------------------------------------------------------------
  cpu: entity work.core
    generic map (
      SIM => true
    )
    port map (
      clk   => clk,
      rst   => rst,
      alt_reset => '0',
      tb_ctrl   => (others => '0'),
      wishbone_insn_in  => wb_insn_in,
      wishbone_insn_out => wb_insn_out,
      wishbone_data_in  => wb_data_in,
      wishbone_data_out => wb_data_out,
      wb_snoop_in       => wb_data_out,
      dmi_addr => (others => '0'),
      dmi_din  => (others => '0'),
      dmi_dout => open,
      dmi_req  => '0',
      dmi_wr   => '0',
      dmi_ack  => open,
      ext_irq  => sha_irq,  -- connect SHA interrupt
      msg_in   => '0',
      msg_out  => open,
      run_out  => open,
      terminated_out => open
    );

  ------------------------------------------------------------------------------
  -- Unified Memory + SHA Peripheral
  ------------------------------------------------------------------------------
  process(clk)
    variable a : integer range 0 to 1023;
  begin
    if rising_edge(clk) then
      wb_addr32 <= std_logic_vector(resize(unsigned(wb_data_out.adr), 32));

      -- Default responses
      wb_data_in.ack <= '0';
      wb_data_in.dat <= (others => '0');
      wb_insn_in.ack <= '0';
      wb_insn_in.dat <= (others => '0');

      -- Instruction fetch
      if wb_insn_out.cyc = '1' and wb_insn_out.stb = '1' then
        a := to_integer(unsigned(wb_insn_out.adr(12 downto 3)));
        if a <= ram'high then
          wb_insn_in.ack <= '1';
          wb_insn_in.dat <= ram(a);
        end if;
      end if;

      -- Data access
      if wb_data_out.cyc = '1' and wb_data_out.stb = '1' then
        a := to_integer(unsigned(wb_data_out.adr(12 downto 3)));
        if wb_addr32(31 downto 28) = "0100" then
          -- SHA region 0x40000000
          wb_data_in.ack <= sha_ack_int;
          wb_data_in.dat(31 downto 0) <= sha_rdata;
        else
          -- RAM access
          wb_data_in.ack <= '1';
          if a <= ram'high then
            if wb_data_out.we = '1' then
              ram(a) <= wb_data_out.dat;
            else
              wb_data_in.dat <= ram(a);
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- SHA-256 Peripheral wrapper
  ------------------------------------------------------------------------------
  u_sha: entity work.sha256_wb_wrapper
    port map (
      clk   => clk,
      rstn  => rstn,
      addr  => wb_addr32(7 downto 0),
      wdata => wb_data_out.dat(31 downto 0),
      write => wb_data_out.we,
      read  => wb_data_out.cyc and wb_data_out.stb and not wb_data_out.we,
      rdata => sha_rdata,
      ack   => sha_ack_int,
      irq   => sha_irq
    );

  ------------------------------------------------------------------------------
  -- UART output stub
  ------------------------------------------------------------------------------
  uart_tx <= '1';

end architecture;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
library work;
use work.MMIPS_pkg.all;
Library UNISIM;
use UNISIM.vcomponents.all;

entity MMIPS_simple is
  port (
         clk    : in  std_logic;
         reset  : in  std_logic;
         switch : in  std_logic_vector(2 downto 0);
         push   : in  std_logic;
         led    : out  std_logic_vector(3 downto 0)
       );
end MMIPS_simple;

architecture structural of MMIPS_simple is

  -- interface mémoire
  signal mem_addr    : waddr;
  signal mem_datain  : w32;
  signal mem_dataout : w32;
  signal mem_we      : std_logic;
  signal mem_ce      : std_logic;

  signal clk_in   : std_logic;
  signal clk_fb   : std_logic;
  signal dcm_lock : std_logic;
  signal rst      : std_logic;
  signal pout32   : w32;
  signal irq      : std_logic;

begin

  MMCME2_BASE_inst : MMCME2_BASE
  generic map (
                CLKFBOUT_MULT_F  => 8.0, -- facteur multiplicatif horloge
                CLKIN1_PERIOD    => 8.0, -- horloge entrante à 125MHz
                CLKOUT0_DIVIDE_F => 20.0, --facteur de division horloge
                REF_JITTER1      => 0.010)
  port map (
             CLKOUT0  => clk_in,
             LOCKED   => dcm_lock,
             CLKFBOUT => clk_fb,
             CLKFBIN  => clk_fb,
             CLKIN1   => clk,
             PWRDWN   => '0',
             RST      => '0'
           );
  rst <= reset or not dcm_lock;

  C_PROCESSEUR: MMIPS_CPU
  port map(
            clk         => clk_in,
            rst         => rst,
            irq         => irq,
            mem_addr    => mem_addr,
            mem_datain  => mem_datain,
            mem_dataout => mem_dataout,
            mem_we      => mem_we,
            mem_ce      => mem_ce,
            pout        => pout32
          );

  sel_led : process(pout32, switch)
  begin
    led <= pout32((conv_integer(switch)+1)*4-1 downto conv_integer(switch)*4);
  end process sel_led;

  C_RAM_PROG : RAM_PROG
  port map(
            clk  => clk_in,
            addr => mem_addr(12 downto 2),
            do   => mem_datain,
            di   => mem_dataout,
            ce   => mem_ce,
            we   => mem_we
          );

  C_ITPush : IP_ITPush
  port map(
            clk  => clk_in,
            rst  => rst,
            -- io
            push => push,
            irq  => irq
          );

end structural;


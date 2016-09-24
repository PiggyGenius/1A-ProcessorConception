library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.MMIPS_pkg.all;
Library UNISIM;
use UNISIM.vcomponents.all;

entity MMIPS_complet is
  port (
         clk    : in  std_logic;
         reset  : in  std_logic;
         switch : in  std_logic_vector(3 downto 0);
         push   : in  std_logic_vector(2 downto 0);
         led    : out  std_logic_vector(3 downto 0);
         R      : out  unsigned(4 downto 0);
         G      : out  unsigned(5 downto 0);
         B      : out  unsigned(4 downto 0);
         HS     : out  std_logic;
         VS     : out  std_logic
       );
end MMIPS_complet;

architecture structural of MMIPS_complet is
  component IP_LED
    port (
           clk   : in std_logic;
           rst   : in std_logic;
           -- bus
           WE    : in std_logic;
           CE    : in std_logic;
           AD    : in waddr;
           DataI : in w32;
           DataO : out w32;
           -- IO
           LED   : out std_logic_vector(3 downto 0)
         );
  end component IP_LED ;
  component IP_PIN
    port (
           clk   : in std_logic;
           rst   : in std_logic;
           -- bus
           we    : in std_logic;
           ce    : in std_logic;
           ad    : in waddr;
           datai : in w32;
           datao : out w32;
           -- io
           pin   : in w32
         );
  end component IP_PIN ;

  component IP_Timer
    port (
           clk   : in std_logic;
           rst   : in std_logic;
           -- bus
           we    : in std_logic;
           ce    : in std_logic;
           ad    : in waddr;
           datai : in w32;
           datao : out w32
         );
  end component IP_Timer ;

  component IP_VGA
    port (
           clk_bus : in std_logic;
           clk_io  : in std_logic;
           rst     : in std_logic;
           -- bus
           we      : in std_logic;
           ce      : in std_logic;
           ad      : in waddr;
           datai   : in w32;
           datao   : out w32;
           -- io
           R       : out  unsigned(4 downto 0);
           G       : out  unsigned(5 downto 0);
           B       : out  unsigned(4 downto 0);
           hs      : out std_logic;
           vs      : out std_logic
         );
  end component IP_VGA ;
  component MMIPS_bus
      generic (
      nCE       : integer;
      base      : waddr_vec;
      high      : waddr_vec
  );
  port (
           clk       : in std_logic;
           rst       : in std_logic; 

           cpu_ce    : in std_logic;
           cpu_we    : in std_logic;
           cpu_addr  : in waddr;
           cpu_datao : in w32;
           cpu_datai : out w32;

           ce        : out std_logic_vector(0 to nce-1);
           we        : out std_logic_vector(0 to nce-1);
           datai     : in w32_vec(0 to nce-1)
       );
  end component MMIPS_bus ;

  signal mem_addr    :  waddr;
  signal mem_datain  :  w32;
  signal mem_dataout :  w32;
  signal mem_we      :  std_logic;
  signal mem_ce      :  std_logic;

  constant nCE       : integer := 5;

  signal bus_ce, bus_we : std_logic_vector(0 to nce-1);
  signal bus_datai      : w32_vec(0 to nce-1);

  signal push_tmp    :  w32;
  signal clk_gen,clk_gen1, clk_proc, clk_vga, clk_fb, dcm_lock, rst :  std_logic;

begin

  MMCME2_BASE_inst : MMCME2_BASE
  generic map (
                CLKFBOUT_MULT_F  => 8.0,
                CLKIN1_PERIOD    => 8.0, -- horloge entrante à 125MHz
                CLKOUT0_DIVIDE_F => 20.0,
                CLKOUT1_DIVIDE   => 10,
                REF_JITTER1      => 0.010
              )
  port map (
             CLKOUT0  => clk_gen,-- horloge sortante à 125x8/20=50MHz
             CLKOUT1  => clk_gen1,-- horloge sortante à 125x8/10=100MHz
             LOCKED   => dcm_lock,
             CLKFBOUT => clk_fb,
             CLKFBIN  => clk_fb,
             CLKIN1   => clk,
             PWRDWN   => '0',
             RST      => '0'
           );

  rst <= reset or not dcm_lock;
  BUFG_proc : BUFG port map ( O => clk_proc, I => clk_gen );
  BUFG_vga : BUFG port map ( O => clk_vga, I => clk_gen1 );

  C_PROC: MMIPS_CPU
  port map(
            clk         => clk_proc,
            rst         => rst,
            irq         => '0',
            mem_addr    => mem_addr,
            mem_datain  => mem_datain,
            mem_dataout => mem_dataout,
            mem_we      => mem_we,
            mem_ce      => mem_ce,
            pout        => open,
            pout_valid  => open
          );

  -- MEM_PROG led sw&push timer MEM_video
  C_bus : MMIPS_bus
  generic map(
               nCE => nCE,
               -- A MODIFIER
               base => (x"000000",  x"004000",
               x"004004", x"004010",  x"080000"
               ),
               high => (x"001FFF",x"004003",
                        x"004007",  x"004017", x"0CAFFF"
               )
             )
  port map(
            clk       => clk_proc,
            rst       => rst,
            cpu_ce    => mem_ce,
            cpu_we    => mem_we,
            cpu_addr  => mem_addr,
            cpu_datao => mem_dataout,
            cpu_datai => mem_datain,
            ce        => bus_ce,
            we        => bus_we,
            datai     => bus_datai
          );

  C_RAM_PROG: RAM_PROG
  port map(
            clk  => clk_proc,

            addr => mem_addr(12 downto 2),
            do   => bus_datai(0),
            di   => mem_dataout,
            ce   => bus_ce(0),
            we   => bus_we(0)

          );

  C_LED: IP_LED
  port map(
            clk   => clk_proc,
            rst   => rst,
            -- bus
            we    => bus_we(1),
            ce    => bus_ce(1),
            ad    => mem_addr,
            datai => mem_dataout,
            datao => bus_datai(1),
            -- io
            led   => led
          );

  C_SWITCH: IP_PIN
  port map(
            clk   => clk_proc,
            rst   => rst,
            -- bus
            we    => bus_we(2),
            ce    => bus_ce(2),
            ad    => mem_addr,
            datai => mem_dataout,
            datao => bus_datai(2),
            -- io
            pin   => push_tmp
          );
  push_tmp  <= X"000" & "0" & push & X"000" & switch;

  C_TImer: IP_Timer
  port map(
            clk   => clk_proc,
            rst   => rst,
            -- bus
            we    => bus_we(3),
            ce    => bus_ce(3),
            ad    => mem_addr,
            datai => mem_dataout,
            datao => bus_datai(3)
          );

  C_VGA: IP_VGA
  port map(
            clk_bus   => clk_proc,
            clk_io   => clk_vga,
            rst   => rst,
            -- bus
            we    => bus_we(4),
            ce    => bus_ce(4),
            ad    => mem_addr,
            datai => mem_dataout,
            datao => bus_datai(4),
            -- io
            r => r,
            g => g,
            b => b,
            hs => hs,
            vs => vs
          );

end structural;

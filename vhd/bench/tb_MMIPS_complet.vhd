library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
library work;

entity tb_mmips_complet  is
end tb_mmips_complet ;

architecture behavior of tb_mmips_complet is 

  component MMIPS_complet
    port (
      clk       : in  std_logic;
      reset     : in  std_logic;

      switch    : in  std_logic_vector(7 downto 0);
      push      : in  std_logic_vector(2 downto 0);
      led       : out  std_logic_vector(7 downto 0);
      seg       : out  std_logic_vector(7 downto 0);
      seg_an    : out  std_logic_vector(3 downto 0);

      R         : out  STD_LOGIC;
      G         : out  STD_LOGIC;
      B         : out  STD_LOGIC;
      HS        : out  STD_LOGIC;
      VS        : out  STD_LOGIC
      );
  end component;

  signal clk    :  std_logic:='0';
  signal reset  :  std_logic;
  signal switch :  std_logic_vector(7 downto 0);
  signal push   :  std_logic_vector(2 downto 0);
  signal led    :  std_logic_vector(7 downto 0);
  signal seg    :  std_logic_vector(7 downto 0);
  signal seg_an :  std_logic_vector(3 downto 0);

  signal R      :  STD_LOGIC;
  signal G      :  STD_LOGIC;
  signal B      :  STD_LOGIC;
  signal HS     :  STD_LOGIC;
  signal VS  :  STD_LOGIC;
  
begin

  C_MMIPS_IO : MMIPS_complet
    port map(
      clk => clk ,
      reset => reset ,
      switch    => switch    ,
      push      => push      ,
      led       => led       ,
      seg       => seg       ,
      seg_an    => seg_an    ,

      R         => R         ,
      G         => G         ,
      B         => B         ,
      HS        => HS        ,
      VS        => VS        
      );
  
  process 
  begin
    clk<='1';
    wait for 10 ns;
    clk<='0';
    wait for 10 ns;
  end process;

  
  tb : process
  begin
    reset<='1';
    switch<=x"03";
    push<="010";
    for i in 1 to 6 loop    
      wait until rising_edge(clk);
    end loop;
    reset<='0';   
    switch<=x"06";
    push<="111";
    for i in 0 to 10 loop    
      wait until rising_edge(clk);
      switch <= switch + 1 ; 
    end loop;

    -- place stimulus here

    wait; -- will wait forever
  end process;

end;

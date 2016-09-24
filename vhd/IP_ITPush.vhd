library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.MMIPS_pkg.all;

entity IP_ITpush is
  port (
         clk  : in std_logic;
         rst  : in std_logic;
         -- io
         push : in std_logic;
         irq  : out std_logic
       );
end IP_ITpush;

architecture RTL of IP_ITpush is

  signal delai1 : std_logic;
  signal delai2 : std_logic;
  signal compteur: std_logic_vector(3 downto 0);

begin
  process (clk)
  begin
    if rst = '1' then
      delai1 <= '0';
      delai2 <= '0';
    elsif rising_edge(clk) then
      delai1 <= push;
      delai2 <= delai1;
    end if;
  end process;

  process (clk)
  begin
    if rst = '1' then
      compteur <= B"0000";
    elsif rising_edge(clk) then
      if ((not(push) and not(delai1) and delai2) = '1') then
        compteur <= X"F";
      elsif compteur /= 0 then
        compteur <= compteur - 1;
      end if;
    end if;
  end process;

  irq <= '1' when (compteur /= 0) else '0';

end RTL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.MMIPS_pkg.all;

entity IP_LED is
    port (
             clk : in std_logic;
             rst: in std_logic; 
    -- bus
             we : in std_logic;
             ce : in std_logic;
             ad : in waddr;
             datai : in w32;
             datao : out w32;
    -- io
             led : out std_logic_vector(3 downto 0)
         );
end IP_LED ;

architecture RTL of IP_LED  is



begin

    synchrone: process (clk)
    begin
        if clk'event and clk='1' then
            if (rst='1') then 
                led <= (others => '0');
            elsif ( ce='1' and we='1') then
                led <= datai(3 downto 0); 
            end if;
        end if;
    end process synchrone;

    datao <= (others=>'0');


end RTL;

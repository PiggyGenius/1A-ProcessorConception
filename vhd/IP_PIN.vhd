library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.MMIPS_pkg.all;

entity IP_PIN is
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
             pin : in w32
         );
end IP_PIN ;

architecture RTL of  IP_PIN is

    signal data_q: w32;


begin
    synchrone : process(clk)
    begin
        if rising_edge(clk) then
            if rst='1' then
                data_q <= (others=>'0');
                datao <= (others=>'0');
            else
                data_q <= pin;
                datao <= data_q;
            end if;
        end if;
    end process synchrone;

end RTL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.MMIPS_pkg.all;

entity MMIPS_bus is
  generic (
    nCE : integer;
    base : waddr_vec;
    high  : waddr_vec
    );
  port (
    clk : in std_logic;
    rst: in std_logic; 

    CPU_CE : in std_logic;
    CPU_WE : in std_logic;
    CPU_ADDR : in waddr;
    CPU_DataO : in w32;
    CPU_DataI : out w32;

    CE : out std_logic_vector(0 to nCE-1);
    WE : out std_logic_vector(0 to nCE-1);
    DataI : in w32_vec(0 to nCE-1)
    );
end MMIPS_bus ;

architecture RTL of  MMIPS_bus is
  signal ce_d, ce_q : std_logic_vector(0 to nCE-1);

begin
---------------------------------------------------
  C_enable: process(CPU_CE, CPU_ADDR, CPU_WE)
  begin
    for i in 0 to nCE-1 loop
      if CPU_CE='1' and (CPU_ADDR>=base(i) and CPU_ADDR<=high(i)) then
	ce_d(i) <= '1';
	we(i)  <= CPU_WE;
      else
	ce_d(i) <= '0';
        we(i)  <= '0';
      end if;
    end loop;  -- i
  end PROCESS ;
  ce <= ce_d;
---------------------------------------------------
  synchrone : process (CLK)
  begin
    if clk'event and clk='1' then 
      ce_q <= ce_d;
    end if;
  end process synchrone;

---------------------------------------------------
  Acces_lecture: process (ce_d, ce_q, DataI)
    variable v,r : w32;
  begin
    r := (others=>'0');
    for i in 0 to nCE-1 loop
      v := (others=>'0');
      if ce_q(i)='1' then
	v := DataI(i);
      end if;
      r:= r or v;
    end loop;
    CPU_DataI <= r;
  end PROCESS Acces_lecture;
  
end RTL;

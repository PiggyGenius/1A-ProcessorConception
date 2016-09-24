library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library work;
use work.MMIPS_pkg.all;

entity MMIPS_CPU is
  port (
    clk         : in  std_logic;
    rst         : in  std_logic;

    irq         : in  std_logic;
    
    mem_addr    : out  waddr;
    mem_datain  : in   w32;
    mem_dataout : out w32;
    mem_we      : out  std_logic;
    mem_ce      : out  std_logic;
    
--  debug
    pout        : out  w32;
    pout_valid  : out boolean
    );
end MMIPS_CPU;

architecture RTL of MMIPS_CPU is
  signal cmd     :  MMIPS_PO_CMD;
  signal status :  MMIPS_PO_STATUS;

begin
  PC : MMIPS_CPU_PC
    Port map(
      clk    => clk,
      rst    => rst,
      cmd    => cmd,
      status => status 
      );
  
  PO :  MMIPS_CPU_PO
    port map (
      clk         => clk,
      rst         => rst,

      
      cmd         => cmd,
      status      => status,

      irq         => irq,
      
      mem_addr    => mem_addr,
      mem_datain  => mem_datain,
      mem_dataout => mem_dataout,
      mem_we      => mem_we,
      mem_ce      => mem_ce,

      pout        => pout,
      pout_valid  => pout_valid        
      );

end RTL;

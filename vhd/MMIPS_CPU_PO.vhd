library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;
library work;
use work.MMIPS_pkg.all;

entity MMIPS_CPU_PO is
  port (
    clk         : in  std_logic;
    rst         : in  std_logic;
    
    cmd         : in MMIPS_PO_CMD;
    status      : out MMIPS_PO_STATUS;

    irq         : in  std_logic;
    
    mem_addr    : out  waddr;
    mem_datain  : in   w32;
    mem_dataout : out  w32;
    mem_we      : out  std_logic;
    mem_ce      : out  std_logic;
    
--  debug
    pout        : out  w32;
    pout_valid : out boolean
    );
end MMIPS_CPU_PO;

architecture RTL of MMIPS_CPU_PO is
  type register_file_type is array (natural range 0 to RF_nb-1) of w32;
  constant register_file_type_zero :register_file_type := (others=>w32_zero);


-- Registres PO
  signal RF_d, RF_q : register_file_type;  -- banc de registres
  signal PC_d, PC_q : w32;
  
  signal AD_d, AD_q : w32;
  signal DT_d, DT_q : w32;
  signal IR_d, IR_q : w32;

-- A MODIFIER POUR GESTION IT
  signal EPC_d, EPC_q : w32;
  signal IRQ_d,IRQ_q : std_logic;
  signal SR_d, SR_q : boolean;
-- A MODIFIER POUR GESTION IT

-- Chemin de donnee PO 
  signal x, y, alu_res : w32;
  signal pout_d, pout_q : w32;
  signal pout_valid_d, pout_valid_q : boolean;
begin
  
    IRQ_d <= irq;

  synchrone : process (CLK)
  begin
    if clk'event and clk='1' then 
      if rst ='1' then 
        PC_q <= w32_zero;
        RF_q <= register_file_type_zero;
        AD_q <= w32_zero;
        DT_q <= w32_zero;
        IR_q <= w32_zero;

-- A MODIFIER POUR GESTION IT
        EPC_q <= w32_zero;
        IRQ_q <= '0';
        SR_q <= true;
-- A MODIFIER POUR GESTION IT

        pout_q <= (others=>'0');
        pout_valid_q <= false;
      else
        PC_q <= PC_d;
        RF_q <= RF_d;
        RF_q(0) <= w32_zero;
        AD_q <= AD_d;
        DT_q <= DT_d;
        IR_q <= IR_d;
	
-- A MODIFIER POUR GESTION IT
        EPC_q <= EPC_d;
        IRQ_q <= IRQ_d;
        SR_q <= SR_d;
-- A MODIFIER POUR GESTION IT

        pout_q <= pout_d;
        pout_valid_q <= pout_valid_d;
      end if;
    end if;
  end process synchrone;
  pout <= pout_q;
  pout_valid <= pout_valid_q;

  comb_MUX : process ( PC_q,
                       RF_q,
                       AD_q,
                       DT_q,
                       IR_q,
		       -- A MODIFIER POUR GESTION IT
                       EPC_q,
                       SR_q,
                       IRQ_q,
               -- A MODIFIER POUR GESTION IT 
                       pout_q, 
                       pout_valid_q, 
                       cmd,
                       alu_res,
                       mem_datain)
    variable rf_dest : integer range 0 to alu_res'length-1;
  begin
    -- les registres prennent leur ancienne valeur par defaut
    PC_d <= PC_q;
    RF_d <= RF_q;
    AD_d <= AD_q;
    DT_d <= DT_q;
    IR_d <= IR_q;
    -- A MODIFIER POUR GESTION IT
    EPC_d <= EPC_q;
    SR_d <= SR_q;
    IRQ_d <= IRQ_q;
    -- A MODIFIER POUR GESTION IT
    pout_d <= pout_q;
    pout_valid_d <= false;
    
    -- la selection des operandes se fait a l'aide de types enumeres
    -- qui seront "transformes" en signaux binaires par l'outil de synthese logique
    -- selection de l'entree X sur l'UAL
    x <= w32_zero;                      -- valeur par defaut
    case cmd.ALU_X_sel is
      when UXS_RF_RS =>
        x <= RF_q(conv_integer(unsigned(IR_q(25 downto 21))));
      when UXS_PC =>
        x <= PC_q;
      when UXS_EPC =>
	-- A MODIFIER POUR GESTION IT
          x <= EPC_q;
	-- A MODIFIER POUR GESTION IT
      when UXS_DT =>
        x <= DT_q;
      when UXS_cst_x00 =>
        x <= x"00000000";
      when UXS_cst_x01 =>
        x <= x"00000001";
      when UXS_cst_x10 =>
        x <= x"00000010";
      when UXS_IT_vec =>
        x <= x"00001FFC";
      when UXS_PC_up =>
        x(31 downto 28) <= PC_q(31 downto 28);
      when UXS_IR_SH =>
        x(4 downto 0) <= IR_q(10 downto 6);
      when others => null;
    end case;
    -- selection de l'entree Y sur l'UAL
    y <= w32_zero;      -- valeur par defaut
    case cmd.ALU_Y_sel is
      when UYS_RF_RT =>
      	y <= RF_q(conv_integer(unsigned(IR_q(20 downto 16))));

      when UYS_IR_imm16 =>
        y(15 downto 0) <= IR_q(15 downto 0);
        
      when UYS_IR_imm16_ext =>
        y <= (others=>IR_q(15));
        y(15 downto 0) <= IR_q(15 downto 0);
        
      when UYS_IR_imm16_ext_up =>
        y <= (others=>IR_q(15));
        y(17 downto 2) <= IR_q(15 downto 0);
        y(1 downto 0) <= "00";
     	
      when UYS_IR_imm26 =>
      	y(27 downto 2) <= IR_q(25 downto 0);
        
      when UYS_cst_x00 =>
      	y <= x"00000000";
        
      when UYS_cst_x04  =>
      	y <= x"00000004";
        
      when others=> null;
    end case;

-- mise a jour des registres par leur nouvelle valeur selon les WE
    
    if cmd.PC_we then
      PC_d <= alu_res;
    end if;

-- selection du numero du registre destination selon RF_sel
    rf_dest := 0;
    if cmd.RF_we then
      case cmd.RF_sel is
        when RFS_RD =>
          rf_dest := conv_integer(unsigned(IR_q(15 downto 11)));
        when RFS_RT => 
          rf_dest := conv_integer(unsigned(IR_q(20 downto 16)));	  
        when RFS_31 =>
          rf_dest :=31;
        when others => null;
      end case;
-- met le registre a jour
      RF_d(rf_dest) <= alu_res;
-- sort le registre 28
      if rf_dest=28 then
        pout_d <= alu_res;
        pout_valid_d <= true;
      end if;      
    end if;
    
    if cmd.AD_we then
      AD_d <= alu_res;
    end if;
    
    if cmd.DT_we then
      DT_d <= mem_datain;
    end if;
    
    if cmd.IR_we then
      IR_d <= mem_datain;
    end if;
-- selection de l'origine de l'adresse vers la memoire
    case cmd.ADDR_sel is
      when ADDR_from_AD =>
	mem_addr <= AD_q(mem_addr'high downto 0);
      when ADDR_from_PC =>
	mem_addr <= PC_q(mem_addr'high downto 0);
    end case;
-- recopie des signaux de controle de la memoire (et change les types)
    if cmd.mem_ce then
      mem_ce <= '1';
    else
      mem_ce <= '0';
    end if;
    if cmd.mem_we then
      mem_we <= '1';
    else
      mem_we <= '0';
    end if; 
-- A MODIFIER POUR GESTION IT
    if cmd.epc_we then
        EPC_d <= alu_res;
    end if;
    if cmd.sr_set then
        SR_d <= true;
    end if;
    if cmd.sr_rst then
        SR_d <= false;
    end if;
-- A MODIFIER POUR GESTION IT
  end process comb_MUX;

  comb_ALU : process (IR_q, x, y, cmd 
)
    variable res : std_logic_vector(32 downto 0);
  begin  
    alu_res <= w32_zero;
    res := (others=>'0');
    -- selection de l'operation effectuee par l'UAL
    case cmd.ALU_OP is
      when AO_plus =>
        res := unsigned((x(31) and cmd.ALU_extension_signe) & x) + unsigned((y(31) and cmd.ALU_extension_signe) & y);
      when AO_moins =>
        res := unsigned((x(31) and cmd.ALU_extension_signe) & x) - unsigned((y(31)  and cmd.ALU_extension_signe) & y);
      when AO_and =>
      	res := '0'& (x and y);
      when AO_or =>
        res := '0'& (x or y);
      when AO_xor =>
        res := '0'& (x xor y);
      when AO_nor =>
        res := '0'& (not(x or y));
      when AO_SLL =>
        res := std_logic_vector(SHL(unsigned('0' &y), unsigned(x(4 downto 0))));
      when AO_SRL =>
        res := '0' & (std_logic_vector(SHR(unsigned(y), unsigned(x(4 downto 0)))));
      when AO_SRA =>
        res := '0' & (std_logic_vector(SHR(signed(y), unsigned(x(4 downto 0)))));
      when others => null;
    end case;
    -- test du resultat de l'UAL
    alu_res <= res(31 downto 0);
    status.c <= res(32)='1';
    status.z <= unsigned(res)=0;
    status.s <= res(31)='1';
    status.IR <= IR_q;
-- A MODIFIER POUR GESTION IT
    status.it <= (IRQ_q='1') and SR_q;
-- A MODIFIER POUR GESTION IT
  end process comb_ALU;

  mem_dataout <= alu_res;
  
end RTL;

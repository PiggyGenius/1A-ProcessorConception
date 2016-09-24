library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

package MMIPS_pkg is

    constant mode_synthese : boolean := true
                                      -- synthesis translate_off
    and false
                                      -- synthesis translate_on
    ;
    constant val_simu : integer := 0
                                 -- synthesis translate_off
    + 1
                                 -- synthesis translate_on
    ;
    subtype w32 is std_logic_vector(31 downto 0);
    subtype waddr is std_logic_vector(23 downto 0);

    type int_vec is array (natural range <>)  of integer;
    type w32_vec is array (natural range <>) of w32;
    type waddr_vec is array (natural range <>) of waddr;

    constant w32_zero : w32 := (others=>'0');


    constant RF_nb : integer := 32;
    constant RF_b : integer := 5;
    constant UAL_op_b : integer := 4;


    type UXS_type is ( -- 4
    UXS_RF_RS,      -- 0000
    UXS_PC,         -- 0001
    UXS_EPC,        -- 0010
    UXS_DT,         -- 0011
    UXS_cst_x00,    -- 1000
    UXS_cst_x01,    -- 1001
    UXS_cst_x10,    -- 1010
    UXS_IT_vec,     -- 1011
    UXS_PC_up,      -- 1100
    UXS_IR_SH       -- 1101
);

constant UXS_type_zero :UXS_type :=UXS_RF_RS;


type UYS_type is   (   -- 3
UYS_IR_imm16,       -- 000
UYS_IR_imm16_ext,   -- 001
UYS_IR_imm16_ext_up,-- 011
UYS_IR_imm26,       -- 010
UYS_RF_RT,          -- 100
UYS_cst_x00,        -- 110
UYS_cst_x04         -- 111
    );  

    constant UYS_type_zero : UYS_type := UYS_IR_imm16;


    type AO_type is (     -- 4
    AO_plus,            -- 000-                          
    AO_moins,           -- 001-
    AO_and,             -- 0100
    AO_or,              -- 0101
    AO_xor,             -- 0110
    AO_nor,             -- 0111
    AO_SLL,             -- 100-
    AO_SRL,             -- 1010
    AO_SRA              -- 1011
);

constant AO_type_zero : AO_type := AO_plus;


type RF_sel_type is (                 -- 2
RFS_RD,                             -- 00
RFS_RT,                             -- 01
RFS_31                              -- 10
    );


    constant RF_sel_type_zero : RF_sel_type := RFS_RD;

    type ADDR_select is (  		-- 1
    ADDR_from_PC,  			-- 0	
    ADDR_from_AD  			-- 1	
) ;
constant ADDR_select_zero : ADDR_select := ADDR_from_PC;
type MMIPS_PO_cmd is record
    rst : std_logic;
    -- selection register file
    ALU_X_Sel : UXS_type;
    ALU_Y_Sel : UYS_type;
    ALU_OP    : AO_type;
    ALU_extension_signe : std_logic;
    RF_Sel    : RF_sel_type;
    RF_we     : boolean;

    PC_we     :  boolean;

    AD_we     :  boolean;
    DT_we     :  boolean;
    IR_we     :  boolean;
    -- A MODIFIER POUR GESTION IT
    epc_we    :  boolean;
    sr_set    :  boolean;
    sr_rst    :  boolean;
    -- A MODIFIER POUR GESTION IT

    ADDR_sel  : ADDR_select;
    mem_we       :  boolean ;
    mem_ce       :  boolean ;
end record;

type MMIPS_PO_status is record
    IR : w32;
    it,s,z,c : boolean;
    -- A MODIFIER POUR GESTION IT
    -- Ajout de it
end record;

  -- zero definition debut

constant MMIPS_PO_cmd_zero : MMIPS_PO_cmd := 
(
rst                 => '0',
      -- selection register file
ALU_X_Sel           => UXS_type_zero,
ALU_Y_Sel           => UYS_type_zero,
ALU_OP              => AO_type_zero,
ALU_extension_signe => '0',

RF_Sel              => RF_sel_type_zero,
RF_we               => false,

PC_we               => false,

AD_we               => false,
DT_we               => false,
IR_we               => false,
      -- A MODIFIER POUR GESTION IT
EPC_we              => false,
SR_set              => false,
SR_rst              => true,
      -- A MODIFIER POUR GESTION IT
ADDR_sel            => ADDR_from_PC,
mem_we              => false,
mem_ce       => false
      );
      constant MMIPS_PO_status_zero : MMIPS_PO_status := 
      (
      IR => w32_zero,
      s  => false,
      z  => false,
      c  => false,
      -- A MODIFIER POUR GESTION IT
      it => false
      -- A MODIFIER POUR GESTION IT
  );
  -- zero definition fin


  component RAM_PROG    
      port ( 
               clk  : in    std_logic;

               addr : in    std_logic_vector(10 downto 0); 
               do   : out   w32;
               di   : in   w32;
               ce   : in   std_logic;
               we   : in   std_logic
           ); 
  end component;

  component IP_ITPush
      port (
               clk  : in std_logic;
               rst  : in std_logic;
               push : in std_logic;
               irq  : out std_logic
           );
  end component IP_ITPush;


  component MMIPS_CPU
      port (
               clk         : in  std_logic;
               rst       : in  std_logic;

               irq         : in  std_logic;

               mem_addr    : out  waddr;
               mem_datain  : in  w32;
               mem_dataout : out  w32;
               mem_we      : out  std_logic;
               mem_ce      : out  std_logic;

      --debug
               pout        : out  w32;
               pout_valid : out boolean
           );
  end component;

  component MMIPS_CPU_PC 
      port (
               clk    : in  STD_LOGIC;
               rst    : in  STD_LOGIC;
               cmd    : out MMIPS_PO_cmd;
               status : in MMIPS_PO_status
           );
  end component MMIPS_CPU_PC;
  component   MMIPS_CPU_PO
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

      -- debug
               pout        : out  w32;
               pout_valid  : out boolean
           );
  end component MMIPS_CPU_PO;


end MMIPS_pkg;

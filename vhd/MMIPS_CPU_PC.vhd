library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
library work;
use work.MMIPS_pkg.all;

entity MMIPS_CPU_PC is
  Port (
    clk    : in  STD_LOGIC;
    rst    : in  STD_LOGIC;
    cmd    : out MMIPS_PO_cmd;
    status : in MMIPS_PO_status
    );
end MMIPS_CPU_PC;

architecture RTL of MMIPS_CPU_PC is
  type State_type is (S_Error,
                      S_Init,
                      S_Fetch_wait,
                      S_Fetch,
                      S_Decode,
                      S_Ori,
                      S_Lui,
                      S_Add,
                      S_Sll,
                      S_Addi,
                      S_Addu,
                      S_Addiu,
                      S_And,
                      S_Andi,
                      S_Nor,
                      S_Or,
                      S_Xor,
                      S_Xori,
                      S_Sub,
                      S_Subu,
                      S_Sllv,
                      S_Srl,
                      S_Sra,
                      S_Srav,
                      S_Srlv,
                      S_J,
                      S_Beq,
                      S_B2,
                      S_Bne,
                      S_Blez,
                      S_Bgtz,
                      S_Bgez,
                      S_Bltz,
                      S_Jr,
                      S_Jal,
                      S_Jalr,
                      S_Bltzal,
                      S_Bgezal,
                      S_Lw,
                      S_Lw2,
                      S_Lw3,
                      S_Lw4,
                      S_Sw,
                      S_Sw2,
                      S_Slt,
                      S_Slti,
                      S_Sltu,
                      S_Sltiu,
                      S_Slt0,
                      S_Slt1,
                      S_Slt0t,
                      S_Slt1t,
                      S_It,
                      S_It2,
                      S_Eret
                      );

  signal state_d, state_q : State_type;

begin
  FSM_synchrone : process(clk)
  begin
    if clk'event and clk='1' then
      if rst='1' then
        state_q <= S_Init;
      else
        state_q <= state_d;
      end if;
    end if;
  end process FSM_synchrone;

  FSM_comb : process (state_q, status)
  begin
    state_d <= state_q;
    cmd <= MMIPS_PO_cmd_zero;
    case state_q is
      
      when S_It =>
        cmd.mem_ce<=true;
        cmd.EPC_we<=true;
        cmd.SR_rst<=true;
        cmd.ALU_X_Sel<=UXS_PC;
        cmd.ALU_Y_Sel<=UYS_cst_x00;
        state_d<=S_It2;
      when S_It2 =>
        cmd.mem_ce<=true;
        cmd.PC_we<=true;
        cmd.ALU_X_Sel<=UXS_IT_vec;
        cmd.ALU_Y_Sel<=UYS_cst_x00;
        cmd.ALU_OP<=AO_Plus;
        state_d<=S_Fetch_wait;
      when S_Error =>
        state_d <= S_Error; 
      when S_Init =>
      -- PC <- 0
        cmd.ALU_X_sel <= UXS_cst_x00;
        cmd.ALU_Y_sel <= UYS_cst_x00;
        cmd.ALU_OP <= AO_plus;
        cmd.PC_we <= true;
        state_d <= S_Fetch_wait;

      when S_Fetch_wait =>
        cmd.mem_ce <= true;
        state_d <= S_Fetch;

      when S_Fetch =>
      -- IR <- mem[PC]
        if status.it then
            state_d <= S_It;
        else
            cmd.IR_we <= true;
            state_d <= S_Decode;
        end if;

      when S_Decode =>	
      -- PC <- PC + 4
        cmd.ALU_X_sel <= UXS_PC;
        cmd.ALU_Y_sel <= UYS_cst_x04;
        cmd.ALU_OP <= AO_plus;
        cmd.PC_we <= true;
        state_d <= S_Init;
        case status.IR(31 downto 29) is 
            when "001" =>
                case status.IR(28 downto 26) is
                    when "101" => 
                        state_d <= S_Ori;
                    when "000" =>
                        state_d <= S_Addi;
                    when "100" =>
                        state_d <= S_Andi;
                    when "001" =>
                        state_d <= S_Addiu;
                    when "010" =>
                        state_d <= S_Slti;
                    when "011" =>
                        state_d <= S_Sltiu;
                    when "111" => 
                        state_d <= S_Lui;
                    when "110" =>
                        state_d <= S_Xori;
                    when others => null;
                end case;
            when "000" =>
                case status.IR(28 downto 26) is
                    when "000" =>
                        case status.IR(5 downto 3) is
                            when "100" =>
                                case status.IR(2 downto 0) is
                                    when "000" =>
                                        state_d <= S_Add;
                                    when "001" =>
                                        state_d <= S_Addu;
                                    when "011" =>
                                        state_d <= S_Subu;
                                    when "010" =>
                                        state_d <= S_Sub;
                                    when "100" =>
                                        state_d <= S_And;
                                    when "101" =>
                                        state_d <= S_Or;
                                    when "111" =>
                                        state_d <= S_Nor;
                                    when "110" =>
                                        state_d <= S_Xor;
                                    when others => null;
                                end case;
                            when "000" =>
                                case status.IR(2 downto 0) is
                                    when "000" =>
                                        state_d <= S_Sll;
                                    when "100" =>
                                        state_d <= S_Sllv;
                                    when "010" =>
                                        state_d <= S_Srl;
                                    when "011" =>
                                        state_d <= S_Sra;
                                    when "111" =>
                                        state_d <= S_Srav;
                                    when "110" =>
                                        state_d <= S_Srlv;
                                    when others => null;
                                end case;
                            when "101" =>
                                case status.IR(2 downto 0) is
                                    when "010" =>
                                        state_d <= S_Slt;
                                    when "011" =>
                                        state_d <= S_Sltu;
                                    when others => null;
                                end case;
                            when "001" =>
                                case status.IR(2 downto 0) is
                                    when "001" =>
                                        state_d <= S_Jalr;
                                    when "000" =>
                                        state_d <= S_Jr;
                                    when others => null;
                                end case;
                            when others => null; 
                        end case;
                    when "001" =>
                        case status.IR(20 downto 16) is
                            when "00000" => 
                                state_d <= S_Bltz;
                            when "00001" =>
                                state_d <= S_Bgez;
                            when "10000" =>
                                state_d <= S_Bltzal;
                            when "10001" =>
                                state_d <= S_Bgezal;
                            when others => null;
                        end case;
                    when "100" =>
                        state_d <= S_Beq;
                    when "101" =>
                        state_d <= S_Bne;
                    when "110" =>
                        state_d <= S_Blez;
                    when "111" =>
                        state_d <= S_Bgtz;
                    when "010" =>
                        state_d <= S_J;
                    when "011" =>
                        state_d <= S_Jal;
                    when others => null;
                end case;
            when "010" =>
                case status.IR(28 downto 26) is
                    when "000" =>
                        case status.IR(5 downto 0) is
                            when "011000" =>
                                state_d <= S_Eret;
                            when others => null;
                        end case;
                    when others => null;
                end case;
            when "100" =>
                case status.IR(28 downto 26) is
                    when "011" =>
                        state_d <= S_Lw;
                    when others => null;
                end case;
            when "101" =>
                case status.IR(28 downto 26) is
                    when "011" =>
                        state_d <= S_Sw;
                    when others => null;
                end case;
            when others => null;
        end case;

        when S_Ori =>
            cmd.mem_ce<=true;
            cmd.RF_Sel<=RFS_RT;
            cmd.RF_we<=true;
            cmd.ALU_OP<=AO_or;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_IR_imm16;
            state_d<=S_Fetch;
        when S_Lui =>
            cmd.mem_ce<=true;
            cmd.RF_Sel<=RFS_RT;
            cmd.RF_we<=true;
            cmd.ALU_OP<=AO_SLL;
            cmd.ALU_X_Sel<=UXS_cst_x10;
            cmd.ALU_Y_Sel<=UYS_IR_imm16;
            state_d<=S_Fetch;
        when S_Add =>
            cmd.mem_ce<=true;
            cmd.RF_Sel<=RFS_RD;
            cmd.RF_we<=true;
            cmd.ALU_OP<=AO_plus;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_RF_RT;
            state_d<=S_Fetch;
        when S_Addu =>
            cmd.mem_ce<=true;
            cmd.RF_Sel<=RFS_RD;
            cmd.RF_we<=true;
            cmd.ALU_OP<=AO_plus;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_RF_RT;
            state_d<=S_Fetch;
        when S_Addi =>
            cmd.mem_ce<=true;
            cmd.RF_Sel<=RFS_RT;
            cmd.RF_we<=true;
            cmd.ALU_OP<=AO_plus;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_IR_imm16_ext;
            state_d<=S_Fetch;
        when S_Addiu =>
            cmd.mem_ce<=true;
            cmd.RF_Sel<=RFS_RT;
            cmd.RF_we<=true;
            cmd.ALU_OP<=AO_plus;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_IR_imm16_ext;
            state_d<=S_Fetch;
        when S_And =>
            cmd.mem_ce<=true;
            cmd.RF_Sel<=RFS_RD;
            cmd.RF_we<=true;
            cmd.ALU_OP<=AO_and;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_RF_RT;
            state_d<=S_Fetch;
        when S_Andi =>
            cmd.mem_ce<=true;
            cmd.RF_Sel<=RFS_RT;
            cmd.RF_we<=true;
            cmd.ALU_OP<=AO_and;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_IR_imm16;
            state_d<=S_Fetch;
        when S_Nor =>
            cmd.mem_ce<=true;
            cmd.RF_Sel<=RFS_RD;
            cmd.RF_we<=true;
            cmd.ALU_OP<=AO_nor;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_RF_RT;
            state_d<=S_Fetch;
        when S_Or =>
            cmd.mem_ce<=true;
            cmd.RF_Sel<=RFS_RD;
            cmd.RF_we<=true;
            cmd.ALU_OP<=AO_or;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_RF_RT;
            state_d<=S_Fetch;
        when S_Xor =>
            cmd.mem_ce<=true;
            cmd.RF_Sel<=RFS_RD;
            cmd.RF_we<=true;
            cmd.ALU_OP<=AO_xor;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_RF_RT;
            state_d<=S_Fetch;
        when S_Xori =>
            cmd.mem_ce<=true;
            cmd.RF_Sel<=RFS_RT;
            cmd.RF_we<=true;
            cmd.ALU_OP<=AO_xor;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_IR_imm16;
            state_d<=S_Fetch;
        when S_Sub =>
            cmd.mem_ce<=true;
            cmd.RF_Sel<=RFS_RD;
            cmd.RF_we<=true;
            cmd.ALU_OP<=AO_moins;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_RF_RT;
            state_d<=S_Fetch;
        when S_Subu =>
            cmd.mem_ce<=true;
            cmd.RF_Sel<=RFS_RD;
            cmd.RF_we<=true;
            cmd.ALU_OP<=AO_moins;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_RF_RT;
            state_d<=S_Fetch;
        when S_Sll =>
            cmd.mem_ce<=true;
            cmd.RF_Sel<=RFS_RD;
            cmd.RF_we<=true;
            cmd.ALU_OP<=AO_SLL;
            cmd.ALU_X_Sel<=UXS_IR_SH;
            cmd.ALU_Y_Sel<=UYS_RF_RT;
            state_d<=S_Fetch;
        when S_Sllv =>
            cmd.mem_ce<=true;
            cmd.RF_Sel<=RFS_RD;
            cmd.RF_we<=true;
            cmd.ALU_OP<=AO_SLL;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_SEL<=UYS_RF_RT;
            state_d<=S_Fetch;
        when S_Srl =>
            cmd.mem_ce<=true;
            cmd.RF_Sel<=RFS_RD;
            cmd.RF_we<=true;
            cmd.ALU_OP<=AO_SRL;
            cmd.ALU_X_Sel<=UXS_IR_SH;
            cmd.ALU_Y_Sel<=UYS_RF_RT;
            state_d<=S_Fetch;
        when S_Sra =>
            cmd.mem_ce <=true;
            cmd.RF_Sel<=RFS_RD;
            cmd.RF_we<=true;
            cmd.ALU_OP<=AO_SRA;
            cmd.ALU_X_Sel<=UXS_IR_SH;
            cmd.ALU_Y_Sel<=UYS_RF_RT;
            state_d<=S_Fetch;
        when S_Srav =>
            cmd.mem_ce<=true;
            cmd.RF_Sel<=RFS_RD;
            cmd.RF_we<=true;
            cmd.ALU_OP<=AO_SRA;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_RF_RT;
            state_d<=S_Fetch;
        when S_Srlv =>
            cmd.mem_ce<=true;
            cmd.RF_Sel<=RFS_RD;
            cmd.RF_we<=true;
            cmd.ALU_OP<=AO_SRL;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_SEL<=UYS_RF_RT;
            state_d<=S_Fetch;
        when S_J =>
            cmd.PC_we<=true;
            cmd.ALU_OP<=AO_or;
            cmd.ALU_X_Sel<=UXS_PC_up;
            cmd.ALU_Y_Sel<=UYS_IR_imm26;
            state_d<=S_Fetch_Wait;
        when S_Beq =>
            cmd.ALU_OP<=AO_moins;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_RF_RT;
            case Status.Z is
                when true =>
                    state_d<=S_B2;
                when others =>
                    cmd.mem_ce<=true;
                    state_d<=S_Fetch;
            end case;
        when S_Bne =>
            cmd.ALU_OP<=AO_moins;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_RF_RT;
            case Status.Z is
                when false =>
                    state_d<=S_B2;
                when others =>
                    cmd.mem_ce<=true;
                    state_d<=S_Fetch;
            end case;
        when S_Blez =>
            cmd.ALU_OP<=AO_moins;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_cst_x00;
            case Status.S or Status.Z is
                when true =>
                    state_d<=S_B2;
                when others =>
                    cmd.mem_ce<=true;
                    state_d<=S_Fetch;
            end case;
        when S_Bgtz =>
            cmd.ALU_OP<=AO_moins;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_cst_x00;
            case Status.Z or Status.S is
                when false =>
                    state_d<=S_B2;
                when others =>
                    cmd.mem_ce<=true;
                    state_d<=S_Fetch;
            end case;
        when S_Bgez =>
            cmd.ALU_OP<=AO_or;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_cst_x00;
            case Status.Z or not Status.S is
                when true =>
                    state_d<=S_B2;
                when others =>
                    cmd.mem_ce<=true;
                    state_d<=S_Fetch;
            end case;
        when S_Bltz =>
            cmd.ALU_OP<=AO_or;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_cst_x00;
            case Status.S is
                when true =>
                    state_d<=S_B2;
                when others =>
                    cmd.mem_ce<=true;
                    state_d<=S_Fetch;
            end case;
        when S_B2 =>
            cmd.PC_we<=true;
            cmd.ALU_OP<=AO_plus;
            cmd.ALU_X_Sel<=UXS_PC;
            cmd.ALU_Y_Sel<=UYS_IR_imm16_ext_up;
            state_d<=S_Fetch_wait;
        when S_Jal =>
            cmd.mem_ce<=true;
            cmd.RF_we<=true;
            cmd.ALU_OP<=AO_plus;
            cmd.ALU_X_Sel<=UXS_PC;
            cmd.ALU_Y_Sel<=UYS_cst_x00;
            cmd.RF_Sel<=RFS_31;
            state_d<=S_J;
        when S_Jr =>
            cmd.mem_ce<=true;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_cst_x00;
            cmd.ALU_OP<=AO_Plus;
            cmd.PC_we<=true;
            state_d<=S_Fetch_wait;
        when S_Jalr =>
            cmd.mem_ce<=true;
            cmd.RF_we<=true;
            cmd.RF_Sel<=RFS_RD;
            cmd.ALU_X_Sel<=UXS_PC;
            cmd.ALU_Y_Sel<=UYS_cst_x00;
            state_d<=S_jr;
        when S_Bltzal =>
            cmd.mem_ce<=true;
            cmd.RF_we<=true;
            cmd.RF_Sel<=RFS_31;
            cmd.ALU_X_Sel<=UXS_PC;
            cmd.ALU_Y_Sel<=UYS_cst_x00;
            cmd.ALU_OP<=AO_or;
            state_d<=S_Bltz;
        when S_Bgezal =>
            cmd.RF_we<=true;
            cmd.RF_Sel<=RFS_31;
            cmd.ALU_X_Sel<=UXS_PC;
            cmd.ALU_Y_Sel<=UYS_cst_x00;
            cmd.ALU_OP<=AO_or;
            state_d<=S_Bgez;
        when S_Lw =>
            cmd.AD_we<=true;
            cmd.ALU_OP<=AO_Plus;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_IR_imm16_ext;
            state_d<=S_Lw2;
        when S_Lw2 =>
            cmd.mem_ce<=true;
            cmd.ADDR_Sel<=ADDR_From_AD;
            state_d<=S_Lw3;
        when S_Lw3 =>
            cmd.DT_we<=true;
            state_d<=S_Lw4;
        when S_Lw4 =>
            cmd.mem_ce<=true;
            cmd.RF_we<=true;
            cmd.ALU_OP<=AO_Plus;
            cmd.ALU_X_Sel<=UXS_DT;
            cmd.ALU_Y_Sel<=UYS_cst_x00;
            cmd.RF_Sel<=RFS_RT;
            state_d<=S_Fetch;
        when S_Sw =>
            cmd.AD_we<=true;
            cmd.ALU_OP<=AO_Plus;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_IR_imm16_ext;
            state_d<=S_Sw2;
        when S_Sw2 =>
            cmd.mem_we<=true;
            cmd.mem_ce<=true;
            cmd.ADDR_Sel<=ADDR_From_AD;
            cmd.ALU_OP<=AO_Plus;
            cmd.ALU_X_Sel<=UXS_cst_x00;
            cmd.ALU_Y_Sel<=UYS_RF_RT;
            state_d<=S_Fetch_wait;
        when S_Slti =>
            cmd.mem_ce<=true;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_IR_imm16_ext;
            cmd.ALU_OP<=AO_moins;
            case Status.S is
                when true =>
                    state_d<=S_Slt1t;
                when false =>
                    state_d<=S_Slt0t;
            end case;
        when S_Sltiu =>
            cmd.mem_ce<=true;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_IR_imm16_ext;
            cmd.ALU_OP<=AO_moins;
            case Status.c is
                when true =>
                    state_d<=S_Slt1t;
                when false =>
                    state_d<=S_Slt0t;
            end case;
        when S_Slt =>
            cmd.mem_ce<=true;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_RF_RT;
            cmd.ALU_OP<=AO_moins;
            case Status.S is
                when true =>
                    state_d<=S_Slt1;
                when false =>
                    state_d<=S_Slt0;
            end case;
        when S_Sltu =>
            cmd.mem_ce<=true;
            cmd.ALU_X_Sel<=UXS_RF_RS;
            cmd.ALU_Y_Sel<=UYS_RF_RT;
            cmd.ALU_OP<=AO_moins;
            case Status.c is
                when true =>
                    state_d<=S_Slt1;
                when false =>
                    state_d<=S_Slt0;
            end case;
        when S_Slt1 =>
            cmd.mem_ce<=true;
            cmd.RF_we<=true;
            cmd.RF_Sel<=RFS_RD;
            cmd.ALU_X_Sel<=UXS_cst_x01;
            cmd.ALU_Y_Sel<=UYS_cst_x00;
            cmd.ALU_OP<=AO_Plus;
            state_d<=S_Fetch;
        when S_Slt0 =>
            cmd.mem_ce<=true;
            cmd.RF_we<=true;
            cmd.RF_Sel<=RFS_RD;
            cmd.ALU_X_Sel<=UXS_cst_x00;
            cmd.ALU_Y_Sel<=UYS_cst_x00;
            cmd.ALU_OP<=AO_Plus;
            state_d<=S_Fetch;
        when S_Slt1t =>
            cmd.mem_ce<=true;
            cmd.RF_we<=true;
            cmd.RF_Sel<=RFS_RT;
            cmd.ALU_X_Sel<=UXS_cst_x01;
            cmd.ALU_Y_Sel<=UYS_cst_x00;
            cmd.ALU_OP<=AO_Plus;
            state_d<=S_Fetch;
        when S_Slt0t =>
            cmd.mem_ce<=true;
            cmd.RF_we<=true;
            cmd.RF_Sel<=RFS_RT;
            cmd.ALU_X_Sel<=UXS_cst_x00;
            cmd.ALU_Y_Sel<=UYS_cst_x00;
            cmd.ALU_OP<=AO_Plus;
            state_d<=S_Fetch;
        when S_Eret =>
            cmd.mem_ce<=true;
            cmd.PC_we<=true;
            cmd.SR_set<=true;
            cmd.ALU_X_Sel<=UXS_EPC;
            cmd.ALU_Y_Sel<=UYS_cst_x00;
            cmd.ALU_OP<=AO_Plus;
            state_d<=S_Fetch;
        when others => null;
    end case;
  end process FSM_comb;
end RTL;

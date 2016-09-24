library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use std.textio.all ;
use ieee.std_logic_textio.all ;

library work;
use work.MMIPS_pkg.all;
use work.txt_util.all;

entity tb_mmips_autotest is
  generic (
            autotest  : string := "test_defaut"
          );
end tb_mmips_autotest;

architecture behavior of tb_mmips_autotest is

  component RAM_bev  is
    generic (
    nbit_addr : integer;
    init_from_file : boolean := false;
    file_name : string := ""
  );
  port (
         clk  : in    std_logic;

         addr : in   std_logic_vector(nbit_addr-1 downto 0);
         do   : out  w32;
         di   : in   w32;
         ce   : in   std_logic;
         we   : in   std_logic
       );
  end component RAM_bev;


  signal mem_addr    :  waddr;
  signal mem_datain  :  w32;
  signal mem_dataout :  w32;

  signal mem_we      :  std_logic;
  signal mem_ce      :  std_logic;


  signal clk         :  std_logic:='0';
  signal reset       :  std_logic;
  signal irq         :  std_logic;
  signal push        :  std_logic;

  signal pout32      : w32;
  signal pout_valid  : boolean;
  signal max_cycle : integer := 500;
  signal gen_irq   : boolean := false;

  constant mem_file : string := autotest & ".mem";

begin

  process
    variable c : integer :=0;
  begin
    clk<='1';
    wait for 5 ns;
    clk<='0';
    wait for 5 ns;
    c := c+1;
    assert c/=max_cycle report "Fin simu : " & str(c) & " cycles" severity failure;
  end process;


  tb_setup : process
    variable ligne_texte : line;
    file f_setup : text open read_mode is autotest & ".setup";
    variable setup_ok, gi : boolean := false;
    variable mc : integer;
  begin
    reset<='1';
    if not setup_ok then
      if not endfile(f_setup) then
        readline(f_setup, ligne_texte);
        read(ligne_texte, mc);
        max_cycle <= mc;
        readline(f_setup, ligne_texte);
        read(ligne_texte, gi);
        gen_irq<= gi;
      end if;
      setup_ok := true;
    end if;
    wait until rising_edge(clk);
    reset<='0';
    wait; -- will wait forever
  end process tb_setup;

  tb_pout :  process
    file f_pout : text open read_mode is autotest & ".out";
    file f_res : text open write_mode is autotest & ".res";
    variable ligne_texte : line;
    variable p : w32;
    variable ok : boolean;
    variable repeat_ok, pout_prev_valid, test : boolean;
    variable repeat : character;
    variable pout, pout_prev :  w32;
  begin
    wait until rising_edge(clk) and reset='0';
    ok := true;
    pout_prev_valid := false;
    while ok and not endfile(f_pout) loop
      readline(f_pout, ligne_texte);
      hread(ligne_texte, p);
      repeat_ok := false;
      read(ligne_texte, repeat, repeat_ok);
      read(ligne_texte, repeat, repeat_ok);
      if  repeat_ok then
        assert false report "repeat x" &repeat&"x  " & hstr(p) severity warning;
        if repeat='x' then
          repeat_ok := true;
        else
          repeat_ok := false;
        end if;
      end if;
      test := true;
      while test loop
        wait until rising_edge(clk) and pout_valid;
        pout := pout32;
        assert false report "pout expect : 0x" & hstr(p) & "  get : 0x"& hstr(pout) severity warning;
  -- gestion des repetitions sur la sortie
        if pout_prev_valid then  	  -- si le motif precedent se repete
          if p = pout then  		-- si c'est la sortie courante attendue
            pout_prev_valid := false;  	-- annule la repetition precedente
            ok := true;			-- et continue
            test := false;
          else
            ok := pout = pout_prev;  	-- verifie la repetition
            assert false report "BUT pout repeat prev : 0x" & hstr(p) & "  get : 0x"& hstr(pout_prev) severity warning;
          end if;
        else
          ok :=  p = pout;
          test := false;
        end if;
  -- si la reference courante se repete, enclenche l'attente
        if not test then
          pout_prev := pout;
          pout_prev_valid := repeat_ok;
        end if;
      end  loop;
    end loop;
    if not ok then
      assert false report "FAILED " severity Note;
      write(ligne_texte, string'("FAILED"));
      writeline(f_res, ligne_texte );
    else
      assert false report "PASSED " severity Note;
      std.textio.write(ligne_texte, string'("PASSED"));
      writeline(f_res, ligne_texte);
    end if;
    wait; -- will wait forever
    assert false severity failure;
  end process tb_pout;


  tb_irq : process
    file f_irq : text open read_mode is autotest & ".irq";
    variable ligne_texte : line;
    variable nc : integer;
  begin
    push <= '0';
    wait until rising_edge(clk) and reset='0';
    if gen_irq then
      while not endfile(f_irq) loop
        readline(f_irq, ligne_texte);
        read(ligne_texte, nc);
        for i  in 0 to nc-1 loop
          wait until rising_edge(clk);
        end loop;  -- i
        push <= '1';
	wait until rising_edge(clk);
        push <= '0';
      end loop;
    else
      push <= '0';
    end if;
    wait; -- will wait forever
  end process tb_irq;



  C_PROC: MMIPS_CPU
  port map(
            clk         => clk,
            rst         => reset,

            irq         =>  irq,


            mem_addr    => mem_addr,
            mem_datain  => mem_datain,
            mem_dataout => mem_dataout,

            mem_we      => mem_we,
            mem_ce      => mem_ce,
      -- debug
            pout        => pout32,
            pout_valid  => pout_valid
          );

  C_RAM: RAM_bev
  generic map (
                nbit_addr => 11,
                init_from_file => true,
                file_name  => mem_file
              )

  port map(
            clk  => clk,
            addr => mem_addr(12 downto 2),
            do   => mem_datain,
            di   => mem_dataout,
            ce   =>mem_ce,
            we   =>mem_we
          );

  C_ITPush : IP_ITPush
  port map(
            clk  => clk,
            rst  => reset,
            -- io
            push => push,
            irq  => irq
          );

end behavior;


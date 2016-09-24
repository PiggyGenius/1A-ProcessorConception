library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.MMIPS_pkg.all;

entity IP_VGA is
    port (
             clk_bus : in std_logic;
             clk_io : in std_logic;
             rst: in std_logic; 
             -- bus
             we : in std_logic;
             ce : in std_logic;
             ad : in waddr;
             datai : in w32;
             datao : out w32;
             -- io
             R      : out  unsigned(4 downto 0);
             G      : out  unsigned(5 downto 0);
             B      : out  unsigned(4 downto 0);
    hs, vs : out std_logic
);
end IP_VGA ;

architecture RTL of IP_VGA  is
    component VGA_GeneSync
        port ( 
                 CLK : in std_logic;
                 HSYNC : out std_logic;
                 VSYNC : out std_logic;
                 IMG : out std_logic;
                 X : out unsigned(9 downto 0);
                 Y : out unsigned(8 downto 0)
             );
    end component VGA_GeneSync;
    component RAM_Video 
        port ( 
                 clka  : in    std_logic;   
                 addra : in    std_logic_vector (16 downto 0); 
                 doa   : out   std_logic_vector(15 downto 0);
                 dia   : in   std_logic_vector(15 downto 0);
                 cea   : in   std_logic;
                 wea   : in   std_logic;

                 clkb  : in    std_logic;   
                 addrb : in    std_logic_vector (16 downto 0); 
                 dob   : out   std_logic_vector(15 downto 0)
             );
    end component RAM_Video;


    signal video_addr : unsigned(16 downto 0);
    signal video_data: std_logic_vector(15 downto 0);
    signal IMGi, IMGii,HSi,VSi, we_bus :std_logic;
    signal Xi : unsigned(9 downto 0);
    signal Yi : unsigned(8 downto 0);

begin
    C_RAM_VIDEO : RAM_Video 
    port map( 
                clka  => clk_bus,
                addra => ad(18 downto 2),
                doa   => datao(15 downto 0),
                dia   => datai(15 downto 0),
                cea   => ce,
                wea   => we,
                clkb  => clk_io,
                addrb => std_logic_vector(video_addr),
                dob   => video_data 
            );

    datao(31 downto 16) <= (others => '0');

    C_VGA_GeneSync  : VGA_GeneSync
    port map(
                clk => clk_io,
                hsync => hsi,
                vsync => vsi,
                img => imgi,
                X => Xi, -- coordonnée sur 640
                Y => Yi -- coordonnée sur 480
            );

    video_addr <= ("0"&Yi(8 downto 1)& x"00") + (Yi(8 downto 1) & "000000") + Xi(9 downto 1) ;

    -- Bascule de synchronisation
    process (clk_io)
    begin
        if rising_edge(clk_io) then
            imgii <= imgi;
            hs <= hsi;
            vs <= vsi;
        end if;
    end process;

    process (video_data,IMGii)
    begin
        if (IMGii = '1') then
            R <= unsigned(video_data(15 downto 11));
            G <= unsigned(video_data(10 downto 5));
            B <= unsigned(video_data(4 downto 0));
        else
            R <= (others => '0');
            G <= (others => '0');
            B <= (others => '0');
        end if;
    end process;
end RTL;

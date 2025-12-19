library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_hdmi_controler is
end entity tb_hdmi_controler;

architecture behavioral of tb_hdmi_controler is

    -- Composant à tester
    component hdmi_controler
        generic (
            h_res  : positive;
            v_res  : positive;
            h_sync : positive;
            h_fp   : positive;
            h_bp   : positive;
            v_sync : positive;
            v_fp   : positive;
            v_bp   : positive
        );
        port (
            i_clk           : in  std_logic;
            i_rst_n         : in  std_logic;
            o_hdmi_hs       : out std_logic;
            o_hdmi_vs       : out std_logic;
            o_hdmi_de       : out std_logic;
            o_pixel_en      : out std_logic;
            o_pixel_address : out natural;
            o_x_counter     : out natural;
            o_y_counter     : out natural
        );
    end component;

    -- Signaux internes
    signal s_clk           : std_logic := '0';
    signal s_rst_n         : std_logic := '0';
    signal s_hdmi_hs       : std_logic;
    signal s_hdmi_vs       : std_logic;
    signal s_hdmi_de       : std_logic;
    signal s_pixel_en      : std_logic;
    signal s_pixel_address : natural;
    signal s_x_counter     : natural;
    signal s_y_counter     : natural;

    -- Période d'horloge (27 MHz pour 480p environ)
    constant clk_period : time := 37.037 ns;

begin

    -- Instanciation du DUT (Device Under Test)
    uut : hdmi_controler
    generic map (
        h_res  => 720,
        v_res  => 480,
        h_sync => 61,
        h_fp   => 58,
        h_bp   => 18,
        v_sync => 5,
        v_fp   => 30,
        v_bp   => 9
    )
    port map (
        i_clk           => s_clk,
        i_rst_n         => s_rst_n,
        o_hdmi_hs       => s_hdmi_hs,
        o_hdmi_vs       => s_hdmi_vs,
        o_hdmi_de       => s_hdmi_de,
        o_pixel_en      => s_pixel_en,
        o_pixel_address => s_pixel_address,
        o_x_counter     => s_x_counter,
        o_y_counter     => s_y_counter
    );

    -- Génération d'horloge
    p_clk : process
    begin
        s_clk <= '0';
        wait for clk_period / 2;
        s_clk <= '1';
        wait for clk_period / 2;
    end process p_clk;

    -- Stimuli
    p_stim : process
    begin
        -- Reset initial
        s_rst_n <= '0';
        wait for 100 ns;
        s_rst_n <= '1';

        -- La simulation doit tourner assez longtemps pour voir une ligne complète et le début de l'image
        -- Une ligne fait environ 857 coups d'horloge. Une image ~450k coups.
        wait;
    end process p_stim;

end architecture behavioral;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hdmi_controler is
    generic (
        H_RES : natural := 720;
        V_RES : natural := 480
    );
    port (
        i_clk   : in  std_logic;  -- horloge pixel 27 MHz
        i_rst_n : in  std_logic;
		  
		  -- Sorties coordonnées vers Telecran
        o_x       : out unsigned(11 downto 0); -- 12 bits suffisent pour 720
        o_y       : out unsigned(11 downto 0); -- 12 bits suffisent pour 480

        -- HDMI output
        o_hdmi_tx_clk : out std_logic;
        --o_hdmi_tx_d   : out std_logic_vector(23 downto 0);
        o_hdmi_tx_de  : out std_logic;
        o_hdmi_tx_hs  : out std_logic;
        o_hdmi_tx_vs  : out std_logic
    );
end entity hdmi_controler;

architecture rtl of hdmi_controler is

    -- Timings pour 480p
    constant H_FP : natural := 16;
    constant H_PW : natural := 62;
    constant H_BP : natural := 60;
    constant H_TOTAL : natural := H_RES + H_FP + H_PW + H_BP;

    constant V_FP : natural := 9;
    constant V_PW : natural := 6;
    constant V_BP : natural := 30;
    constant V_TOTAL : natural := V_RES + V_FP + V_PW + V_BP;

    signal h_cnt : natural range 0 to H_TOTAL-1 := 0;
    signal v_cnt : natural range 0 to V_TOTAL-1 := 0;

    signal de_int : std_logic;  -- signal interne pour data enable

begin

    -- horloge pixel
    o_hdmi_tx_clk <= i_clk;
	 
	 -- Export des coordonnées actuelles
    o_x <= to_unsigned(h_cnt, 12);
    o_y <= to_unsigned(v_cnt, 12);

    -- compteurs horizontaux et verticaux
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst_n = '0' then
                h_cnt <= 0;
                v_cnt <= 0;
            else
                if h_cnt = H_TOTAL-1 then
                    h_cnt <= 0;
                    if v_cnt = V_TOTAL-1 then
                        v_cnt <= 0;
                    else
                        v_cnt <= v_cnt + 1;
                    end if;
                else
                    h_cnt <= h_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    -- génération des signaux de synchronisation
    o_hdmi_tx_hs <= '0' when (h_cnt >= H_RES + H_FP and h_cnt < H_RES + H_FP + H_PW) else '1';
    o_hdmi_tx_vs <= '0' when (v_cnt >= V_RES + V_FP and v_cnt < V_RES + V_FP + V_PW) else '1';

    -- signal interne data enable
    de_int <= '1' when (h_cnt < H_RES and v_cnt < V_RES) else '0';
    o_hdmi_tx_de <= de_int;

--    -- écran entièrement rouge pendant la zone active
--    o_hdmi_tx_d <= (std_logic_vector(to_unsigned(255, 8)) &  -- rouge max
--                    std_logic_vector(to_unsigned(0, 8)) &    -- vert à 0
--                    std_logic_vector(to_unsigned(0, 8)))     -- bleu à 0
--                    when de_int = '1' else
--                   (others => '0');

end architecture rtl;
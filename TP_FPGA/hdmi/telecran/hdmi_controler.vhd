library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hdmi_controler is
    generic (
        h_res  : positive := 720;
        v_res  : positive := 480;
        h_sync : positive := 61;
        h_fp   : positive := 58;
        h_bp   : positive := 18;
        v_sync : positive := 5;
        v_fp   : positive := 30;
        v_bp   : positive := 9
    );
    port (
        -- Horloge et reset
        i_clk           : in  std_logic;
        i_rst_n         : in  std_logic;

        -- Signaux de contrôle ADV7513
        o_hdmi_hs       : out std_logic;
        o_hdmi_vs       : out std_logic;
        o_hdmi_de       : out std_logic;

        -- Signaux pour le générateur de pixels
        o_pixel_en      : out std_logic;
        o_pixel_address : out natural;
        o_x_counter     : out natural;
        o_y_counter     : out natural
    );
end entity hdmi_controler;

architecture rtl of hdmi_controler is

    -- Constantes Horizontales
    constant h_start : positive := h_sync + h_fp;
    constant h_end   : positive := h_start + h_res;
    constant h_total : positive := h_end + h_bp;

    -- Constantes Verticales
    constant v_start : positive := v_sync + v_fp;
    constant v_end   : positive := v_start + v_res;
    constant v_total : positive := v_end + v_bp;

    -- Registres internes
    signal r_h_count  : integer range 0 to h_total;
    signal r_h_active : std_logic;
    
    signal r_v_count  : integer range 0 to v_total;
    signal r_v_active : std_logic;

    -- Registre adresse pixel interne pour le calcul
    signal r_pixel_address : natural;

begin

    -------------------------------------------------------------------------
    -- Process Horizontal
    -------------------------------------------------------------------------
    p_horizontal : process(i_clk, i_rst_n)
    begin
        if i_rst_n = '0' then
            r_h_count   <= 0;
            o_hdmi_hs   <= '1';
            r_h_active  <= '0';
        elsif rising_edge(i_clk) then
            
            -- Compteur r_h_count (0 à h_total)
            if r_h_count = h_total then
                r_h_count <= 0;
            else
                r_h_count <= r_h_count + 1;
            end if;

            -- Signal de synchro horizontale o_hdmi_hs
            -- Logique: '1' si >= h_sync et /= h_total (Active Low implicite pour 0 à h_sync)
            if r_h_count >= h_sync and r_h_count /= h_total then
                o_hdmi_hs <= '1';
            else
                o_hdmi_hs <= '0';
            end if;

            -- Signal actif horizontal r_h_active
            if r_h_count = h_start then
                r_h_active <= '1';
            elsif r_h_count = h_end then
                r_h_active <= '0';
            end if;

        end if;
    end process p_horizontal;

    -------------------------------------------------------------------------
    -- Process Vertical
    -------------------------------------------------------------------------
    p_vertical : process(i_clk, i_rst_n)
    begin
        if i_rst_n = '0' then
            r_v_count  <= 0;
            o_hdmi_vs  <= '1';
            r_v_active <= '0';
        elsif rising_edge(i_clk) then
            
            -- Le compteur vertical n'avance que si le compteur horizontal a fini sa ligne
            if r_h_count = h_total then
                
                -- Compteur r_v_count (0 à v_total)
                if r_v_count = v_total then
                    r_v_count <= 0;
                else
                    r_v_count <= r_v_count + 1;
                end if;

                -- Signal de synchro verticale o_hdmi_vs
                if r_v_count >= v_sync and r_v_count /= v_total then
                    o_hdmi_vs <= '1';
                else
                    o_hdmi_vs <= '0';
                end if;

                -- Signal actif vertical r_v_active
                if r_v_count = v_start then
                    r_v_active <= '1';
                elsif r_v_count = v_end then
                    r_v_active <= '0';
                end if;

            end if;
        end if;
    end process p_vertical;

    -------------------------------------------------------------------------
    -- Process Data Enable (DE)
    -------------------------------------------------------------------------
    p_data_enable : process(i_clk, i_rst_n)
    begin
        if i_rst_n = '0' then
            o_hdmi_de <= '0';
        elsif rising_edge(i_clk) then
            o_hdmi_de <= r_v_active and r_h_active;
        end if;
    end process p_data_enable;

    -------------------------------------------------------------------------
    -- Générateur d'adresse et de coordonnées
    -------------------------------------------------------------------------
    
    -- Pixel Enable : Actif si on est dans la zone active H et V
    o_pixel_en <= r_h_active and r_v_active;

    -- Coordonnées X et Y
    -- Le pixel (0,0) correspond au moment où r_h_count = h_start et r_v_count = v_start
    -- On utilise unsigned/integer conversion ou simple soustraction car type natural
    o_x_counter <= (r_h_count - h_start) when (r_h_active = '1' and r_h_count >= h_start) else 0;
    o_y_counter <= (r_v_count - v_start) when (r_v_active = '1' and r_v_count >= v_start) else 0;

    -- Calcul de l'adresse linéaire : o_pixel_address
    p_address_gen : process(i_clk, i_rst_n)
    begin
        if i_rst_n = '0' then
            r_pixel_address <= 0;
        elsif rising_edge(i_clk) then
            -- Reset de l'adresse au début de la toute première image active ou Vsync
            if r_v_count = 0 and r_h_count = 0 then
                r_pixel_address <= 0; 
            -- Incrément seulement si les pixels sont actifs
            elsif r_h_active = '1' and r_v_active = '1' then
                r_pixel_address <= r_pixel_address + 1;
            end if;
        end if;
    end process p_address_gen;

    o_pixel_address <= r_pixel_address;

end architecture rtl;
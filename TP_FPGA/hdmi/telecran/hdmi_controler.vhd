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
end entity hdmi_controler;

architecture rtl of hdmi_controler is

    -- Constantes
    constant h_start : positive := h_sync + h_fp;
    constant h_end   : positive := h_start + h_res;
    constant h_total : positive := h_end + h_bp;

    constant v_start : positive := v_sync + v_fp;   -- 35
    constant v_end   : positive := v_start + v_res; -- 515
    constant v_total : positive := v_end + v_bp;    -- 524

    -- Registres
    signal r_h_count  : integer range 0 to h_total;
    signal r_h_active : std_logic;
    
    signal r_v_count  : integer range 0 to v_total;
    signal r_v_active : std_logic;

    signal r_pixel_address : natural;

begin

    -- ----------------------------------------------------------------------
    -- Process Horizontal
    -- ----------------------------------------------------------------------
    p_horizontal : process(i_clk, i_rst_n)
    begin
        if i_rst_n = '0' then
            r_h_count   <= 0;
            o_hdmi_hs   <= '1'; -- Reset à 1
            r_h_active  <= '0';
        elsif rising_edge(i_clk) then
            
            -- Compteur
            if r_h_count = h_total then
                r_h_count <= 0;
                -- HS logic pour le retour à 0 : doit être 0 (car < h_sync)
                o_hdmi_hs <= '0';
            else
                r_h_count <= r_h_count + 1;
                
                -- Gestion standard HS (décalage de 1 cycle naturel accepté ici)
                if r_h_count >= h_sync - 1 then 
                    -- Astuce : si on veut que HS passe à 1 exactement à 61,
                    -- on conditionne sur 60. Mais selon l'énoncé standard ">= Sync", 
                    -- le délai est normal. On garde la logique simple.
                    -- Pour V-Sync on a été très précis, pour H-Sync on applique la même logique.
                    if r_h_count >= h_sync then
                        o_hdmi_hs <= '1';
                    else
                        o_hdmi_hs <= '0';
                    end if;
                end if;
            end if;

            -- Active Area
            if r_h_count = h_start then
                r_h_active <= '1';
            elsif r_h_count = h_end then
                r_h_active <= '0';
            end if;

        end if;
    end process p_horizontal;

    -- ----------------------------------------------------------------------
    -- Process Vertical
    -- ----------------------------------------------------------------------
    p_vertical : process(i_clk, i_rst_n)
    begin
        if i_rst_n = '0' then
            r_v_count  <= 0;
            o_hdmi_vs  <= '0'; -- Reset à 0 (début de sync)
            r_v_active <= '0';
        elsif rising_edge(i_clk) then
            
            -- Trigger uniquement quand H finit son cycle (857)
            -- Ainsi V changera en même temps que H passe à 0 (Image 1)
            if r_h_count = h_total then
                
                -- Gestion du Wrap-Around (524 -> 0)
                if r_v_count = v_total then
                    r_v_count <= 0;
                    o_hdmi_vs <= '0'; -- FORCE À 0 ICI pour être synchro avec count=0 (Image 3)
                else
                    r_v_count <= r_v_count + 1;
                    
                    -- Gestion Sync (0 à 1)
                    -- Si count = 5, au prochain coup (6) VS passe à 1. (Image 2)
                    if r_v_count >= v_sync then
                        o_hdmi_vs <= '1';
                    else
                        o_hdmi_vs <= '0';
                    end if;
                end if;

                -- Gestion Active
                -- Si count = 35, au prochain coup (36) Active passe à 1. (Image 4)
                -- Si count = 515, au prochain coup (516) Active passe à 0. (Image 5)
                if r_v_count = v_start then
                    r_v_active <= '1';
                elsif r_v_count = v_end then
                    r_v_active <= '0';
                end if;

            end if;
        end if;
    end process p_vertical;

    -- ----------------------------------------------------------------------
    -- Data Enable & Output Logic
    -- ----------------------------------------------------------------------
    p_data_enable : process(i_clk, i_rst_n)
    begin
        if i_rst_n = '0' then
            o_hdmi_de <= '0';
        elsif rising_edge(i_clk) then
            o_hdmi_de <= r_v_active and r_h_active;
        end if;
    end process p_data_enable;

    o_pixel_en <= r_h_active and r_v_active;

    -- Compteurs X/Y
    -- On garde la logique simple : valeur actuelle - offset.
    -- Comme active est retardé de 1 cycle, et le count aussi, ils sont alignés.
    o_x_counter <= (r_h_count - h_start) when (r_h_count >= h_start and r_h_active = '1') else 0;
    o_y_counter <= (r_v_count - v_start) when (r_v_count >= v_start and r_v_active = '1') else 0;

    -- Adresse Pixel
    p_addr : process(i_clk, i_rst_n)
    begin
        if i_rst_n = '0' then
            r_pixel_address <= 0;
        elsif rising_edge(i_clk) then
            if r_v_count = 0 and r_h_count = 0 then
                r_pixel_address <= 0;
            elsif r_h_active = '1' and r_v_active = '1' then
                r_pixel_address <= r_pixel_address + 1;
            end if;
        end if;
    end process;
    
    o_pixel_address <= r_pixel_address;

end architecture rtl;
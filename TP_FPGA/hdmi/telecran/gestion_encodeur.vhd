library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gestion_encodeur is
    generic (
        C_MAX_VAL   : integer := 720;  -- Valeur max (ex: 720 ou 480)
        C_START_POS : integer := 0     -- Position au démarrage
    );
    port (
        i_clk   : in std_logic; -- Horloge 50 MHz
        i_rst_n : in std_logic;
        i_a     : in std_logic; -- Canal A
        i_b     : in std_logic; -- Canal B
        o_val   : out integer range 0 to C_MAX_VAL-1 -- Position courante
    );
end entity gestion_encodeur;

architecture rtl of gestion_encodeur is

    -- Paramètres Anti-Rebond (Debounce)
    -- 50MHz = 20ns. 2ms / 20ns = 100 000 cycles
    constant C_DEBOUNCE_LIMIT : integer := 100000; 
    signal r_debounce_cnt     : integer range 0 to C_DEBOUNCE_LIMIT := 0;
    signal r_tick_enable      : std_logic := '0';

    -- Signaux internes
    signal r_counter : integer range 0 to C_MAX_VAL-1 := C_START_POS;
    signal r_a_curr, r_a_prev : std_logic := '0';
    signal r_b_curr, r_b_prev : std_logic := '0';

begin

    -- Processus unique : Gestion du Tick + Logique Encodeur
    process(i_clk, i_rst_n)
    begin
        if i_rst_n = '0' then
            r_debounce_cnt <= 0;
            r_tick_enable  <= '0';
            r_counter      <= C_START_POS;
            r_a_curr <= '0'; r_a_prev <= '0';
            r_b_curr <= '0'; r_b_prev <= '0';
            
        elsif rising_edge(i_clk) then
            
            -- 1. Gestion du Timer Anti-Rebond
            if r_debounce_cnt = C_DEBOUNCE_LIMIT then
                r_debounce_cnt <= 0;
                r_tick_enable  <= '1'; -- On autorise la lecture ce cycle-ci
            else
                r_debounce_cnt <= r_debounce_cnt + 1;
                r_tick_enable  <= '0';
            end if;

            -- 2. Logique Encodeur (Uniquement quand Tick est actif)
            if r_tick_enable = '1' then
                -- Echantillonnage
                r_a_curr <= i_a; r_a_prev <= r_a_curr;
                r_b_curr <= i_b; r_b_prev <= r_b_curr;

                -- Incrémentation
                if (r_a_curr = '1' and r_a_prev = '0' and r_b_curr = '0') or
                   (r_a_curr = '0' and r_a_prev = '1' and r_b_curr = '1') then
                    if r_counter < C_MAX_VAL - 1 then
                        r_counter <= r_counter + 1;
                    end if;
                
                -- Décrémentation
                elsif (r_b_curr = '1' and r_b_prev = '0' and r_a_curr = '0') or
                      (r_b_curr = '0' and r_b_prev = '1' and r_a_curr = '1') then
                    if r_counter > 0 then
                        r_counter <= r_counter - 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    o_val <= r_counter;

end architecture rtl;
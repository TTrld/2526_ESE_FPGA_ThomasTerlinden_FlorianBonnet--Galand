library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- =========================================================
-- 1. Entité DEBOUNCER (Filtre anti-rebond)
-- =========================================================
entity debouncer is
    generic (
        -- Temps de stabilité requis (ex: 2ms avec horloge 50MHz = 100_000 cycles)
        TIMEOUT_CYCLES : integer := 100_000 
    );
    port (
        i_clk    : in std_logic;
        i_rst_n  : in std_logic;
        i_noisy  : in std_logic;  -- Signal bruité (bouton/encodeur)
        o_clean  : out std_logic  -- Signal propre
    );
end entity debouncer;

architecture rtl of debouncer is
    signal r_count  : integer range 0 to TIMEOUT_CYCLES;
    signal r_stable : std_logic; -- La valeur mémorisée "propre"
    signal r_sync   : std_logic; -- Pour synchroniser l'entrée (éviter métastabilité)
begin
    process(i_clk, i_rst_n)
    begin
        if i_rst_n = '0' then
            r_count  <= 0;
            r_stable <= '0';
            r_sync   <= '0';
        elsif rising_edge(i_clk) then
            -- 1. Synchronisation de l'entrée (Bonne pratique FPGA)
            r_sync <= i_noisy;

            -- 2. Logique de filtrage
            if (r_sync /= r_stable) then
                -- Si l'entrée est différente de notre valeur stable actuelle
                r_count <= r_count + 1;
                
                -- Si le compteur atteint le temps limite, on valide le changement
                if r_count = TIMEOUT_CYCLES then
                    r_stable <= r_sync;
                    r_count  <= 0;
                end if;
            else
                -- Si l'entrée revient à la valeur stable (c'était un parasite), on reset
                r_count <= 0;
            end if;
        end if;
    end process;

    o_clean <= r_stable;
end architecture rtl;

-- =========================================================
-- 2. Entité Principale : GESTION ENCODEUR
-- =========================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gestion_encodeur is
    generic (
        N_BITS : integer := 10
    );
    port (
        i_clk   : in std_logic;
        i_rst_n : in std_logic;
        i_a     : in std_logic; -- Entrée A (Bruité)
        i_b     : in std_logic; -- Entrée B (Bruité)
        o_led   : out std_logic_vector(N_BITS-1 downto 0)
    );
end entity gestion_encodeur;

architecture rtl of gestion_encodeur is

    -- Déclaration du composant Debouncer
    component debouncer is
        generic ( TIMEOUT_CYCLES : integer );
        port (
            i_clk   : in std_logic;
            i_rst_n : in std_logic;
            i_noisy : in std_logic;
            o_clean : out std_logic
        );
    end component;

    -- Signaux "propres" sortant des debouncers
    signal w_a_clean : std_logic;
    signal w_b_clean : std_logic;

    -- Registres pour la détection de fronts (sur signaux propres)
    signal r_a_curr, r_a_prev : std_logic;
    signal r_b_curr, r_b_prev : std_logic;

    -- Compteur
    signal r_counter : unsigned(N_BITS-1 downto 0) := (others => '0');

begin

    -- =====================================================
    -- INSTANCIATION DES DEBOUNCERS
    -- =====================================================
    
    -- Filtre pour la voie A
    inst_debouncer_A : debouncer
    generic map ( TIMEOUT_CYCLES => 50_000 ) -- Ajustez selon votre horloge (ici env. 1ms @ 50MHz)
    port map (
        i_clk   => i_clk,
        i_rst_n => i_rst_n,
        i_noisy => i_a,        -- On branche l'entrée physique
        o_clean => w_a_clean   -- On récupère le signal propre
    );

    -- Filtre pour la voie B
    inst_debouncer_B : debouncer
    generic map ( TIMEOUT_CYCLES => 50_000 )
    port map (
        i_clk   => i_clk,
        i_rst_n => i_rst_n,
        i_noisy => i_b,
        o_clean => w_b_clean
    );

    -- =====================================================
    -- LOGIQUE PRINCIPALE (Sur w_a_clean et w_b_clean)
    -- =====================================================
    process(i_clk, i_rst_n)
    begin
        if i_rst_n = '0' then
            r_counter <= (others => '0');
            r_a_curr <= '0'; r_a_prev <= '0';
            r_b_curr <= '0'; r_b_prev <= '0';
            
        elsif rising_edge(i_clk) then
            
            -- IMPORTANT : On utilise maintenant les signaux CLEAN
            r_a_curr <= w_a_clean;
            r_a_prev <= r_a_curr;
            
            r_b_curr <= w_b_clean;
            r_b_prev <= r_b_curr;

            -- --- Logique d'Incrémentation ---
            -- Front montant A (Clean) ET B (Clean) bas
            if (r_a_curr = '1' and r_a_prev = '0') and (r_b_curr = '0') then
                r_counter <= r_counter + 1;
            -- Front descendant A ET B haut
            elsif (r_a_curr = '0' and r_a_prev = '1') and (r_b_curr = '1') then
                r_counter <= r_counter + 1;
            end if;

            -- --- Logique de Décrémentation ---
            -- Front montant B ET A bas
            if (r_b_curr = '1' and r_b_prev = '0') and (r_a_curr = '0') then
                r_counter <= r_counter - 1;
            -- Front descendant B ET A haut
            elsif (r_b_curr = '0' and r_b_prev = '1') and (r_a_curr = '1') then
                r_counter <= r_counter - 1;
            end if;
            
        end if;
    end process;

    o_led <= std_logic_vector(r_counter);

end architecture rtl;
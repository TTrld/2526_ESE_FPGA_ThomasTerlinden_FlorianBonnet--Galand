library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- Nécessaire pour l'addition/soustraction sur le compteur

entity gestion_encodeur is
    generic (
        N_BITS : integer := 10 -- Taille du registre configurable
    );
    port (
        i_clk   : in std_logic;
        i_rst_n : in std_logic;
        i_a     : in std_logic; -- Signal A de l'encodeur
        i_b     : in std_logic; -- Signal B de l'encodeur
        o_led   : out std_logic_vector(N_BITS-1 downto 0) -- Sortie binaire
    );
end entity gestion_encodeur;

architecture rtl of gestion_encodeur is

    -- Registres pour la détection de fronts sur A (Structure FF1 -> FF2)
    signal r_a_curr : std_logic;
    signal r_a_prev : std_logic;

    -- Registres pour la détection de fronts sur B
    signal r_b_curr : std_logic;
    signal r_b_prev : std_logic;

    -- Le registre compteur
    signal r_counter : unsigned(N_BITS-1 downto 0) := (others => '0');

begin

    process(i_clk, i_rst_n)
    begin
        if i_rst_n = '0' then
            r_counter <= (others => '0');
            r_a_curr  <= '0';
            r_a_prev  <= '0';
            r_b_curr  <= '0';
            r_b_prev  <= '0';

        elsif rising_edge(i_clk) then
            
            -----------------------------------------------------------
            -- 1. Mise à jour des registres (Détecteur de fronts)
            -----------------------------------------------------------
            -- On décale : prev prend la valeur de curr (t-1)
            r_a_prev <= r_a_curr;
            r_b_prev <= r_b_curr;
            
            -- curr prend la nouvelle valeur d'entrée (t)
            r_a_curr <= i_a;
            r_b_curr <= i_b;

            -----------------------------------------------------------
            -- 2. Application de la logique d'Incrémentation
            -----------------------------------------------------------
            -- Condition 1 : Front montant sur A ET B est bas
            if (r_a_curr = '1' and r_a_prev = '0') and (r_b_curr = '0') then
                r_counter <= r_counter + 1;

            -- Condition 2 : Front descendant sur A ET B est haut
            elsif (r_a_curr = '0' and r_a_prev = '1') and (r_b_curr = '1') then
                r_counter <= r_counter + 1;
            end if;

            -----------------------------------------------------------
            -- 3. Application de la logique de Décrémentation
            -----------------------------------------------------------
            -- Condition 1 : Front montant sur B ET A est bas
            if (r_b_curr = '1' and r_b_prev = '0') and (r_a_curr = '0') then
                r_counter <= r_counter - 1;

            -- Condition 2 : Front descendant sur B ET A est haut
            elsif (r_b_curr = '0' and r_b_prev = '1') and (r_a_curr = '1') then
                r_counter <= r_counter - 1;
            end if;

        end if;
    end process;

    -- Conversion du type unsigned vers std_logic_vector pour la sortie LED
    o_led <= std_logic_vector(r_counter);

end architecture rtl;
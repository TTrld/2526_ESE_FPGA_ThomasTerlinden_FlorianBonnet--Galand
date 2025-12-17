library ieee;
use ieee.std_logic_1164.all;

entity tb_edge_detector is
    -- Une entité de testbench est toujours vide
end entity tb_edge_detector;

architecture behavior of tb_edge_detector is

    -- 1. Déclaration du composant à tester (DUT : Device Under Test)
    component edge_detector is
        port (
            i_clk         : in std_logic;
            i_signal      : in std_logic;
            o_rising_edge : out std_logic
        );
    end component;

    -- 2. Signaux internes pour connecter le composant
    signal r_clk      : std_logic := '0';
    signal r_signal   : std_logic := '0';
    signal w_edge_out : std_logic;

    -- Constante pour définir la vitesse de l'horloge (ex: 100 MHz = 10 ns)
    constant c_clk_period : time := 10 ns;

begin

    -- 3. Instanciation du composant (On le "branche")
    uut: edge_detector
        port map (
            i_clk         => r_clk,
            i_signal      => r_signal,
            o_rising_edge => w_edge_out
        );

    -- 4. Processus de génération de l'horloge
    p_clk : process
    begin
        r_clk <= '0';
        wait for c_clk_period / 2;
        r_clk <= '1';
        wait for c_clk_period / 2;
    end process p_clk;

    -- 5. Processus de stimulation (Le scénario de test)
    p_stim : process
    begin
        -- État initial
        r_signal <= '0';
        wait for 20 ns; -- On attend que tout soit stable

        -------------------------------------------------
        -- TEST 1 : Front Montant (Rising Edge)
        -------------------------------------------------
        -- On passe le signal à 1. On s'attend à voir une impulsion sur o_rising_edge
        r_signal <= '1';
        wait for 40 ns; -- On attend quelques cycles d'horloge

        -------------------------------------------------
        -- TEST 2 : Front Descendant (Falling Edge)
        -------------------------------------------------
        -- On repasse à 0. 
        -- NOTE : Avec ton code XOR, cela va AUSSI déclencher une détection.
        r_signal <= '0';
        wait for 40 ns;

        -------------------------------------------------
        -- TEST 3 : Impulsion rapide
        -------------------------------------------------
        r_signal <= '1';
        wait for c_clk_period * 2; 
        r_signal <= '0';

        -- Fin de la simulation
        wait; -- Le process s'arrête ici indéfiniment
    end process p_stim;

end architecture behavior;
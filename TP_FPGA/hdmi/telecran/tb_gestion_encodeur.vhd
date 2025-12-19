library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_gestion_encodeur is
end entity tb_gestion_encodeur;

architecture behavior of tb_gestion_encodeur is

    -- 1. Déclaration du composant (DUT)
    component gestion_encodeur is
        generic (
            N_BITS : integer := 10
        );
        port (
            i_clk   : in std_logic;
            i_rst_n : in std_logic;
            i_a     : in std_logic;
            i_b     : in std_logic;
            o_led   : out std_logic_vector(N_BITS-1 downto 0)
        );
    end component;

    -- 2. Signaux de test
    signal r_clk   : std_logic := '0';
    signal r_rst_n : std_logic := '0';
    signal r_a     : std_logic := '0';
    signal r_b     : std_logic := '0';
    signal w_led   : std_logic_vector(9 downto 0);

    -- Paramètres de temps
    constant c_clk_period : time := 10 ns;     -- Horloge 100 MHz
    constant c_enc_speed  : time := 40 ns;     -- Vitesse de rotation simulée

begin

    -- 3. Instanciation
    uut: gestion_encodeur
        generic map (
            N_BITS => 10
        )
        port map (
            i_clk   => r_clk,
            i_rst_n => r_rst_n,
            i_a     => r_a,
            i_b     => r_b,
            o_led   => w_led
        );

    -- 4. Génération d'horloge
    p_clk : process
    begin
        r_clk <= '0';
        wait for c_clk_period / 2;
        r_clk <= '1';
        wait for c_clk_period / 2;
    end process p_clk;

    -- 5. Scénario de test
    p_stim : process
    begin
        -- === INITIALISATION ===
        r_rst_n <= '0';
        r_a <= '0'; 
        r_b <= '0';
        wait for 100 ns;
        r_rst_n <= '1'; -- Relâchement du reset
        wait for 100 ns;

        -- === TEST 1 : Rotation vers la DROITE (Incrémentation) ===
        -- On simule 4 "crans" vers la droite
        -- Séquence : 00 -> 10 -> 11 -> 01 -> 00
        
        report "Debut rotation Droite (Incrementation)";
        
        for i in 1 to 4 loop
            r_a <= '1'; wait for c_enc_speed; -- Front Montant A (B=0) -> INC
            r_b <= '1'; wait for c_enc_speed;
            r_a <= '0'; wait for c_enc_speed; -- Front Descendant A (B=1) -> INC
            r_b <= '0'; wait for c_enc_speed;
        end loop;

        wait for 200 ns; -- Pause

        -- === TEST 2 : Rotation vers la GAUCHE (Décrémentation) ===
        -- On simule 4 "crans" vers la gauche pour revenir à 0
        -- Séquence : 00 -> 01 -> 11 -> 10 -> 00
        
        report "Debut rotation Gauche (Decrementation)";

        for i in 1 to 4 loop
            r_b <= '1'; wait for c_enc_speed; -- Front Montant B (A=0) -> DEC
            r_a <= '1'; wait for c_enc_speed;
            r_b <= '0'; wait for c_enc_speed; -- Front Descendant B (A=1) -> DEC
            r_a <= '0'; wait for c_enc_speed;
        end loop;

        -- Fin du test
        wait for 100 ns;
        report "Fin de simulation";
        wait;
    end process p_stim;

end architecture behavior;
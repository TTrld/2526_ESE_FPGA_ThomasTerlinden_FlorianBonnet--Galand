library ieee;
use ieee.std_logic_1164.all;

entity edge_detector is
    port (
        i_clk   : in std_logic;
        i_signal: in std_logic;
        o_rising_edge : out std_logic
    );
end entity edge_detector;

architecture rtl of edge_detector is
    signal r_ff1 : std_logic := '0';
    signal r_ff2 : std_logic := '0';
begin
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            r_ff1 <= i_signal;
            r_ff2 <= r_ff1;
        end if;
    end process;
    o_rising_edge <= r_ff1 xor r_ff2;
end architecture rtl;
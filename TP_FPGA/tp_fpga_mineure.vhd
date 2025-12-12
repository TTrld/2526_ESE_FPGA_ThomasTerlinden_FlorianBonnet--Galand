library ieee;
use ieee.std_logic_1164.all;

entity tp_fpga_mineure is
    port (
        pushl : in std_logic;
        led0 : out std_logic
    );
end entity tp_fpga_mineure;

architecture rtl of tp_fpga_mineure is
begin
    led0 <= not pushl;
end architecture rtl;
# 2526_ESE_FPGA_ThomasTerlinden_FlorianBonnet--Galand

This repository contains the project files for the [FPGA LAB](https://github.com/lfiack/ENSEA_2A_FPGA_Public/blob/main/mineure/3-tp/fpga_tp_english.md) at ENSEA, completed by Thomas Terlinden and Florian Bonnet-Galand.

## LED blinker with a button control

Implementation of the code:
```vhdl
library ieee;
use ieee.std_logic_1164.all;

entity tuto_fpga is
    port (
        pushl : in std_logic;
        led0 : out std_logic
    );
end entity tuto_fpga;

architecture rtl of tuto_fpga is
begin
    led0 <= not pushl; -- LED is ON when button is pressed
end architecture rtl;
```

Results:

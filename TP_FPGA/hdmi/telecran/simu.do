# --- Préparation ---
quit -sim
if {[file exists work]} { vdel -lib work -all }
vlib work

# --- Compilation ---
vcom -2008 -work work hdmi_controler.vhd
vcom -2008 -work work tb_hdmi_controler.vhd

# --- Chargement (+acc pour voir les internes) ---
vsim -voptargs=+acc work.tb_hdmi_controler

# --- Configuration Waveform (Style identique à vos images) ---
delete wave *

# Groupe : Inputs
add wave -noupdate -divider "Inputs"
add wave -noupdate -label "/hdmi_controler_tb/uut/i_clk"   /tb_hdmi_controler/uut/i_clk
add wave -noupdate -label "/hdmi_controler_tb/uut/i_rst_n" /tb_hdmi_controler/uut/i_rst_n

# Groupe : Horizontal
add wave -noupdate -divider "Horizontal"
add wave -noupdate -radix unsigned -label "/hdmi_controler_tb/uut/r_h_count"  /tb_hdmi_controler/uut/r_h_count
add wave -noupdate -label "/hdmi_controler_tb/uut/r_h_active" /tb_hdmi_controler/uut/r_h_active

# Groupe : Vertical
add wave -noupdate -divider "Vertical"
add wave -noupdate -radix unsigned -label "/hdmi_controler_tb/uut/r_v_count"  /tb_hdmi_controler/uut/r_v_count
add wave -noupdate -label "/hdmi_controler_tb/uut/r_v_active" /tb_hdmi_controler/uut/r_v_active

# Groupe : ADV7513
add wave -noupdate -divider "ADV7513"
add wave -noupdate -label "/hdmi_controler_tb/uut/o_hdmi_hs"  /tb_hdmi_controler/uut/o_hdmi_hs
add wave -noupdate -label "/hdmi_controler_tb/uut/o_hdmi_vs"  /tb_hdmi_controler/uut/o_hdmi_vs
add wave -noupdate -label "/hdmi_controler_tb/uut/o_hdmi_de"  /tb_hdmi_controler/uut/o_hdmi_de

# --- Configuration et Lancement ---

# Reset propre
force /tb_hdmi_controler/s_rst_n 0 0ns, 1 50ns
run 50 ns

# Simulation longue pour atteindre la fin de l'image (18 ms)
# Cela permettra de voir le passage de 524 à 0
run 18 ms

# Zoom full pour vue d'ensemble, mais vous devrez zoomer manuellement 
# sur les zones (temps ~17.3ms pour la fin de frame)
wave zoom full

puts "Simulation terminée. Zoomez vers 17.3ms pour voir la fin de frame (ligne 516-524)."
# 1. Nettoyage
quit -sim
if {[file exists work] == 0} {
    vlib work
}

# 2. Compilation (Ordre : Code source, puis Testbench)
vcom -2008 gestion_encodeur.vhd
vcom -2008 tb_gestion_encodeur.vhd

# 3. Chargement de la simulation
vsim work.tb_gestion_encodeur

# 4. Configuration de l'affichage des vagues
# On enlève les chemins longs (tb/uut/...)
config wave -signalnamewidth 1

# Ajout des signaux globaux
add wave -noupdate -divider "Entrees"
add wave -noupdate -color "yellow" /tb_gestion_encodeur/r_clk
add wave -noupdate -color "red"    /tb_gestion_encodeur/r_rst_n

add wave -noupdate -divider "Encodeur"
add wave -noupdate -color "cyan"   /tb_gestion_encodeur/r_a
add wave -noupdate -color "cyan"   /tb_gestion_encodeur/r_b

add wave -noupdate -divider "Sortie & Interne"
# On affiche la LED en binaire
add wave -noupdate -format literal -radix binary /tb_gestion_encodeur/w_led

# ASTUCE : On va chercher le compteur interne du composant (uut) 
# et on l'affiche en DECIMAL (unsigned) pour voir 0, 1, 2, 3...
add wave -noupdate -format literal -radix unsigned /tb_gestion_encodeur/uut/r_counter

# 5. Lancer la simulation
run 1500 ns
wave zoom full
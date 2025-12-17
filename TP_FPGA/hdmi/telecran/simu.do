# 1. Quitter la simulation précédente s'il y en a une en cours
quit -sim

# 2. Créer la bibliothèque de travail "work" si elle n'existe pas
if {[file exists work] == 0} {
    vlib work
}

# 3. Compiler les fichiers VHDL
# L'ordre est important : d'abord les composants, ensuite le testbench qui les utilise
# -2008 force l'utilisation du standard VHDL 2008 (optionnel mais conseillé)
vcom -2008 edge_detector.vhd
vcom -2008 tb_edge_detector.vhd

# 4. Charger la simulation
# On charge l'entité du Testbench (tb_edge_detector) située dans la librairie 'work'
vsim work.tb_edge_detector

# 5. Ajouter les signaux à la fenêtre Wave
# On ajoute tous les signaux (*) du testbench
add wave -position insertpoint sim:/tb_edge_detector/*

# Astuce : On peut aussi ajouter les signaux internes du composant testé (uut)
# add wave -position insertpoint sim:/tb_edge_detector/uut/*

# 6. Configuration de l'affichage (facultatif)
# signalnamewidth 1 permet d'afficher "clk" au lieu de "tb_edge_detector/clk"
config wave -signalnamewidth 1

# 7. Lancer la simulation
# On lance pour une durée définie (ex: 200 nanosecondes) ou "run -all"
run 200 ns

# 8. Zoomer pour tout voir
wave zoom full
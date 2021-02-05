#####################################################################
#
# Simulatiescript (ModelSim 10.0)
#   Jens Van den Broeck, februari 2013
#
# Dit bestand bevat de nodige instellingen en stimuli om de zelf-
# gemaakte SRAM-controller te simuleren. Het SRAM-geheugen wordt
# gesimuleerd door een gelijkaardige component.
#
# Uitvoeren door ModelSim op te starten, en het volgende commando
# in te tikken: do sram_controller_do.do
#
#####################################################################

# Compileer de verschillende VHDL-bestanden, in volgorde!
# ...................................................................
vcom mt55l256l32p.vhd
vcom sram_controller.vhd
vcom tristatebuffer.vhd
vcom sram_tester.vhd

# Start een simulatieomgeving op voor de "sram_tester"-entity.
# ...................................................................
vsim sram_tester

# Voeg de verschillende, te plotten signalen toe.
# Verdeel de verschillende signalen in overzichtelijke groepen.
# ...................................................................
add wave -group controller_input clk
add wave -group controller_input rst
add wave -group controller_input rstinv
add wave -group controller_input -radix decimal ctrl_address
add wave -group controller_input -radix hexadecimal ctrl_in
add wave -group controller_input ctrl_read
add wave -group controller_input ctrl_write
add wave -group controller_input ctrl_burst
add wave -group controller_output -radix hexadecimal ctrl_out
add wave -group controller_output ctrl_rdy

add wave -group testbank top_adv
add wave -group testbank -radix decimal top_address
add wave -group testbank top_cke
add wave -group testbank top_write
add wave -group testbank -group write top_bwa
add wave -group testbank -group write top_bwb
add wave -group testbank -group write top_bwc
add wave -group testbank -group write top_bwd
add wave -group testbank top_ce
add wave -group testbank -group ce top_ce2
add wave -group testbank -group ce top_ce22
add wave -group testbank top_oe
add wave -group testbank -group data_I -radix hexadecimal top_dqa_I
add wave -group testbank -group data_I -radix hexadecimal top_dqb_I
add wave -group testbank -group data_I -radix hexadecimal top_dqc_I
add wave -group testbank -group data_I -radix hexadecimal top_dqd_I
add wave -group testbank -group data_O -radix hexadecimal top_dqa_O
add wave -group testbank -group data_O -radix hexadecimal top_dqb_O
add wave -group testbank -group data_O -radix hexadecimal top_dqc_O
add wave -group testbank -group data_O -radix hexadecimal top_dqd_O
add wave -group testbank -group data_T -radix hexadecimal top_dqa_T
add wave -group testbank -group data_T -radix hexadecimal top_dqb_T
add wave -group testbank -group data_T -radix hexadecimal top_dqc_T
add wave -group testbank -group data_T -radix hexadecimal top_dqd_T
add wave -group testbank -radix hexadecimal top_data
add wave -group testbank top_mode
add wave -group testbank top_zz

# KLOK INSTELLEN
force clk 1 0, 0 5 -repeat 10

# RESET
#  Voer een reset uit van de controller, om alle signalen in een
#  vooraf bekende toestand te plaatsen.
# ...................................................................
force rst 1
force rstinv 0
force ctrl_in 00000000000000000000000000000000
force ctrl_address 000000000000000000
force ctrl_read 0
force ctrl_write 0
force ctrl_burst 0
run 20
force rst 0
force rstinv 1
run 20

# WRITE
#  Voer eerst een SINGLE WRITE uit naar een bepaald geheugenadres.
#  Voer daarna een BURST WRITE uit naar een andere geheugenzone.
#
#  De code hieronder vult het SRAM op met de volgende waarden:
#   0x00000008 | 0xDEADBEEF
#   0x0000000C | 0x0BADF00D
#   0x0000000D | 0xCAFEBABE
#   0x0000000E | 0xFEEDFACE
#   0x0000000F | 0xBADCAB1E
# ...................................................................
force ctrl_write 1
# 0xDEADBEEF
force ctrl_in 11011110101011011011111011101111
force ctrl_address 000000000000001000
run 10
force ctrl_write 0
force ctrl_in 00000000000000000000000000000000
force ctrl_address 000000000000000000
run 10

force ctrl_write 1
#force ctrl_burst 1
# 0x0BADF00D
force ctrl_in 00001011101011011111000000001101
force ctrl_address 000000000000001100
run 10
force ctrl_in 00000000000000000000000000000000
#force ctrl_write 0
# 0xCAFEBABE
force ctrl_in 11001010111111101011101010111110
force ctrl_address 000000000000001011
run 10
# 0xFEEDFACE
force ctrl_in 11111110111011011111101011001110
force ctrl_address 000000000000010000
run 10
# 0xBADCAB1E
force ctrl_in 10111010110111001010110100011110
force ctrl_address 000000000000010111
run 10
force ctrl_in 00000000000000000000000000000000
force ctrl_burst 0
force ctrl_write 0
run 40

# READ
#  Voer eerst een SINGLE READ uit van een bepaald geheugenadres.
#  Voer daarna een BURST READ uit van een andere geheugenzone.
# ...................................................................
force ctrl_read 1
force ctrl_address 000000000000001000
run 10
force ctrl_read 0
force ctrl_address 000000000000000000
run 10
force ctrl_read 1
#force ctrl_burst 1
force ctrl_address 000000000000001100
run 10
#force ctrl_read 0
force ctrl_address 000000000000010000
run 10
#force ctrl_read 0
force ctrl_address 000000000000010111
run 10
#force ctrl_read 0
force ctrl_address 000000000000001011
run 30
force ctrl_burst 0
force ctrl_read 0
run 50

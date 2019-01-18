vlib work
vlog RockBand.v

vlog notes_display_test_three.v
vlog song1.v
vlog Background_ram.v
vlog gameover.v

vsim -L altera_mf_ver RockBand -t ns
log {/*} -r
add wave {/*}

#reset
force {CLOCK_50} 0 0ns, 1 {1ns} -r 2ns
force {SW[0]} 1
force {KEY[0]} 1
run 1000ms
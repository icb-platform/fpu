########################
# set up some vars
########################
set NumberThreads [exec cat /proc/cpuinfo | grep -c processor]
set_host_options -max_cores $NumberThreads

set TOP_ENTITY "fpu_core"

set FPU_PATH "../hdl/fpu_v0.1"

#set TYPE "HALF"
set TYPE "SINGLE"

set TIME [clock seconds]
set FILE [clock format $TIME -format _%a_%d_%m_%Y_]

# use typical case library
# for driving and load
# set LIB uk65lscllmvbbr_120c25_tc
set LIB uk65lscllmvbbl_120c25_tc
set DRIV_CELL BUFM4W
set DRIV_PIN  Z
set LOAD_CELL BUFM4W
set LOAD_PIN  A

set clk_name Clk_CI
set rst_name Rst_RBI

########################
# clean
# do not use -all, that 
# one will delete all 
# std cell libraries
########################

remove_design -design
exec rm -rf WORK


########################
# analyze and compile
########################

foreach clk_period {2.0 1.8 1.6 1.4 1.2 1.0 0.8} {

    remove_design -design
    exec rm -rf WORK/*

    source scripts/analyze_fpu_pkg.tcl
    source scripts/analyze_fpu.tcl

    elaborate ${TOP_ENTITY} -architecture verilog -library WORK
    link

    current_design ${TOP_ENTITY}    

    create_clock $clk_name -period $clk_period

    set_driving_cell  -no_design_rule -library ${LIB} -lib_cell ${DRIV_CELL} -pin ${DRIV_PIN} [all_inputs]   
    set_load [load_of ${LIB}/${LOAD_CELL}/${LOAD_PIN}] [all_outputs]   

    set_dont_touch_network -no_propagate $clk_name
    set_dont_touch_network -no_propagate $rst_name
    set_ideal_network -no_propagate $clk_name
    set_ideal_network -no_propagate $rst_name

    set_input_delay 0.1 -clock $clk_name [all_inputs]
    set_output_delay 0.1 -clock $clk_name [all_outputs]

    set_max_delay ${clk_period} -from [all_inputs] -to [all_outputs] 

    set_optimize_registers -designs fpu_core

    compile_ultra -no_autoungroup

    report_timing      > reports/${TYPE}/timing_${clk_period}.rep
    report_area  -hier > reports/${TYPE}/area_${clk_period}.rep

}
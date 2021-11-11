#Creamos la libreria que vamos a usar prueba.ndm (por el momento hay un warning que no sabemos si nos afecta -ver link library-)
create_lib EL_GRAN_JAGUAR.ndm -technology /usr/synopsys/TSMC/180/CMOS/G/stclib/7-track/tcb018gbwp7t_290a_FE/TSMCHOME/digital/Back_End/milkyway/tcb018gbwp7t_270a/techfiles/tsmc018_6lm.tf \
 -ref_libs /mnt/nfs/synopsys/Compartida_NFS/ASA/LibreriasNDM/TSMCWorkspace.ndm

#Abrimos el verilog file sintetizado
read_verilog /mnt/nfs/synopsys/Compartida_NFS/GRANJAGUAR/El_Gran_Jaguar_v2/Sintesis_cell_io/salidas/out_final_io.v

read_sdc -echo /mnt/nfs/synopsys/Compartida_NFS/GRANJAGUAR/El_Gran_Jaguar_v2/Sintesis_cell_io/salidas/out_final_io.sdc

#Importamos las TLU+ y el map
read_parasitic_tech -tlup /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/tluplus/t018lo_1p6m_typical.tluplus \
-layermap /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/tluplus/star.map_6M

#Limpiamos las cosas de PG
#save_block ALU_SYN.ndm:ALU_IO
remove_pg_strategies -all

#Creacion de corners
create_cell {CORNER1 CORNER2 CORNER3 CORNER4} PCORNER

#Creación de pads para  VDD y VSS
create_cell {PVDD1} PVDD1CDG
create_cell {PVSS1} PVSS1CDG

#Creación de nets de VDD y VSS 
resolve_pg_nets
create_net -power VDD
create_net -ground VSS
connect_pg_net -net VDD [get_pins -physical_context *VDD]
connect_pg_net -net VSS [get_pins -physical_context *VSS]
connect_pg_net -automatic
report_cells -power

#Floorplan inicial
initialize_floorplan -site_def unit -use_site_row -keep_all -side_length {285 285} -core_offset {125}

#Creación del anillo IO
create_io_ring -name anillo_IO_JAGUAR -corner_height 115

#Coloca los pines de entradas y salidas (Pads) en un lugar arbitrario de no ser especificado en el floorplan
add_to_io_guide [get_io_guides anillo_IO_JAGUAR.left] PVDD*
add_to_io_guide [get_io_guides anillo_IO_JAGUAR.right] PVSS*
place_io

#Creacion del anillo de PG
create_pg_ring_pattern ring_pattern -horizontal_layer METAL2    -horizontal_width {2} -horizontal_spacing {2}    -vertical_layer METAL3 -vertical_width {2} -vertical_spacing {2}
set_pg_strategy core_ring    -pattern {{name: ring_pattern}    {nets: {VDD VSS}} {offset: {1 1}}} -core
compile_pg -strategies core_ring

#creamos conexion IO ejemplo 2 -EL MEJOR EJEMPLO-
create_pg_macro_conn_pattern hm_pattern -pin_conn_type scattered_pin -layers {METAL2 METAL3} -nets {VDD VSS} -pin_layers {METAL2}
set_app_options -name plan.pgroute.treat_pad_as_macro -value true
set_pg_strategy macro_conn -macros [get_cells {PVDD* PVSS*}] -pattern {{name: hm_pattern} {nets: {VDD VSS}}}
set_pg_strategy_via_rule macro_conn_via_rule -via_rule {{{{strategies: macro_conn}}{{existing: all} {layers: METAL3}} {via_master: default}} {{intersection: undefined}{via_master: NIL}}}
compile_pg -strategies macro_conn -via_rule macro_conn_via_rule -tag test 

#Creamos el mesh del circuito para VDD y VSS
connect_pg_net -automatic
create_pg_mesh_pattern mesh_pattern -layers { {{vertical_layer: METAL3} {width: 4.2} {pitch: 42} {spacing: interleaving}} }
set_pg_strategy mesh_strategy -polygon {{125.000 118.000} {409.480 414.240}} -pattern {{pattern: mesh_pattern}{nets: {VDD VSS}}} -blockage {macros: all}
create_pg_std_cell_conn_pattern std_cell_pattern
set_pg_strategy std_cell_strategy -core -pattern {{pattern: std_cell_pattern}{nets: {VDD VSS}}}
compile_pg

#Merge del mesh con el pg ring
merge_pg_mesh -nets {VDD VSS} -types {ring stripe} -layers {METAL2 METAL3}

#Creamos el placement 
set_app_options -name place.coarse.fix_hard_macros -value false
set_app_options -name plan.place.auto_create_blockages -value auto
create_placement -floorplan -timing_driven -congestion -effort high -congestion_effort high
legalize_placement

#Sintetizacion de relojes
check_clock_trees -clocks clk
check_design -checks pre_clock_tree_stage
synthesize_clock_trees -clocks clk -postroute -routed_clock_stage detail_with_signal_routes
clock_opt -list_only
check_design -checks cts_qor

#Ruteamos
check_routability -check_pg_blocked_ports true
check_design -checks pre_route_stage 
route_auto

#Creamos los filler del core y el IO ring
create_io_filler_cells -io_guides [get_io_guides {anillo_IO_JAGUAR.top anillo_IO_JAGUAR.right anillo_IO_JAGUAR.left anillo_IO_JAGUAR.bottom}] -reference_cells {PFILLER1 PFILLER5 PFILLER05 PFILLER0005 PFILLER10 PFILLER20}
create_stdcell_fillers -lib_cells [get_lib_cells {TSMCWorkspace|FillersWorkspace/FILL64BWP7T TSMCWorkspace|FillersWorkspace/FILL32BWP7T TSMCWorkspace|FillersWorkspace/FILL16BWP7T TSMCWorkspace|FillersWorkspace/FILL8BWP7T TSMCWorkspace|FillersWorkspace/FILL4BWP7T TSMCWorkspace|FillersWorkspace/FILL2BWP7T TSMCWorkspace|FillersWorkspace/FILL1BWP7T}]
connect_pg_net -automatic
remove_stdcell_fillers_with_violation
check_legality


# Configuramos el DRC runset file
set_app_options -list {signoff.check_design.run_dir {/home/nanoelectronica2021/Documentos/El_Gran_Jaguar2/DRC/}}
set_app_options -list {signoff.check_drc.run_dir {/home/nanoelectronica2021/Documentos/El_Gran_Jaguar2/DRC/}}
set_app_options -list {signoff.check_design.runset {ICVLM18_LM16_LM152_6M.215a_pre041518}}
set_app_options -list {signoff.check_drc.runset {ICVLM18_LM16_LM152_6M.215a_pre041518}}


#Guardamos el bloque y corremos DRC y su Fix
save_block EL_GRAN_JAGUAR.ndm:chip_IO
signoff_fix_drc

save_block EL_GRAN_JAGUAR.ndm:chip_IO
signoff_check_drc

check_lvs
save_block EL_GRAN_JAGUAR.ndm:chip_IO

#Creamos el verilog equivalente de la sintesis fisica
write_verilog -include all EL_GRAN_JAGUAR.v
#route_auto -max_detail_route_iterations 1000
#route_eco -open_net_driven true -max_detail_route_iterations 1000
#optimize_routes -max_detail_route_iterations 100

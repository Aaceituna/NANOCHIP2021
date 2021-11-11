#Creamos la libreria que vamos a usar prueba.ndm (por el momento hay un warning que no sabemos si nos afecta -ver link library-)
create_lib FA_SYN.ndm -technology /usr/synopsys/TSMC/180/CMOS/G/stclib/7-track/tcb018gbwp7t_290a_FE/TSMCHOME/digital/Back_End/milkyway/tcb018gbwp7t_270a/techfiles/tsmc018_6lm.tf \
 -ref_libs /mnt/nfs/compartida/ASA/LibreriasNDM/TSMCWorkspace.ndm

#Abrimos el verilog file sintetizado
read_verilog /mnt/nfs/compartida/FullAdder4/sintesis_logica/Sintesis_cell_io/salidas/out_Fulladd_io.v

read_sdc -echo -syntax_only /mnt/nfs/compartida/FullAdder4/sintesis_logica/Sintesis_cell_io/salidas/out_Fulladd_io.sdc

#Importamos las TLU+ y el map
read_parasitic_tech -tlup /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/tluplus/t018lo_1p6m_typical.tluplus \
-layermap /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/tluplus/star.map_6M

#Limpiamos las cosas de PG
save_block FA_SYN.ndm:fulladd_io
remove_pg_strategies -all

#Creacion de corners
create_cell {CORNER1 CORNER2 CORNER3 CORNER4} PCORNER

#Creación de pads para  VDD y VSS
create_cell PVDDA PVDD1CDG
create_cell PVSSA PVSS1CDG
#create_cell PVDDB PVDD1CDG
#create_cell PVSSB PVSS1CDG

#Creación de nets de VDD y VSS 
resolve_pg_nets
create_net -power VDD
create_net -ground VSS
connect_pg_net -net VDD [get_pins -physical_context *VDD]
connect_pg_net -net VSS [get_pins -physical_context *VSS]
connect_pg_net -automatic
report_cells -power

#Floorplan inicial
#initialize_floorplan -keep_all -side_length {100 100} -core_offset {125}
#set_auto_floorplan_constraints -control_type core -core_utilization 0.70 -side_length {100 100} -honor_pad_limit -use_site_row -site_def unit
initialize_floorplan -site_def unit -use_site_row -keep_all -side_length {285 285} -core_offset {125}
#create_site_row -name filas_core -site unit -origin {125.000 125.000} -site_count 100

#Creación del anillo IO
create_io_ring -name anillo_IO_FA -bbox {{0.0000 0.0000} {534.4800 532.2400}} -corner_height 115
#create_io_ring -name anillo_IO_XOR -bbox {{0.000 0.000} {359.680 358.000}} -corner_height 115
#create_io_ring -name anillo_IO -bbox {{0.000 0.000} {349.680 348.000}} -corner_height 115

#Coloca los pines de entradas y salidas (Pads) en un lugar arbitrario de no ser especificado en el floorplan
#set_power_io_constraints -io_guide_object [get_io_guides {anillo_IO_XOR.right anillo_IO_XOR.left}] -reference_cell {PVDD1CDG PVSS1CDG}
add_to_io_guide [get_io_guides anillo_IO_FA.left] PVDD*
add_to_io_guide [get_io_guides anillo_IO_FA.right] PVSS*
place_io

#Creacion del anillo de PG
create_pg_ring_pattern ring_pattern -horizontal_layer METAL2    -horizontal_width {2} -horizontal_spacing {2}    -vertical_layer METAL3 -vertical_width {2} -vertical_spacing {2}
set_pg_strategy core_ring    -pattern {{name: ring_pattern}    {nets: {VDD VSS}} {offset: {1 1}}} -core
compile_pg -strategies core_ring

#Creamos el placement 
set_app_options -name place.coarse.fix_hard_macros -value false
set_app_options -name plan.place.auto_create_blockages -value auto
create_placement -floorplan -timing_driven -congestion -effort high -congestion_effort high
legalize_placement

#Creamos la conexion a los IO ejemplo 1
#set macros {PVDD PVSS}
#create_pg_macro_conn_pattern macro_connect_pattern    -pin_conn_type scattered_pin -nets {VDD VSS}    -width {0.3 0.3} -layers {METAL2 METAL3}
#set_pg_strategy macro_connect    -pattern {{name: macro_connect_pattern}{nets: VDD VSS}}    -macros "$macros"
#compile_pg -strategies macro_connect

#creamos conexion IO ejemplo 2 -EL MEJOR EJEMPLO-
create_pg_macro_conn_pattern hm_pattern -pin_conn_type scattered_pin -layers {METAL2 METAL3} -nets {VDD VSS} -pin_layers {METAL2}
set_app_options -name plan.pgroute.treat_pad_as_macro -value true
set_pg_strategy macro_conn -macros [get_cells {PVDD* PVSS*}] -pattern {{name: hm_pattern} {nets: {VDD VSS}}}
set_pg_strategy_via_rule macro_conn_via_rule -via_rule {{{{strategies: macro_conn}}{{existing: all} {layers: METAL3}} {via_master: default}} {{intersection: undefined}{via_master: NIL}}}
compile_pg -strategies macro_conn -via_rule macro_conn_via_rule -tag test 

#creamos conexion IO ejemplo 3
#set_app_options -name plan.pgroute.hmpin_connection_target_layers -value METAL3
#create_pg_macro_conn_pattern io_to_ring -pin_conn_type scattered_pin -pin_layers {METAL2} -layers {METAL2 METAL3} -width 10 -via_rule {{{intersection: all} {via_master: NIL}}}
#set_pg_strategy s_io_to_ring -macros {PVDD PVSS} -pattern {{name: io_to_ring}{nets: {VDD VSS}}}
#set_pg_strategy_via_rule rule1 -via_rule {{{{strategies: s_io_to_ring}{layers: METAL2}} {{existing: ring}{layers: METAL3}} {via_master: default}} {{intersection: undefined} {via_master: NIL}}}
#compile_pg -strategies s_io_to_ring -via_rule rule1

#Creamos el mesh del circuito para VDD y VSS
connect_pg_net -automatic
#4.2
create_pg_mesh_pattern mesh_pattern -layers { {{vertical_layer: METAL3} {width: 4.2} {pitch: 42} {spacing: interleaving}} }
set_pg_strategy mesh_strategy -polygon {{125.000 118.000} {409.480 414.240}} -pattern {{pattern: mesh_pattern}{nets: {VDD VSS}}} -blockage {macros: all}
create_pg_std_cell_conn_pattern std_cell_pattern
set_pg_strategy std_cell_strategy -polygon {{125.000 118.000} {409.480 414.240}} -pattern {{pattern: std_cell_pattern}{nets: {VDD VSS}}}
compile_pg 
#-ignore_via_drc

#connect_pg_net -automatic
#create_pg_mesh_pattern mesh_pattern -layers { {{horizontal_layer: METAL2} {width: 4.2} {pitch: 42} {spacing: interleaving}}  {{vertical_layer: METAL3} {width: 4.2} {pitch: 42} {spacing: interleaving}} }
#set_pg_strategy mesh_strategy -core -pattern {{pattern: mesh_pattern}{nets: {VDD VSS}}} -blockage {macros: all}
#create_pg_std_cell_conn_pattern std_cell_pattern
#set_pg_strategy std_cell_strategy -core -pattern {{pattern: std_cell_pattern}{nets: {VDD VSS}}}
#compile_pg 
#-ignore_via_drc

#Merge del mesh con el pg ring
merge_pg_mesh -nets {VDD VSS} -types {ring stripe} -layers {METAL2 METAL3}

#Ruteamos
check_routability -check_pg_blocked_ports true
check_design -checks pre_route_stage 
#-open_message_browser
route_auto

#Creamos los filler del core y el IO ring
create_io_filler_cells -io_guides [get_io_guides {anillo_IO_FA.top anillo_IO_FA.right anillo_IO_FA.left anillo_IO_FA.bottom}] \
-reference_cells {PFILLER1 PFILLER5 PFILLER05 PFILLER0005 PFILLER10 PFILLER20} \
-extension_bbox {{0.0000 0.0000} {534.4800 532.2400}}

create_stdcell_fillers -lib_cells [get_lib_cells {TSMCWorkspace|FillersWorkspace/FILL64BWP7T TSMCWorkspace|FillersWorkspace/FILL32BWP7T TSMCWorkspace|FillersWorkspace/FILL16BWP7T TSMCWorkspace|FillersWorkspace/FILL8BWP7T TSMCWorkspace|FillersWorkspace/FILL4BWP7T TSMCWorkspace|FillersWorkspace/FILL2BWP7T TSMCWorkspace|FillersWorkspace/FILL1BWP7T}]
#remove_stdcell_fillers_with_violation -shorts_only true
connect_pg_net -automatic
#remove_stdcell_fillers_with_violation
#create_stdcell_fillers -lib_cells [get_lib_cells {TSMCWorkspace|FillersWorkspace/FILL2BWP7T TSMCWorkspace|FillersWorkspace/FILL1BWP7T}]
check_legality


# Configuramos el DRC runset file
set_app_options -list {signoff.check_design.run_dir {/home/nanoelectronica2021/Documentos/Sintesis_Fisica_FA1/DRC/}}
set_app_options -list {signoff.check_drc.run_dir {/home/nanoelectronica2021/Documentos/Sintesis_Fisica_FA1/DRC/}}
set_app_options -list {signoff.check_design.runset {ICVLM18_LM16_LM152_6M.215a_pre041518}}
set_app_options -list {signoff.check_drc.runset {ICVLM18_LM16_LM152_6M.215a_pre041518}}


#Guardamos el bloque y corremos DRC y su Fix
#save_block FA_SYN.ndm:fulladd_io
#signoff_fix_drc

#save_block FA_SYN.ndm:fulladd_io
#signoff_check_drc

#check_lvs
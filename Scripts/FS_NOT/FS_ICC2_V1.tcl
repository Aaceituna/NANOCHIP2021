#Creamos la libreria que vamos a usar prueba.ndm (por el momento hay un warning que no sabemos si nos afecta -ver link library-)
create_lib prueba.ndm -technology /usr/synopsys/TSMC/180/CMOS/G/stclib/7-track/tcb018gbwp7t_290a_FE/TSMCHOME/digital/Back_End/milkyway/tcb018gbwp7t_270a/techfiles/tsmc018_6lm.tf -ref_libs /home/nanoelectronica2021/Documentos/PruebaICC2_4/TSMCWorkspace.ndm

#Abrimos el verilog file sintetizado
read_verilog /home/nanoelectronica2021/Escritorio/ELMER_NOT/salidas_not_io2/out_not_io.v

read_sdc -echo -syntax_only /home/nanoelectronica2021/Escritorio/ELMER_NOT/salidas_not_io2/out_not_io.sdc

#Importamos las TLU+ y el map
read_parasitic_tech -tlup /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/tluplus/t018lo_1p6m_typical.tluplus -layermap /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/tluplus/star.map_6M

#Creacion de corners
create_cell {CORNER1 CORNER2 CORNER3 CORNER4} PCORNER

#Creación de pads para  VDD y VSS
#create_cell {VDD} PVDD1CDG
#create_cell {VSS} PVSS1CDG

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
initialize_floorplan -site_def unit -use_site_row -keep_all -side_length {100 100} -core_offset {125}
#create_site_row -name filas_core -site unit -origin {125.000 125.000} -site_count 100

#Creación del anillo IO
create_io_ring -name anillo_IO -bbox {{0.000 0.000} {349.680 348.000}} -corner_height 115

#Coloca los pines de entradas y salidas (Pads) en un lugar arbitrario de no ser especificado en el floorplan
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

#Creación de nets de VDD y VSS 
resolve_pg_nets
create_net -power VDD
create_net -ground VSS
connect_pg_net -net VDD [get_pins -physical_context *VDD]
connect_pg_net -net VSS [get_pins -physical_context *VSS]
connect_pg_net -automatic
report_cells -power
connect_pg_net -automatic

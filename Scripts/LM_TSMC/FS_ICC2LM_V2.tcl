#Importar el tech file
create_workspace -flow normal -technology /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/tf/tsmc018_6lm.tf NormalWorkspace

#Importar los db (no incluimos los IO)
read_db { /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/tcb018gbwp7t/LM/tcb018gbwp7tbc.db /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/tcb018gbwp7t/LM/tcb018gbwp7tlt.db /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/tcb018gbwp7t/LM/tcb018gbwp7tml.db /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/tcb018gbwp7t/LM/tcb018gbwp7ttc.db /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/tcb018gbwp7t/LM/tcb018gbwp7twc.db /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/tcb018gbwp7t/LM/tcb018gbwp7twcl.db }

#Importar el LEF
read_lef /usr/synopsys/TSMC/180/CMOS/G/stclib/7-track/tcb018gbwp7t_290a_FE/TSMCHOME/digital/Back_End/lef/tcb018gbwp7t_270a/lef/tcb018gbwp7t_6lm.lef

#Correr y desplegar el check
current_workspace; check_workspace
gui_create_window -type MessageBrowserWindow
open_ems_database check_workspace.ems

#Commit y save a la libreria
current_workspace NormalWorkspace; commit_workspace  -output StandardWorkspace.ndm

#Creamos el ndm de los pads
create_workspace -flow normal -technology /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/tf/tsmc018_6lm.tf PadsWorkspace
read_db { /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/tcb018gbwp7t/LM/tpd018nvtc.db }
read_lef /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/lef/tpd018nv_6lm.lef
current_workspace; check_workspace
current_workspace PadsWorkspace; commit_workspace  -output PadsWorkspace.ndm

#Creamos el ndm para los corners
create_workspace -flow physical_only -technology /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/tf/tsmc018_6lm.tf CornersWorkspace
read_db { /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/tcb018gbwp7t/LM/tpd018nvtc.db }
read_lef /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/lef/tpd018nv_6lm.lef
current_workspace; check_workspace
current_workspace CornersWorkspace; commit_workspace  -output CornersWorkspace.ndm

#Creamos el ndm para los fillers std cells
create_workspace -flow physical_only -technology /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/tf/tsmc018_6lm.tf PhysicalOnlyWorkspace
read_lef /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/lef/tcb018gbwp7t_6lm.lef
read_db { /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/tcb018gbwp7t/LM/tcb018gbwp7tbc.db /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/tcb018gbwp7t/LM/tcb018gbwp7tlt.db /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/tcb018gbwp7t/LM/tcb018gbwp7tml.db /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/tcb018gbwp7t/LM/tcb018gbwp7ttc.db /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/tcb018gbwp7t/LM/tcb018gbwp7twc.db /home/nanoelectronica2021/Documentos/tcb018gbwp7t_290a_FE/tcb018gbwp7t/LM/tcb018gbwp7twcl.db }
current_workspace; check_workspace
current_workspace PhysicalOnlyWorkspace; commit_workspace  -output FillersWorkspace.ndm

#Integramos los 4 NDM
create_workspace -flow aggregate TSMCWorkspace
read_ndm /mnt/nfs/compartida/ASA/LibreriasNDM/CornersWorkspace.ndm; read_ndm /mnt/nfs/compartida/ASA/LibreriasNDM/FillersWorkspace.ndm; read_ndm /mnt/nfs/compartida/ASA/LibreriasNDM/PadsWorkspace.ndm; read_ndm /mnt/nfs/compartida/ASA/LibreriasNDM/StandardWorkspace.ndm;
current_workspace; check_workspace
current_workspace TSMCWorkspace; commit_workspace  -output TSMCWorkspace.ndm


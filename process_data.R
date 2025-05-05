Listening on http://127.0.0.1:6158
Reading layer `parc' from data source 
  `F:\Qualidade_Florestal\02- MATO GROSSO DO SUL\11- Administrativo Qualidade MS\00- Colaboradores\17 - Alex Vinicius\AutomaÃ§Ã£o em R\AutoAlocador\data\parc.shp' 
  using driver `ESRI Shapefile'
Simple feature collection with 1 feature and 20 fields
Geometry type: POINT
Dimension:     XY
Bounding box:  xmin: -49.21066 ymin: -22.63133 xmax: -49.21066 ymax: -22.63133
Geodetic CRS:  SIRGAS 2000
Aviso em st_cast.sf(shape[i, ], "POLYGON") :
  repeating attributes for all sub-geometries for which they may not be constant
[1] "total de poligonos:  1"
[1] "Processando o indice: 6163014"
Aviso: Error in UseMethod: método não aplicável para 'group_by' aplicado a um objeto de classe "NULL"
  86: group_by
  85: mutate
  84: ungroup
  83: %>%
  82: process_data [src/process_data.R#109]
  81: observe [src/server.R#82]
  80: <observer:observeEvent(input$gerar_parcelas)>
   1: runApp

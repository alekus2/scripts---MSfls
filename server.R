output$plot <- renderPlot({
  # 1) carrega polígono e pontos
  sf_sel  <- shape() %>%
               st_transform(31982) %>%
               mutate(Index = paste0(ID_PROJETO, TALHAO))
  shp_sel <- sf_sel %>% filter(Index == input$selected_index)
  pts_sel <- values$result_points %>% filter(Index == input$selected_index)
  
  # 2) extrai e converte área e intensidade
  area_ha_raw <- shp_sel$AREA_HA[1]
  area_ha     <- as.numeric(area_ha_raw)
  intens_raw  <- input$intensidade_amostral
  intens      <- as.numeric(intens_raw)
  
  # 3) checa intensidade válida
  if (is.na(intens) || intens <= 0) {
    stop("`intensidade_amostral` deve ser um número maior que zero.")
  }
  
  # 4) calcula número recomendado e força mínimo
  num_rec_calc <- area_ha / intens
  num_rec      <- ceiling(num_rec_calc)
  num_rec      <- ifelse(is.na(num_rec) || num_rec < 2, 2, num_rec)
  
  # 5) monta o ggplot
  p <- ggplot() +
    geom_sf(data = shp_sel, fill = NA, color = "#007E69")
  
  if (nrow(pts_sel) > 0) {
    p <- p + geom_sf(data = pts_sel, size = 2)
  }
  
  p +
    ggtitle(sprintf(
      "Número de parcelas recomendadas: %d  (Área: %.2f ha)",
      num_rec, area_ha
    )) +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5, face = "bold"))
})


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
Aviso: Error in stopifnot: i In argument: `Index == input$selected_index`.
Caused by error:
! `..1` must be of size 1, not size 0.
  197: <Anonymous>
  196: signalCondition
  195: signal_abort
  194: abort
  193: <Anonymous>
  192: signalCondition
  191: signal_abort
  190: abort
  189: dplyr_internal_error
  188: eval
  187: mask$eval_all_filter
  185: filter_eval
  184: filter_rows
  183: filter.data.frame
  182: NextMethod
  181: stopifnot
  180: .re_sf
  179: filter.sf
  178: filter
  177: %>%
  176: renderPlot [src/server.R#211]
  174: func
  134: drawPlot
  120: <reactive:plotObj>
  100: drawReactive
   87: renderFunc
   86: output$plot
    1: runApp
Input to asJSON(keep_vec_names=TRUE) is a named vector. In a future version of jsonlite, this option will not be supported, and named vectors will be translated into arrays instead of objects. If you want JSON object output, please use a named list instead. See ?toJSON.

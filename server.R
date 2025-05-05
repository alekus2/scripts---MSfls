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

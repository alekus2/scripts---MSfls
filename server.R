output$plot <- renderPlot({
  req(values$result_points, input$selected_index, shape())

  # 1) Transformar e filtrar o talhão selecionado
  sf_sel <- shape() %>%
    st_transform(31982) %>%
    mutate(Index = paste0(ID_PROJETO, TALHAO))
  shp_sel <- sf_sel %>% filter(Index == input$selected_index)

  # 2) Garantir que exista AREA_HA; se não existir, calcular
  if (!"AREA_HA" %in% names(shp_sel)) {
    shp_sel <- shp_sel %>%
      mutate(AREA_HA = as.numeric(st_area(geometry)) / 10000)
  }
  area_ha <- as.numeric(shp_sel$AREA_HA[1])

  # 3) Calcular número de parcelas e proteger contra NA
  intensidade <- as.numeric(input$intensidade_amostral)
  num_rec <- ceiling(area_ha / intensidade)

  # Aqui vem a “proteção” contra NA ou valores menores que 2
  if (is.na(num_rec) || num_rec < 2) {
    num_rec <- 2
  }

  # 4) Plotar o polígono de contorno + pontos
  ggplot() +
    geom_sf(data = shp_sel, fill = NA, color = "#007E69", size = 0.8) +
    geom_sf(data = values$result_points %>% 
                     filter(Index == input$selected_index),
            size = 2) +
    ggtitle(paste0("Número de parcelas recomendadas: ", num_rec,
                   " (Área: ", round(area_ha, 2), " ha)")) +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5, face = "bold"))
})

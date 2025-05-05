output$plot <- renderPlot({
  req(values$result_points, input$selected_index, shape())
  
  # Força criação do Index para garantir consistência
  sf_sel <- shape() %>%
    st_transform(31982) %>%
    mutate(Index = paste0(ID_PROJETO, TALHAO))
  
  shp_sel <- sf_sel %>% filter(Index == input$selected_index)
  pts_sel <- values$result_points %>% filter(Index == input$selected_index)
  
  # Calcula a área com st_area(), em hectares
  area_ha <- st_area(shp_sel) %>% as.numeric() / 10000
  
  num_rec <- ceiling(area_ha / as.numeric(input$intensidade_amostral))
  if (num_rec < 2) num_rec <- 2
  
  ggplot() +
    geom_sf(data = shp_sel, fill = NA, color = "#007E69", size = 1) +
    geom_sf(data = pts_sel, size = 2) +
    ggtitle(paste0("Número de parcelas recomendadas: ", num_rec,
                   " (Área: ", round(area_ha, 2), " ha)")) +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5, face = "bold"))
})

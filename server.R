output$plot <- renderPlot({
  req(values$result_points, input$selected_index)
  shp <- shape()
  print(class(shp))
  print(nrow(shp))
  print(st_geometry_type(shp))
  shp_sel <- shp %>% filter(Index == input$selected_index)
  req(nrow(shp_sel) > 0)
  pts_sel <- values$result_points %>% filter(Index == input$selected_index)
  area_ha <- as.numeric(st_area(shp_sel)) / 10000
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

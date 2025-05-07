if (!is.null(input$shape_input_pergunta_arudek) &&
    input$shape_input_pergunta_arudek == 0) {
  shp <- shp %>%
    rename(
      ID_PROJETO = !!sym(input$mudar_nome_arudek_projeto),
      TALHAO     = !!sym(input$mudar_nome_arudek_talhao),
      CICLO      = !!sym(input$mudar_nome_arudek_ciclo),
      ROTACAO    = !!sym(input$mudar_nome_arudek_rotacao)
    )
}



output$plot <- renderPlot({
  req(values$result_points, input$selected_index)
  shp_sel <- shape() %>%
    filter(Index == input$selected_index)
  req(nrow(shp_sel) > 0)
  pts_sel  <- values$result_points %>% filter(Index == input$selected_index)
  area_ha  <- as.numeric(st_area(shp_sel)) / 10000
  num_rec  <- max(2, ceiling(area_ha / as.numeric(input$intensidade_amostral)))
  ggplot() +
    geom_sf(data = shp_sel, fill = NA, color = "#007E69", size = 1) +
    geom_sf(data = pts_sel, size = 2) +
    ggtitle(paste0("Número de parcelas recomendadas: ", num_rec,
                   " (Área: ", round(area_ha, 2), " ha)")) +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5, face = "bold"))
})

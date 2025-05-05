library(shiny)
library(sf)
library(stringr)
library(dplyr)
library(zip)
library(ggplot2)

server <- function(input, output, session) {

  # … (todas as partes de upload, process_data, UI, download, etc, sem alterações) …

  # ——————————————————————————————————————————
  # Render do gráfico com contorno + pontos, usando AREA_HA
  output$plot <- renderPlot({
    req(values$result_points, input$selected_index)

    # 1) carrega e indexa o shapefile
    sf_sel  <- shape() %>%
                 st_transform(31982) %>%
                 mutate(Index   = paste0(ID_PROJETO, TALHAO),
                        AREA_HA = as.numeric(AREA_HA))  # converte aqui
    shp_sel <- sf_sel %>% filter(Index == input$selected_index)
    pts_sel <- values$result_points %>% filter(Index == input$selected_index)

    # 2) se não houver polígono nem pontos, só mensagem
    if (nrow(shp_sel) == 0 && nrow(pts_sel) == 0) {
      plot.new()
      title("Nenhum dado para o talhão selecionado")
      return()
    }

    # 3) usa a coluna AREA_HA para calcular
    area_ha <- shp_sel$AREA_HA[1]
    # garante área numérica válida
    if (is.na(area_ha) || area_ha <= 0) {
      area_ha <- 0
    }

    # 4) intensidade (ha por ponto)
    intens <- as.numeric(input$intensidade_amostral)
    if (is.na(intens) || intens <= 0) {
      # fallback pra não dividir por zero
      intens <- if (area_ha > 0) area_ha / 2 else 1
    }

    # 5) número recomendado, forçando mínimo de 2
    num_rec <- ceiling(area_ha / intens)
    if (is.na(num_rec) || num_rec < 2) num_rec <- 2

    # 6) monta o ggplot
    p <- ggplot() +
      # contorno do talhão
      { if (nrow(shp_sel) > 0)
          geom_sf(data = shp_sel, fill = NA, color = "#007E69")
        else NULL } +
      # pontos de amostragem
      { if (nrow(pts_sel) > 0)
          geom_sf(data = pts_sel, size = 2)
        else NULL } +
      ggtitle(sprintf(
        "Número de parcelas recomendadas: %d  (Área: %.2f ha)",
        num_rec, area_ha
      )) +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5, face = "bold"))

    print(p)
  })

  # … (restante do server) …
}

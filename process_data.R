library(sf)
library(dplyr)

process_data <- function(shape, recomend, parc_exist_path, 
                         forma_parcela, tipo_parcela,  
                         distancia.minima,      # não usado: buffer fixo de –30 m
                         intensidade_amostral,  # valor X de “1 por X hectares”
                         update_progress) {
  
  # 1) lê e transforma as parcelas já existentes
  parc_exist <- st_read(parc_exist_path) %>%
    st_transform(31982) %>%
    mutate(Index = paste0(PROJETO, TALHAO))
  
  # 2) transforma e marca os talhões originais
  shape <- shape %>%
    st_transform(31982) %>%
    mutate(Index = paste0(ID_PROJETO, TALHAO))
  
  # 3) aplica buffer interno fixo de –30 m e retém só polígonos não vazios
  shapeb <- shape %>%
    st_buffer(-30) %>%
    filter(!st_is_empty(.))
  
  result_points <- list()
  total_poly   <- n_distinct(shapeb$Index)
  completed     <- 0
  
  # 4) para cada talhão bufferizado
  for (poly_idx in unique(shapeb$Index)) {
    poly     <- filter(shapeb, Index == poly_idx)
    subgeoms <- split_subgeometries(poly)
    
    for (i in seq_len(nrow(subgeoms))) {
      sg      <- subgeoms[i, ]
      area_sg <- as.numeric(st_area(sg))            # m²
      if (area_sg < 400) next                        # ignora muito pequenos
      
      # 5) quantos pontos baseado em “1 por X hectares”?
      area_ha <- area_sg / 10000
      n_pts   <- max(1, floor(area_ha / intensidade_amostral))
      
      # 6) cria grid de centroids com espaçamento adequado
      dx       <- sqrt(area_sg / n_pts)
      grid_pts <- st_make_grid(sg,
                               cellsize = c(dx, dx),
                               what     = "centers")
      #  filtra só os dentro de sg
      grid_pts <- grid_pts[st_within(grid_pts, sg, sparse = FALSE)]
      if (length(grid_pts) == 0) next
      
      # 7) ordena por X então Y e pega os primeiros n_pts
      coords_grid <- st_coordinates(grid_pts)
      ord         <- order(coords_grid[,1], coords_grid[,2])
      sel_pts     <- grid_pts[ord][seq_len(min(length(grid_pts), n_pts))]
      
      # 8) monta o sf com atributos
      coords <- st_coordinates(sel_pts)
      pts_sf <- st_sf(
        data.frame(
          Index      = rep(poly_idx, length(sel_pts)),
          PROJETO    = rep(poly$ID_PROJETO, length(sel_pts)),
          TALHAO     = rep(poly$TALHAO, length(sel_pts)),
          CICLO      = rep(poly$CICLO, length(sel_pts)),
          ROTACAO    = rep(poly$ROTACAO, length(sel_pts)),
          STATUS     = rep("ATIVA", length(sel_pts)),
          FORMA      = rep(forma_parcela, length(sel_pts)),
          TIPO_INSTA = rep(tipo_parcela, length(sel_pts)),
          TIPO_ATUAL = rep(tipo_parcela, length(sel_pts)),
          DATA       = rep(Sys.Date(), length(sel_pts)),
          DATA_ATUAL = rep(Sys.Date(), length(sel_pts)),
          COORD_X    = coords[,1],
          COORD_Y    = coords[,2]
        ),
        geometry = sel_pts
      )
      
      result_points[[paste(poly_idx, i, sep = "_")]] <- pts_sf
    }
    
    completed <- completed + 1
    update_progress(round(completed / total_poly * 100, 2))
  }
  
  # 9) combina todos os pontos
  all_pts <- do.call(rbind, result_points)
  
  # 10) numera sequencialmente sem geometria em parc_exist
  parcelasinv <- parc_exist %>%
    st_drop_geometry() %>%
    group_by(PROJETO) %>%
    summarise(
      max_antiga = max(PARCELAS[PARCELAS < 500], na.rm = TRUE),
      max_geral  = max(PARCELAS, na.rm = TRUE)
    ) %>%
    mutate(
      numeracao_inicial = if_else(
        tipo_parcela %in% c("IFQ6","IFQ12","S30","S90","PP"),
        if_else(max_antiga == 499, max_geral + 1, max_antiga + 1),
        if_else(max_antiga < 500, 501, max_antiga + 1)
      )
    ) %>%
    select(PROJETO, numeracao_inicial)
  
  all_pts <- all_pts %>%
    left_join(parcelasinv, by = "PROJETO") %>%
    replace_na(list(numeracao_inicial = 1)) %>%
    group_by(PROJETO) %>%
    mutate(PARCELAS = row_number() - 1 + first(numeracao_inicial)) %>%
    ungroup() %>%
    select(-numeracao_inicial)
  
  return(all_pts)
}

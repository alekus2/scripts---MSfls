library(glue)
library(sf)
library(dplyr)

process_data <- function(shape, parc_exist_path,
                         forma_parcela, tipo_parcela,
                         distancia.minima,
                         distancia_parcelas,
                         intensidade_amostral,
                         update_progress) {
  
  parc_exist <- suppressMessages(st_read(parc_exist_path)) %>% 
    st_transform(31982)
  
  shape_full <- shape %>%
    st_transform(31982) %>%
    mutate(
      Index = paste0(ID_PROJETO, TALHAO),
      AREA_HA = if ("AREA_HA" %in% names(.)) 
        as.numeric(AREA_HA)
      else as.numeric(st_area(.) / 10000)
    )
  
  shapeb <- shape_full %>%
    st_buffer(-abs(distancia.minima)) %>%
    filter(!st_is_empty(geometry) & st_is_valid(geometry))
  
  indices <- unique(shapeb$Index)
  total_poly <- length(indices)
  result_pts <- vector("list", total_poly)
  
  for (i in seq_along(indices)) {
    idx <- indices[i]
    talhao <- shapeb[shapeb$Index == idx, ]
    if (nrow(talhao) == 0) next
    if (any(st_is_empty(talhao)) || any(!st_is_valid(talhao))) next
    index <- talhao$Index
    area_ha <- talhao$AREA_HA[1]
    n_req <- max(2, ceiling(area_ha / intensidade_amostral))
    
    delta <- sqrt(as.numeric(st_area(talhao)) / n_req)
    
    print(glue("Talhão: {index} | Número de parcelas recomendadas: {n_req} | Distância inicial entre parcelas (delta): {round(delta, 2)} m | Intensidade amostral: {intensidade_amostral} | Área do talhão: {round(area_ha, 2)} ha"))
    
    
    max_iter <- 100
    iter <- 0
    pts_sel <- NULL
    best_diff <- Inf
    best_pts <- NULL
    best_delta <- delta #a distancia minima entre as parcelas não pode ser menor doque 30 metros. então terá que dentro do codigo verificar se o delta é menor ou igual a 30 ou maior que 30 se for maior pode ir diminuindo até alcançar 30. Se alcançar e mesmo assim não couber parcelas o codigo deverá lançar um print avisando q o talhão não cabe parcelas.
    #mas o ideal é sempre tentar manter o mais proximo possivel da distancia minima que o usuario colocou.
    
    while (iter < max_iter) {
      bb <- st_bbox(talhao)

      offset_x <- runif(1, 0, delta)
      offset_y <- runif(1, 0, delta)
      offset <- c(bb$xmin + offset_x, bb$ymin + offset_y)
      
      grid_all <- st_make_grid(talhao, cellsize = c(delta, delta), offset = offset, what = "centers")
      grid_all <- st_cast(grid_all, "POINT")
      inside_poly <- st_within(grid_all, talhao, sparse = FALSE)[,1]
      pts_tmp <- grid_all[inside_poly]
      
      n_pts <- length(pts_tmp)
      diff <- abs(n_pts - n_req)

      if (diff < best_diff) {
        best_diff <- diff
        best_pts <- pts_tmp
        best_delta <- delta
      }
      
      if (n_pts == n_req) {
        pts_sel <- pts_tmp
        break
      } else if (n_pts < n_req) {
        delta <- delta * 0.95  
      } else {
        delta <- delta * 1.05  
      }
      
      iter <- iter + 1
    }

    if (is.null(pts_sel)) {
      if (best_diff <= 1) {  
        pts_sel <- best_pts
        delta <- best_delta
        message(glue("Aceitando {length(pts_sel)} pontos (margem de ±1) para talhão {idx}"))
      } else {
        message(glue("Não foi possível ajustar pontos para talhão {idx} com n_req = {n_req}"))
        next
      }
    }
    
    
    cr <- st_coordinates(pts_sel)
    ord <- order(cr[,1], cr[,2])
    sel <- pts_sel[ord][seq_len(n_req)]
    
    df <- tibble(
      Index      = idx,
      PROJETO    = talhao$ID_PROJETO[1],
      TALHAO     = talhao$TALHAO[1],
      CICLO      = talhao$CICLO[1],
      ROTACAO    = talhao$ROTACAO[1],
      STATUS     = "ATIVA",
      FORMA      = forma_parcela,
      TIPO_INSTA = tipo_parcela,
      TIPO_ATUAL = tipo_parcela,
      DATA       = Sys.Date(),
      DATA_ATUAL = Sys.Date(),
      COORD_X    = st_coordinates(sel)[,1],
      COORD_Y    = st_coordinates(sel)[,2],
      AREA_HA    = area_ha
    )
    
    pts_sf <- st_sf(df, geometry = sel, crs = st_crs(shape_full))
    result_pts[[i]] <- pts_sf
    update_progress(round(i/total_poly * 100, 1))
  }
  
  all_pts <- bind_rows(result_pts)
  
  all_pts %>%
    group_by(Index) %>%
    mutate(PARCELA = row_number()) %>%
    ungroup()
}

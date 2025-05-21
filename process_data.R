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
    
    max_iter <- 50
    iter <- 0
    pts_sel <- NULL
    
    while (iter < max_iter) {
      bb <- st_bbox(talhao)
      offset <- c(bb$xmin + delta / 2, bb$ymin + delta / 2)
      
      grid_all <- st_make_grid(talhao, cellsize = c(delta, delta), offset = offset, what = "centers")
      grid_all <- st_cast(grid_all, "POINT")
      inside_poly <- st_within(grid_all, talhao, sparse = FALSE)[,1]
      pts_tmp <- grid_all[inside_poly]
      
      print(glue("Iteração {iter + 1}: {length(pts_tmp)} pontos encontrados | delta = {round(delta, 2)}"))
      
      if (length(pts_tmp) == n_req) {
        pts_sel <- pts_tmp
        break
      } else if (length(pts_tmp) < n_req) {
        delta <- delta * 0.9
      } else {
        delta <- delta * 1.1
      }
      
      iter <- iter + 1
    }
    
    if (is.null(pts_sel) || length(pts_sel) != n_req) {
      next
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

Talhão: 6455002-01 | Número de parcelas recomendadas: 7 | Distância inicial entre parcelas (delta): 170.59 m | Intensidade amostral: 5 | Área do talhão: 34.17 ha
Iteração 1: 7 pontos encontrados | delta = 170.59
Talhão: 6436066-01 | Número de parcelas recomendadas: 2 | Distância inicial entre parcelas (delta): 94.86 m | Intensidade amostral: 5 | Área do talhão: 8.7 ha
Iteração 1: 1 pontos encontrados | delta = 94.86
Iteração 2: 3 pontos encontrados | delta = 85.38
Iteração 3: 1 pontos encontrados | delta = 93.91
Iteração 4: 3 pontos encontrados | delta = 84.52
Iteração 5: 1 pontos encontrados | delta = 92.97
Iteração 6: 3 pontos encontrados | delta = 83.68
Iteração 7: 1 pontos encontrados | delta = 92.04
Iteração 8: 3 pontos encontrados | delta = 82.84
Iteração 9: 1 pontos encontrados | delta = 91.12
Iteração 10: 2 pontos encontrados | delta = 82.01
Talhão: 6443006-01 | Número de parcelas recomendadas: 16 | Distância inicial entre parcelas (delta): 186.16 m | Intensidade amostral: 5 | Área do talhão: 77.15 ha
Iteração 1: 16 pontos encontrados | delta = 186.16
Talhão: 6443010-01 | Número de parcelas recomendadas: 12 | Distância inicial entre parcelas (delta): 181.81 m | Intensidade amostral: 5 | Área do talhão: 56.37 ha
Iteração 1: 9 pontos encontrados | delta = 181.81
Iteração 2: 14 pontos encontrados | delta = 163.63
Iteração 3: 9 pontos encontrados | delta = 179.99
Iteração 4: 14 pontos encontrados | delta = 161.99
Iteração 5: 10 pontos encontrados | delta = 178.19
Iteração 6: 14 pontos encontrados | delta = 160.37
Iteração 7: 10 pontos encontrados | delta = 176.41
Iteração 8: 14 pontos encontrados | delta = 158.77
Iteração 9: 11 pontos encontrados | delta = 174.64
Iteração 10: 14 pontos encontrados | delta = 157.18
Iteração 11: 12 pontos encontrados | delta = 172.9
Talhão: 6443007-01 | Número de parcelas recomendadas: 20 | Distância inicial entre parcelas (delta): 195.63 m | Intensidade amostral: 5 | Área do talhão: 99.44 ha
Iteração 1: 19 pontos encontrados | delta = 195.63
Iteração 2: 25 pontos encontrados | delta = 176.07
Iteração 3: 19 pontos encontrados | delta = 193.67
Iteração 4: 26 pontos encontrados | delta = 174.31
Iteração 5: 21 pontos encontrados | delta = 191.74
Iteração 6: 18 pontos encontrados | delta = 210.91
Iteração 7: 21 pontos encontrados | delta = 189.82
Iteração 8: 18 pontos encontrados | delta = 208.8
Iteração 9: 21 pontos encontrados | delta = 187.92
Iteração 10: 18 pontos encontrados | delta = 206.71
Iteração 11: 21 pontos encontrados | delta = 186.04
Iteração 12: 18 pontos encontrados | delta = 204.65
Iteração 13: 22 pontos encontrados | delta = 184.18
Iteração 14: 18 pontos encontrados | delta = 202.6
Iteração 15: 23 pontos encontrados | delta = 182.34
Iteração 16: 19 pontos encontrados | delta = 200.58
Iteração 17: 23 pontos encontrados | delta = 180.52
Iteração 18: 19 pontos encontrados | delta = 198.57
Iteração 19: 23 pontos encontrados | delta = 178.71
Iteração 20: 19 pontos encontrados | delta = 196.58
Iteração 21: 24 pontos encontrados | delta = 176.93
Iteração 22: 19 pontos encontrados | delta = 194.62
Iteração 23: 25 pontos encontrados | delta = 175.16
Iteração 24: 20 pontos encontrados | delta = 192.67
Talhão: 6356006-01 | Número de parcelas recomendadas: 17 | Distância inicial entre parcelas (delta): 190.8 m | Intensidade amostral: 5 | Área do talhão: 84.61 ha
Iteração 1: 16 pontos encontrados | delta = 190.8
Iteração 2: 20 pontos encontrados | delta = 171.72
Iteração 3: 16 pontos encontrados | delta = 188.89
Iteração 4: 20 pontos encontrados | delta = 170
Iteração 5: 17 pontos encontrados | delta = 187
Talhão: 6449009-01 | Número de parcelas recomendadas: 8 | Distância inicial entre parcelas (delta): 152.61 m | Intensidade amostral: 5 | Área do talhão: 35.13 ha
Iteração 1: 7 pontos encontrados | delta = 152.61
Iteração 2: 8 pontos encontrados | delta = 137.35
Talhão: 6443013-01 | Número de parcelas recomendadas: 15 | Distância inicial entre parcelas (delta): 187.82 m | Intensidade amostral: 5 | Área do talhão: 72.46 ha
Iteração 1: 13 pontos encontrados | delta = 187.82
Iteração 2: 18 pontos encontrados | delta = 169.04
Iteração 3: 13 pontos encontrados | delta = 185.94
Iteração 4: 18 pontos encontrados | delta = 167.35
Iteração 5: 14 pontos encontrados | delta = 184.09
Iteração 6: 18 pontos encontrados | delta = 165.68
Iteração 7: 14 pontos encontrados | delta = 182.24
Iteração 8: 18 pontos encontrados | delta = 164.02
Iteração 9: 14 pontos encontrados | delta = 180.42
Iteração 10: 18 pontos encontrados | delta = 162.38
Iteração 11: 14 pontos encontrados | delta = 178.62
Iteração 12: 18 pontos encontrados | delta = 160.76
Iteração 13: 14 pontos encontrados | delta = 176.83
Iteração 14: 18 pontos encontrados | delta = 159.15
Iteração 15: 14 pontos encontrados | delta = 175.06
Iteração 16: 19 pontos encontrados | delta = 157.56
Iteração 17: 14 pontos encontrados | delta = 173.31
Iteração 18: 19 pontos encontrados | delta = 155.98
Iteração 19: 15 pontos encontrados | delta = 171.58
Talhão: 6291010-01 | Número de parcelas recomendadas: 17 | Distância inicial entre parcelas (delta): 183.69 m | Intensidade amostral: 5 | Área do talhão: 83.51 ha
Iteração 1: 14 pontos encontrados | delta = 183.69
Iteração 2: 20 pontos encontrados | delta = 165.32
Iteração 3: 15 pontos encontrados | delta = 181.85
Iteração 4: 20 pontos encontrados | delta = 163.66
Iteração 5: 16 pontos encontrados | delta = 180.03
Iteração 6: 19 pontos encontrados | delta = 162.03
Iteração 7: 16 pontos encontrados | delta = 178.23
Iteração 8: 18 pontos encontrados | delta = 160.41
Iteração 9: 17 pontos encontrados | delta = 176.45
Talhão: 6443002-01 | Número de parcelas recomendadas: 20 | Distância inicial entre parcelas (delta): 186.17 m | Intensidade amostral: 5 | Área do talhão: 96.84 ha
Iteração 1: 20 pontos encontrados | delta = 186.17
Talhão: 6428006-01 | Número de parcelas recomendadas: 2 | Distância inicial entre parcelas (delta): 10.73 m | Intensidade amostral: 5 | Área do talhão: 3.57 ha
Iteração 1: 1 pontos encontrados | delta = 10.73
Iteração 2: 1 pontos encontrados | delta = 9.66
Iteração 3: 2 pontos encontrados | delta = 8.69
Talhão: 6505028-01 | Número de parcelas recomendadas: 18 | Distância inicial entre parcelas (delta): 186.56 m | Intensidade amostral: 5 | Área do talhão: 86.61 ha
Iteração 1: 18 pontos encontrados | delta = 186.56
Talhão: 6505026-01 | Número de parcelas recomendadas: 11 | Distância inicial entre parcelas (delta): 175.68 m | Intensidade amostral: 5 | Área do talhão: 54.65 ha
Iteração 1: 12 pontos encontrados | delta = 175.68
Iteração 2: 9 pontos encontrados | delta = 193.25
Iteração 3: 12 pontos encontrados | delta = 173.93
Iteração 4: 9 pontos encontrados | delta = 191.32
Iteração 5: 12 pontos encontrados | delta = 172.19
Iteração 6: 10 pontos encontrados | delta = 189.41
Iteração 7: 12 pontos encontrados | delta = 170.47
Iteração 8: 10 pontos encontrados | delta = 187.51
Iteração 9: 12 pontos encontrados | delta = 168.76
Iteração 10: 10 pontos encontrados | delta = 185.64
Iteração 11: 12 pontos encontrados | delta = 167.07
Iteração 12: 10 pontos encontrados | delta = 183.78
Iteração 13: 12 pontos encontrados | delta = 165.4
Iteração 14: 11 pontos encontrados | delta = 181.94
Talhão: 6505029-01 | Número de parcelas recomendadas: 13 | Distância inicial entre parcelas (delta): 179.01 m | Intensidade amostral: 5 | Área do talhão: 62.25 ha
Iteração 1: 12 pontos encontrados | delta = 179.01
Iteração 2: 13 pontos encontrados | delta = 161.11
Talhão: 6268029-01 | Número de parcelas recomendadas: 11 | Distância inicial entre parcelas (delta): 173.25 m | Intensidade amostral: 5 | Área do talhão: 52.37 ha
Iteração 1: 11 pontos encontrados | delta = 173.25
Talhão: 6268026-01 | Número de parcelas recomendadas: 9 | Distância inicial entre parcelas (delta): 174.79 m | Intensidade amostral: 5 | Área do talhão: 43.79 ha
Iteração 1: 8 pontos encontrados | delta = 174.79
Iteração 2: 11 pontos encontrados | delta = 157.31
Iteração 3: 9 pontos encontrados | delta = 173.04
Talhão: 6268034-01 | Número de parcelas recomendadas: 2 | Distância inicial entre parcelas (delta): 16.1 m | Intensidade amostral: 5 | Área do talhão: 3.37 ha
Iteração 1: 2 pontos encontrados | delta = 16.1
Talhão: 6319009-01 | Número de parcelas recomendadas: 11 | Distância inicial entre parcelas (delta): 151.99 m | Intensidade amostral: 5 | Área do talhão: 53.09 ha
Iteração 1: 12 pontos encontrados | delta = 151.99
Iteração 2: 10 pontos encontrados | delta = 167.19
Iteração 3: 11 pontos encontrados | delta = 150.47
Talhão: 6356003-01 | Número de parcelas recomendadas: 14 | Distância inicial entre parcelas (delta): 186.22 m | Intensidade amostral: 5 | Área do talhão: 69.16 ha
Iteração 1: 14 pontos encontrados | delta = 186.22
Talhão: 6443008-01 | Número de parcelas recomendadas: 15 | Distância inicial entre parcelas (delta): 183.24 m | Intensidade amostral: 5 | Área do talhão: 70.44 ha
Iteração 1: 14 pontos encontrados | delta = 183.24
Iteração 2: 15 pontos encontrados | delta = 164.92
Talhão: 6443012-01 | Número de parcelas recomendadas: 5 | Distância inicial entre parcelas (delta): 160.99 m | Intensidade amostral: 5 | Área do talhão: 24.81 ha
Iteração 1: 3 pontos encontrados | delta = 160.99
Iteração 2: 6 pontos encontrados | delta = 144.89
Iteração 3: 3 pontos encontrados | delta = 159.38
Iteração 4: 6 pontos encontrados | delta = 143.44
Iteração 5: 3 pontos encontrados | delta = 157.79
Iteração 6: 6 pontos encontrados | delta = 142.01
Iteração 7: 4 pontos encontrados | delta = 156.21
Iteração 8: 6 pontos encontrados | delta = 140.59
Iteração 9: 5 pontos encontrados | delta = 154.65
Talhão: 6443015-01 | Número de parcelas recomendadas: 17 | Distância inicial entre parcelas (delta): 193.74 m | Intensidade amostral: 5 | Área do talhão: 84.59 ha
Iteração 1: 16 pontos encontrados | delta = 193.74
Iteração 2: 20 pontos encontrados | delta = 174.36
Iteração 3: 16 pontos encontrados | delta = 191.8
Iteração 4: 21 pontos encontrados | delta = 172.62
Iteração 5: 16 pontos encontrados | delta = 189.88
Iteração 6: 22 pontos encontrados | delta = 170.9
Iteração 7: 16 pontos encontrados | delta = 187.98
Iteração 8: 23 pontos encontrados | delta = 169.19
Iteração 9: 16 pontos encontrados | delta = 186.1
Iteração 10: 24 pontos encontrados | delta = 167.49
Iteração 11: 16 pontos encontrados | delta = 184.24
Iteração 12: 24 pontos encontrados | delta = 165.82
Iteração 13: 16 pontos encontrados | delta = 182.4
Iteração 14: 24 pontos encontrados | delta = 164.16
Iteração 15: 16 pontos encontrados | delta = 180.58
Iteração 16: 24 pontos encontrados | delta = 162.52
Iteração 17: 16 pontos encontrados | delta = 178.77
Iteração 18: 24 pontos encontrados | delta = 160.89
Iteração 19: 17 pontos encontrados | delta = 176.98
Talhão: 6387008-01 | Número de parcelas recomendadas: 14 | Distância inicial entre parcelas (delta): 183.93 m | Intensidade amostral: 5 | Área do talhão: 68.88 ha
Iteração 1: 12 pontos encontrados | delta = 183.93
Iteração 2: 16 pontos encontrados | delta = 165.54
Iteração 3: 14 pontos encontrados | delta = 182.09
Talhão: 6475004-01 | Número de parcelas recomendadas: 13 | Distância inicial entre parcelas (delta): 171.57 m | Intensidade amostral: 5 | Área do talhão: 62.38 ha
Iteração 1: 13 pontos encontrados | delta = 171.57
Talhão: 6518017-01 | Número de parcelas recomendadas: 21 | Distância inicial entre parcelas (delta): 169.96 m | Intensidade amostral: 5 | Área do talhão: 101.32 ha
Iteração 1: 19 pontos encontrados | delta = 169.96
Iteração 2: 24 pontos encontrados | delta = 152.97
Iteração 3: 21 pontos encontrados | delta = 168.26
Talhão: 6431011-01 | Número de parcelas recomendadas: 13 | Distância inicial entre parcelas (delta): 176.31 m | Intensidade amostral: 5 | Área do talhão: 61.07 ha
Iteração 1: 10 pontos encontrados | delta = 176.31
Iteração 2: 14 pontos encontrados | delta = 158.68
Iteração 3: 10 pontos encontrados | delta = 174.55
Iteração 4: 14 pontos encontrados | delta = 157.09
Iteração 5: 10 pontos encontrados | delta = 172.8
Iteração 6: 14 pontos encontrados | delta = 155.52
Iteração 7: 10 pontos encontrados | delta = 171.07
Iteração 8: 14 pontos encontrados | delta = 153.96
Iteração 9: 13 pontos encontrados | delta = 169.36
Talhão: 6449001-01 | Número de parcelas recomendadas: 11 | Distância inicial entre parcelas (delta): 105.53 m | Intensidade amostral: 5 | Área do talhão: 52.02 ha
Iteração 1: 11 pontos encontrados | delta = 105.53
Talhão: 6431012-01 | Número de parcelas recomendadas: 13 | Distância inicial entre parcelas (delta): 185.12 m | Intensidade amostral: 5 | Área do talhão: 62.07 ha
Iteração 1: 10 pontos encontrados | delta = 185.12
Iteração 2: 12 pontos encontrados | delta = 166.61
Iteração 3: 16 pontos encontrados | delta = 149.95
Iteração 4: 12 pontos encontrados | delta = 164.95
Iteração 5: 17 pontos encontrados | delta = 148.45
Iteração 6: 13 pontos encontrados | delta = 163.3
Talhão: 6268028-01 | Número de parcelas recomendadas: 15 | Distância inicial entre parcelas (delta): 173.57 m | Intensidade amostral: 5 | Área do talhão: 74.94 ha
Iteração 1: 15 pontos encontrados | delta = 173.57
Talhão: 6459015-01 | Número de parcelas recomendadas: 14 | Distância inicial entre parcelas (delta): 169.48 m | Intensidade amostral: 5 | Área do talhão: 66.1 ha
Iteração 1: 13 pontos encontrados | delta = 169.48
Iteração 2: 17 pontos encontrados | delta = 152.53
Iteração 3: 14 pontos encontrados | delta = 167.78
Talhão: 6443011-01 | Número de parcelas recomendadas: 7 | Distância inicial entre parcelas (delta): 156.2 m | Intensidade amostral: 5 | Área do talhão: 33.01 ha
Iteração 1: 5 pontos encontrados | delta = 156.2
Iteração 2: 6 pontos encontrados | delta = 140.58
Iteração 3: 10 pontos encontrados | delta = 126.52
Iteração 4: 7 pontos encontrados | delta = 139.17
Talhão: 6436062-01 | Número de parcelas recomendadas: 7 | Distância inicial entre parcelas (delta): 147.29 m | Intensidade amostral: 5 | Área do talhão: 33.06 ha
Iteração 1: 6 pontos encontrados | delta = 147.29
Iteração 2: 9 pontos encontrados | delta = 132.56
Iteração 3: 5 pontos encontrados | delta = 145.82
Iteração 4: 9 pontos encontrados | delta = 131.23
Iteração 5: 5 pontos encontrados | delta = 144.36
Iteração 6: 9 pontos encontrados | delta = 129.92
Iteração 7: 6 pontos encontrados | delta = 142.91
Iteração 8: 9 pontos encontrados | delta = 128.62
Iteração 9: 6 pontos encontrados | delta = 141.48
Iteração 10: 9 pontos encontrados | delta = 127.34
Iteração 11: 6 pontos encontrados | delta = 140.07
Iteração 12: 10 pontos encontrados | delta = 126.06
Iteração 13: 8 pontos encontrados | delta = 138.67
Iteração 14: 5 pontos encontrados | delta = 152.54
Iteração 15: 8 pontos encontrados | delta = 137.28
Iteração 16: 6 pontos encontrados | delta = 151.01
Iteração 17: 9 pontos encontrados | delta = 135.91
Iteração 18: 6 pontos encontrados | delta = 149.5
Iteração 19: 9 pontos encontrados | delta = 134.55
Iteração 20: 6 pontos encontrados | delta = 148.01
Iteração 21: 9 pontos encontrados | delta = 133.21
Iteração 22: 5 pontos encontrados | delta = 146.53
Iteração 23: 9 pontos encontrados | delta = 131.87
Iteração 24: 5 pontos encontrados | delta = 145.06
Iteração 25: 9 pontos encontrados | delta = 130.55
Iteração 26: 5 pontos encontrados | delta = 143.61
Iteração 27: 9 pontos encontrados | delta = 129.25
Iteração 28: 6 pontos encontrados | delta = 142.17
Iteração 29: 9 pontos encontrados | delta = 127.96
Iteração 30: 6 pontos encontrados | delta = 140.75
Iteração 31: 9 pontos encontrados | delta = 126.68
Iteração 32: 7 pontos encontrados | delta = 139.34
Talhão: 6431048-01 | Número de parcelas recomendadas: 19 | Distância inicial entre parcelas (delta): 184.8 m | Intensidade amostral: 5 | Área do talhão: 90.51 ha
Iteração 1: 17 pontos encontrados | delta = 184.8
Iteração 2: 22 pontos encontrados | delta = 166.32
Iteração 3: 18 pontos encontrados | delta = 182.95
Iteração 4: 22 pontos encontrados | delta = 164.65
Iteração 5: 18 pontos encontrados | delta = 181.12
Iteração 6: 21 pontos encontrados | delta = 163.01
Iteração 7: 18 pontos encontrados | delta = 179.31
Iteração 8: 22 pontos encontrados | delta = 161.38
Iteração 9: 19 pontos encontrados | delta = 177.51
Talhão: 6436047-01 | Número de parcelas recomendadas: 15 | Distância inicial entre parcelas (delta): 189.59 m | Intensidade amostral: 5 | Área do talhão: 73.2 ha
Iteração 1: 14 pontos encontrados | delta = 189.59
Iteração 2: 18 pontos encontrados | delta = 170.63
Iteração 3: 14 pontos encontrados | delta = 187.7
Iteração 4: 18 pontos encontrados | delta = 168.93
Iteração 5: 14 pontos encontrados | delta = 185.82
Iteração 6: 18 pontos encontrados | delta = 167.24
Iteração 7: 14 pontos encontrados | delta = 183.96
Iteração 8: 18 pontos encontrados | delta = 165.56
Iteração 9: 15 pontos encontrados | delta = 182.12
Talhão: 6518002-01 | Número de parcelas recomendadas: 14 | Distância inicial entre parcelas (delta): 183.31 m | Intensidade amostral: 5 | Área do talhão: 67.68 ha
Iteração 1: 12 pontos encontrados | delta = 183.31
Iteração 2: 14 pontos encontrados | delta = 164.98
Talhão: 6518001-01 | Número de parcelas recomendadas: 20 | Distância inicial entre parcelas (delta): 190.05 m | Intensidade amostral: 5 | Área do talhão: 95.59 ha
Iteração 1: 18 pontos encontrados | delta = 190.05
Iteração 2: 22 pontos encontrados | delta = 171.04
Iteração 3: 18 pontos encontrados | delta = 188.15
Iteração 4: 23 pontos encontrados | delta = 169.33
Iteração 5: 18 pontos encontrados | delta = 186.27
Iteração 6: 23 pontos encontrados | delta = 167.64
Iteração 7: 18 pontos encontrados | delta = 184.4
Iteração 8: 23 pontos encontrados | delta = 165.96
Iteração 9: 18 pontos encontrados | delta = 182.56
Iteração 10: 24 pontos encontrados | delta = 164.3
Iteração 11: 19 pontos encontrados | delta = 180.73
Iteração 12: 24 pontos encontrados | delta = 162.66
Iteração 13: 19 pontos encontrados | delta = 178.93
Iteração 14: 25 pontos encontrados | delta = 161.03
Iteração 15: 20 pontos encontrados | delta = 177.14
Talhão: 6459024-01 | Número de parcelas recomendadas: 12 | Distância inicial entre parcelas (delta): 177.79 m | Intensidade amostral: 5 | Área do talhão: 57.08 ha
Iteração 1: 9 pontos encontrados | delta = 177.79
Iteração 2: 12 pontos encontrados | delta = 160.01
Talhão: 6505035-01 | Número de parcelas recomendadas: 13 | Distância inicial entre parcelas (delta): 169.07 m | Intensidade amostral: 5 | Área do talhão: 61.95 ha
Iteração 1: 9 pontos encontrados | delta = 169.07
Iteração 2: 14 pontos encontrados | delta = 152.17
Iteração 3: 9 pontos encontrados | delta = 167.38
Iteração 4: 14 pontos encontrados | delta = 150.64
Iteração 5: 10 pontos encontrados | delta = 165.71
Iteração 6: 15 pontos encontrados | delta = 149.14
Iteração 7: 12 pontos encontrados | delta = 164.05
Iteração 8: 13 pontos encontrados | delta = 147.65

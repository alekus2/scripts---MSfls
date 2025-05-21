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

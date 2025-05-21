max_iter <- 100
iter <- 0
pts_sel <- NULL
best_diff <- Inf
best_pts <- NULL
best_delta <- delta

while (iter < max_iter) {
  bb <- st_bbox(talhao)
  
  # Ajusta o offset variando dentro do intervalo [0, delta]
  offset_x <- runif(1, 0, delta)
  offset_y <- runif(1, 0, delta)
  offset <- c(bb$xmin + offset_x, bb$ymin + offset_y)
  
  grid_all <- st_make_grid(talhao, cellsize = c(delta, delta), offset = offset, what = "centers")
  grid_all <- st_cast(grid_all, "POINT")
  inside_poly <- st_within(grid_all, talhao, sparse = FALSE)[,1]
  pts_tmp <- grid_all[inside_poly]
  
  n_pts <- length(pts_tmp)
  diff <- abs(n_pts - n_req)
  
  # Guarda a melhor solução até aqui
  if (diff < best_diff) {
    best_diff <- diff
    best_pts <- pts_tmp
    best_delta <- delta
  }
  
  if (n_pts == n_req) {
    pts_sel <- pts_tmp
    break
  } else if (n_pts < n_req) {
    delta <- delta * 0.95  # ajuste menor para diminuir delta
  } else {
    delta <- delta * 1.05  # ajuste menor para aumentar delta
  }
  
  iter <- iter + 1
}

# Se não encontrou exatamente n_req, aceita a melhor solução próxima
if (is.null(pts_sel)) {
  if (best_diff <= 1) {  # margem aceitável ±1 ponto
    pts_sel <- best_pts
    delta <- best_delta
    message(glue("Aceitando {length(pts_sel)} pontos (margem de ±1) para talhão {idx}"))
  } else {
    message(glue("Não foi possível ajustar pontos para talhão {idx} com n_req = {n_req}"))
    next
  }
}

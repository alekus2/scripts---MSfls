create_points2 <- function(points_list, num_parc, min_dist) {
  points_list <- points_list[!sapply(points_list, is.null)]
  while (TRUE) {
    points2 <- do.call("rbind", points_list)
    non_zero_dists <- as.numeric(st_distance(points2)) != 0
    valid_dists <- as.numeric(st_distance(points2)) < min_dist
    enough_area <- sum(points2$Area) >= 800 & any(points2$Area > 800)
    
    if (enough_area & any(valid_dists & non_zero_dists)) {
      points2 <- points2 %>% filter(Area >= 800)
      
      if (nrow(points2) >= num_parc) {
        points2 <- points2 %>% sample_n(num_parc)
        
        if (any(valid_dists & non_zero_dists)) {
          break
        }
      } else {
        break
      }
    } else {
      if (nrow(points2) >= num_parc) {
        dist_matrix <- st_distance(points2)
        diag(dist_matrix) <- NA
        min_dists <- apply(dist_matrix, 1, min, na.rm = TRUE)
        
        points2 <- points2 %>% mutate(MinDist = min_dists) %>%
          arrange(desc(Area), desc(MinDist))
        
        points2 <- points2[1:num_parc, ]
        break
      } else {
        break
      }
    }
  }
  
  points2 <- points2 %>%
    select("Area", "Index", "PROJETO", "TALHAO", "CICLO", "ROTACAO", "STATUS", 
           "FORMA", "TIPO_INSTA", "TIPO_ATUAL", "DATA", "DATA_ATUAL", "COORD_X",
           "COORD_Y", "geometry")
  
  return(points2)
}
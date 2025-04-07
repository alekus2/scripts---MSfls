split_subgeometries <- function(shape) {
  n <- nrow(shape)
  subgeoms <- vector("list", n)
  
  for (i in 1:n) {
    subgeoms[[i]] <- st_cast(shape[i,], "POLYGON")
  }
  
  return(do.call("rbind", subgeoms))
}
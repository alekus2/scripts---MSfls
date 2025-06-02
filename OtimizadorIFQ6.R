ler_ifq6 <- function(path) {
  df <- tryCatch(read_excel(path, sheet = 0, col_types = "text"), error = function(e) NULL)
  if (is.null(df)) return(NULL)
  names(df) <- toupper(str_trim(names(df)))
  
  # -> aqui:
  # 1) torna os nomes únicos
  names(df) <- make.unique(names(df))
  # 2) mantém só as colunas que você de fato quer
  df <- df[, intersect(cols_esperadas, names(df)), drop = FALSE]
  
  # agora continue sua validação normal
  if (!all(cols_esperadas %in% names(df))) return(NULL)
  df %>% select(all_of(cols_esperadas))
}

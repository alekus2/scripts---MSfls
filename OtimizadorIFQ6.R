ler_ifq6 <- function(path) {
  df <- tryCatch(read_excel(path, sheet = 1), error = function(e) NULL)
  if (is.null(df) || nrow(df) == 0) {
    df <- tryCatch(read_excel(path, sheet = 2), error = function(e) NULL)
  }
  if (is.null(df) || nrow(df) == 0) return(NULL)
  
  # Renomear colunas vazias
  names(df) <- ifelse(names(df) == "", paste0("new_col_", seq_along(df)), names(df))
  
  # Transformar todos os nomes de colunas em maiúsculas
  names(df) <- toupper(str_trim(names(df)))
  
  # Garantir que 'CD_PROJETO' seja sempre character
  if ("CD_PROJETO" %in% names(df)) {
    df <- df %>% mutate(CD_PROJETO = as.character(CD_PROJETO))
  } else {
    warning("A coluna 'CD_PROJETO' não foi encontrada no arquivo: ", path)
    return(NULL)
  }
  
  if (!all(cols_esperadas %in% names(df))) return(NULL)
  df %>% select(all_of(cols_esperadas))
}
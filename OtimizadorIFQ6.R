df_pivot[num_cols] <- lapply(df_pivot[num_cols], as.numeric)

Error in lapply(df_pivot[num_cols], as.numeric) : 
  objeto 'list' não pode ser coercionado ao tipo 'double'

df_pivot <- df_pivot %>%
  mutate(across(all_of(num_cols),
    ~ sapply(.x, function(v) {
        if (length(v) == 0) NA_real_ else as.numeric(v)
      })
  ))

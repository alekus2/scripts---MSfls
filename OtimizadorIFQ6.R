# 6) sequencia
seq_valida <- function(df) {
  df <- df %>%
    mutate(NM_COVA = as.numeric(NM_COVA))  # conversão segura

  last <- NA_real_
  ok <- TRUE
  for (i in seq_len(nrow(df))) {
    cov <- df$NM_COVA[i]
    tipo <- df$CD_01[i]

    if (tipo == "L") {
      if (is.na(last)) last <- cov
      if (!is.na(cov) && cov != last) ok <- FALSE
    }
    if (tipo == "N") {
      if (is.na(last) || is.na(cov) || cov != last + 1) ok <- FALSE
      last <- cov
    }
  }
  ok
}

df_final <- df_final %>%
  mutate(NM_COVA = as.numeric(NM_COVA)) %>%  # <- conversão segura
  arrange(NM_FILA) %>%
  mutate(
    check_sqc    = "OK",
    NM_COVA_ORIG = NM_COVA,
    group_id     = cumsum(NM_FILA != lag(NM_FILA, default = first(NM_FILA)))
  )

bif <- any(!map_lgl(group_split(df_final, NM_FILA), seq_valida))

if (bif) {
  df_final <- df_final %>%
    group_by(group_id) %>%
    mutate(
      new_seq = {
        seqs <- seq_len(n())
        for (i in seq_along(seqs)) {
          if (CD_01[i] == "L") {
            ori <- NM_COVA_ORIG[i]
            if (i > 1 && ori == NM_COVA_ORIG[i - 1]) seqs[i] <- seqs[i - 1]
            else if (i < n() && ori == NM_COVA_ORIG[i + 1]) seqs[i] <- seqs[i + 1]
          }
        }
        seqs
      },
      check_sqc = if_else(row_number() != new_seq, "VERIFICAR", "OK"),
      NM_COVA   = new_seq
    ) %>%
    ungroup() %>%
    select(-new_seq)
} else {
  df_final <- df_final %>%
    arrange(NM_FILA, NM_COVA) %>%
    mutate(
      check_sqc = if_else(
        CD_01 == "N" & lag(CD_01) == "L" &
        lag(NM_FUSTE) == "2" & NM_COVA == lag(NM_COVA),
        "VERIFICAR", "OK"
      )
    )
}

df_final <- df_final %>% select(-NM_COVA_ORIG, -group_id)

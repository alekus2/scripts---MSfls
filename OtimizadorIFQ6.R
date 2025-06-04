library(dplyr)
library(stringr)
library(purrr)
library(glue)
library(openxlsx)

# 1) concatenação e renumeração inicial (zig-zag dentro de cada fila)
df_final <- bind_rows(lista_df) %>%
  mutate(NM_COVA = as.numeric(NM_COVA)) %>%
  group_by(CD_PROJETO, CD_TALHAO, NM_PARCELA, NM_FILA) %>%
  arrange(
    if_else(NM_FILA %% 2 == 1, NM_COVA, -NM_COVA),
    .by_group = TRUE
  ) %>%
  mutate(NM_COVA = row_number()) %>%
  ungroup()

# 2) flags de duplicidade e CD_01 vs NM_FUSTE
dup_cols <- c("CD_PROJETO","CD_TALHAO","NM_PARCELA","NM_FILA","NM_COVA","NM_FUSTE","NM_ALTURA")
df_final <- df_final %>%
  mutate(
    # duplicatas idênticas (ida e volta)
    check_dup = if_else(
      duplicated(across(all_of(dup_cols))) |
      duplicated(across(all_of(dup_cols)), fromLast = TRUE),
      "VERIFICAR", "OK"
    ),
    # se CD_01 indicar L mas fuste ainda é 1, marca para verificar
    check_cd = case_when(
      CD_01 %in% LETTERS[1:24] & NM_FUSTE == "1" ~ "OK",
      CD_01 == "L"      & NM_FUSTE == "1" ~ "VERIFICAR",
      TRUE ~ "OK"
    ),
    # garante formato de 3 dígitos em CD_TALHAO
    CD_TALHAO = str_sub(as.character(CD_TALHAO), -3) %>%
                str_pad(width = 3, pad = "0")
  )

# 3) validação de sequência “L” e “N”
seq_valida <- function(df) {
  last <- NA_real_
  ok   <- TRUE
  for (i in seq_len(nrow(df))) {
    cov  <- df$NM_COVA[i]
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

# prepara para teste por fila
df_final <- df_final %>%
  arrange(NM_FILA) %>%
  mutate(
    check_sqc    = "OK",
    NM_COVA_ORIG = NM_COVA,
    group_id     = cumsum(NM_FILA != lag(NM_FILA, default = first(NM_FILA)))
  )

# verifica se existe alguma fila com sequência inválida
bif <- any(!map_lgl(group_split(df_final, NM_FILA), seq_valida))

if (bif) {
  # para cada grupo (fila), refaz a sequência apenas para marcar onde L quebra
  df_final <- df_final %>%
    group_by(group_id) %>%
    mutate(
      new_seq = {
        seqs <- seq_len(n())
        for (i in seq_along(seqs)) {
          if (CD_01[i] == "L") {
            # se L repetir o NM_COVA do antes ou depois, marca
            if ((i > 1 && NM_COVA_ORIG[i] == NM_COVA_ORIG[i - 1]) ||
                (i < n() && NM_COVA_ORIG[i] == NM_COVA_ORIG[i + 1])) {
              seqs[i] <- if (i > 1 && NM_COVA_ORIG[i] == NM_COVA_ORIG[i - 1]) {
                           seqs[i - 1]
                         } else {
                           seqs[i + 1]
                         }
              check_sqc[i] <<- "VERIFICAR"
            }
          }
        }
        seqs
      },
      # aplica só para sinalizar, não altera a coluna oficial
      NM_COVA = NM_COVA   # mantém original
    ) %>%
    ungroup() %>%
    select(-new_seq)
  
} else {
  # se nunca houve problema de bifurcação
  df_final <- df_final %>%
    arrange(NM_FILA, NM_COVA) %>%
    mutate(
      # ponta de L->N com fuste 2 mas NM_COVA repetido
      check_sqc = if_else(
        CD_01 == "N" & lag(CD_01) == "L" &
        lag(NM_FUSTE) == "2" & NM_COVA == lag(NM_COVA),
        "VERIFICAR", "OK"
      )
    )
}

# limpa colunas auxiliares
df_final <- df_final %>%
  select(-NM_COVA_ORIG, -group_id)

# 4) interatividade para salvar arquivo se houver “VERIFICAR”
qtd_ver <- sum(df_final$check_sqc == "VERIFICAR", na.rm = TRUE)
message("Quantidade de 'VERIFICAR': ", qtd_ver)

if (qtd_ver > 0) {
  resp <- tolower(readline("Deseja verificar agora? (s/n): "))
  if (resp == "s") {
    nome_base <- glue("IFQ6_{nome_mes}_{data_emissao}")
    cnt <- 1
    repeat {
      out <- file.path(pasta_output,
                       glue("{nome_base}_{str_pad(cnt, width = 2, pad = '0')}.xlsx"))
      if (!file.exists(out)) break
      cnt <- cnt + 1
    }
    write.xlsx(df_final, out, rowNames = FALSE)
    message("Dados verificados e salvos em '", out, "'.")
    return(invisible(NULL))
  }
}

# no fim, df_final permanece com NM_COVA e NM_FUSTE originais,
# mas com três colunas de checagem: check_dup, check_cd e check_sqc.

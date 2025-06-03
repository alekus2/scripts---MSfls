# --- Parte 8: geração de tabelas C e D com todas as correções ---

# (A) função de métricas e vetores de códigos
calc_metrics <- function(vals) {
  vals <- vals[!is.na(vals)]
  n    <- length(vals)
  if (n == 0) {
    return(tibble(n = 0, n2 = 0, Mediana = 0, sumHt = 0, sumHt_le = 0, PV50 = 0))
  }
  meio <- floor(n/2)
  med  <- median(vals)
  tot  <- sum(vals)
  ordv <- sort(vals)
  le   <- if (n %% 2 == 0) {
            sum(ordv[1:meio][ordv[1:meio] <= med])
          } else {
            sum(ordv[1:meio]) + med/2
          }
  pv50 <- if (tot > 0) le/tot*100 else 0
  tibble(n = n, n2 = meio, Mediana = med, sumHt = tot, sumHt_le = le, PV50 = pv50)
}
codes  <- c("A","B","D","F","G","H","I","J","L","M","N","O","Q","K","T","V","S","E")
falhas <- c("M","H","F","L","S")

# (B) prepara df_final
df_final <- df_final %>%
  mutate(
    Ht_media         = as.numeric(NM_ALTURA),
    Ht_media         = replace_na(Ht_media, 0),
    NM_COVA_ORDENADO = NM_COVA,
    chave_stand      = paste(CD_PROJETO, CD_TALHAO, NM_PARCELA, sep = "-"),
    dt_medicao1      = DT_INICIAL,
    equipe2          = CD_EQUIPE
  ) %>%
  select(-check_dup, -check_cd, -check_sqc)

# (C) tabela C
pivot_c <- df_final %>%
  pivot_wider(
    id_cols     = c("chave_stand","CD_PROJETO","CD_TALHAO",
                    "NM_PARCELA","NM_AREA_PARCELA"),
    names_from  = NM_COVA_ORDENADO,
    values_from = Ht_media,
    values_fill = list(.default = 0),
    values_fn   = function(x) mean(x, na.rm = TRUE)
  )

covas <- setdiff(names(pivot_c),
                 c("chave_stand","CD_PROJETO","CD_TALHAO","NM_PARCELA","NM_AREA_PARCELA"))

# contagem e garante colunas faltantes
conts <- df_final %>%
  count(CD_PROJETO, CD_TALHAO, NM_PARCELA, CD_01) %>%
  pivot_wider(
    names_from  = CD_01,
    values_from = n,
    values_fill = list(.default = 0)
  )
falt_c <- setdiff(codes, names(conts))
if (length(falt_c) > 0) conts[, falt_c] <- 0
falt_f <- setdiff(falhas, names(conts))
if (length(falt_f) > 0) conts[, falt_f] <- 0

# métricas C
met_c <- pivot_c %>%
  select(all_of(covas)) %>%
  pmap_dfr(~ calc_metrics(c(...)))

df_c <- bind_cols(pivot_c, met_c) %>%
  left_join(conts, by = c("CD_PROJETO","CD_TALHAO","NM_PARCELA")) %>%
  mutate(
    Stand_tree_ha = (rowSums(across(all_of(codes))) -
                     rowSums(across(all_of(falhas)))) *
                    10000 / as.numeric(NM_AREA_PARCELA),
    Pits_ha       = ((n - L) * 10000 / as.numeric(NM_AREA_PARCELA)),
    surv_dec      = (rowSums(across(all_of(codes))) -
                     rowSums(across(all_of(falhas)))) /
                    rowSums(across(all_of(codes))),
    surv_pct      = percent(surv_dec/100, accuracy = 0.1, decimal.mark = ","),
    Pits_por_sob  = Stand_tree_ha / surv_dec,
    Check_pits    = Pits_por_sob - Pits_ha
  ) %>%
  select(-surv_dec)

# (D) tabela D (Ht^3)
pivot_d <- df_final %>%
  mutate(Ht3 = Ht_media^3) %>%
  pivot_wider(
    id_cols     = c("chave_stand","CD_PROJETO","CD_TALHAO",
                    "NM_PARCELA","NM_AREA_PARCELA"),
    names_from  = NM_COVA_ORDENADO,
    values_from = Ht3,
    values_fill = list(.default = 0),
    values_fn   = function(x) mean(x, na.rm = TRUE)
  )

met_d <- pivot_d %>%
  select(all_of(covas)) %>%
  pmap_dfr(~ calc_metrics(c(...)))

df_d <- bind_cols(pivot_d, met_d) %>%
  left_join(conts, by = c("CD_PROJETO","CD_TALHAO","NM_PARCELA")) %>%
  mutate(
    Stand_tree_ha = (rowSums(across(all_of(codes))) -
                     rowSums(across(all_of(falhas)))) *
                    10000 / as.numeric(NM_AREA_PARCELA),
    Pits_ha       = ((n - L) * 10000 / as.numeric(NM_AREA_PARCELA)),
    surv_dec      = (rowSums(across(all_of(codes))) -
                     rowSums(across(all_of(falhas)))) /
                    rowSums(across(all_of(codes))),
    surv_pct      = percent(surv_dec/100, accuracy = 0.1, decimal.mark = ","),
    Check_covas   = Stand_tree_ha / (Pits_ha / Pits_por_sob),
    Check_imp_par = if_else(n %% 2 == 0, "Par", "Impar")
  ) %>%
  select(-surv_dec)

# --- Parte 9: gravação em Excel ---

df_cadastro <- read_excel(cadastro_path, sheet = 1, col_types = "text") %>%
  mutate(index = paste0(`Id Projeto`, Talhao))

wb <- createWorkbook()
addWorksheet(wb, "cadastro_sgf")
writeData(wb, "cadastro_sgf", df_cadastro %>% select(-index))

addWorksheet(wb, glue("dados_cst_{nome_mes}"))
writeData(wb, glue("dados_cst_{nome_mes}"), df_final)

addWorksheet(wb, "C_tabela_resultados")
writeData(wb, "C_tabela_resultados", df_c)

addWorksheet(wb, "D_tabela_resultados_Ht3")
writeData(wb, "D_tabela_resultados_Ht3", df_d)

nome_base2 <- glue("BASE_IFQ6_{nome_mes}_{data_emissao}")
cnt2 <- 1
repeat {
  out2 <- file.path(pasta_output,
                    glue("{nome_base2}_{str_pad(cnt2, width = 2, pad = '0')}.xlsx"))
  if (!file.exists(out2)) break
  cnt2 <- cnt2 + 1
}
saveWorkbook(wb, out2, overwrite = TRUE)
message("Tudo gravado em ", out2)

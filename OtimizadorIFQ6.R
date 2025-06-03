# --- dentro de validacao(), antes de montar tabela C/D ---

# Definição da função de métricas e vetores de códigos
calc_metrics <- function(vals) {
  n    <- length(vals)
  meio <- floor(n/2)
  med  <- if (n>0) median(vals) else 0
  tot  <- sum(vals)
  ordv <- sort(vals)
  le   <- if (n%%2==0) {
            sum(ordv[1:meio][ordv[1:meio] <= med])
          } else {
            sum(ordv[1:meio]) + med/2
          }
  pv50 <- if (tot>0) le/tot*100 else 0.1
  tibble(n = n, n2 = meio, Mediana = med, sumHt = tot, sumHt_le = le, PV50 = pv50)
}
codes  <- c("A","B","D","F","G","H","I","J","L","M","N","O","Q","K","T","V","S","E")
falhas <- c("M","H","F","L","S")

# 8) gera tabelas C e D
df_final <- df_final %>%
  mutate(
    Ht_media         = as.numeric(NM_ALTURA),
    NM_COVA_ORDENADO = NM_COVA,
    chave_stand      = paste(CD_PROJETO, CD_TALHAO, NM_PARCELA, sep = "-"),
    dt_medicao1      = DT_INICIAL,
    equipe2          = CD_EQUIPE
  ) %>%
  select(-check_dup, -check_cd, -check_sqc)

# TABELA C
pivot_c <- df_final %>%
  pivot_wider(
    id_cols     = c("chave_stand","CD_PROJETO","CD_TALHAO",
                    "NM_PARCELA","NM_AREA_PARCELA"),
    names_from  = NM_COVA_ORDENADO,
    values_from = Ht_media,
    values_fill = list(.default = 0),
    values_fn   = mean
  )

covas <- setdiff(
  names(pivot_c),
  c("chave_stand","CD_PROJETO","CD_TALHAO","NM_PARCELA","NM_AREA_PARCELA")
)

met_c <- pivot_c %>%
  select(all_of(covas)) %>%
  pmap_dfr(calc_metrics)

conts <- df_final %>%
  count(CD_PROJETO, CD_TALHAO, NM_PARCELA, CD_01) %>%
  pivot_wider(names_from = CD_01, values_from = n, values_fill = list(.default = 0))

df_c <- bind_cols(pivot_c, met_c) %>%
  left_join(conts, by = c("CD_PROJETO","CD_TALHAO","NM_PARCELA")) %>%
  mutate(
    Stand_tree_ha = (rowSums(across(all_of(codes))) - rowSums(across(all_of(falhas)))) * 10000 / as.numeric(NM_AREA_PARCELA),
    Pits_ha       = ((n - L) * 10000 / as.numeric(NM_AREA_PARCELA)),
    surv_dec      = (rowSums(across(all_of(codes))) - rowSums(across(all_of(falhas)))) / rowSums(across(all_of(codes))),
    surv_pct      = percent(surv_dec/100, accuracy = 0.1, decimal.mark = ","),
    Pits_por_sob  = Stand_tree_ha / surv_dec,
    Check_pits    = Pits_por_sob - Pits_ha
  ) %>%
  select(-surv_dec)

# TABELA D (Ht^3)
pivot_d <- df_final %>%
  mutate(Ht3 = Ht_media^3) %>%
  pivot_wider(
    id_cols     = c("chave_stand","CD_PROJETO","CD_TALHAO",
                    "NM_PARCELA","NM_AREA_PARCELA"),
    names_from  = NM_COVA_ORDENADO,
    values_from = Ht3,
    values_fill = list(.default = 0),
    values_fn   = mean
  )

met_d <- pivot_d %>%
  select(all_of(covas)) %>%
  pmap_dfr(calc_metrics)

df_d <- bind_cols(pivot_d, met_d) %>%
  left_join(conts, by = c("CD_PROJETO","CD_TALHAO","NM_PARCELA")) %>%
  mutate(
    Stand_tree_ha  = (rowSums(across(all_of(codes))) - rowSums(across(all_of(falhas)))) * 10000 / as.numeric(NM_AREA_PARCELA),
    Pits_ha        = ((n - L) * 10000 / as.numeric(NM_AREA_PARCELA)),
    surv_dec       = (rowSums(across(all_of(codes))) - rowSums(across(all_of(falhas)))) / rowSums(across(all_of(codes))),
    surv_pct       = percent(surv_dec/100, accuracy = 0.1, decimal.mark = ","),
    Check_covas    = Stand_tree_ha / (Pits_ha / Pits_por_sob),
    Check_imp_par  = if_else(n %% 2 == 0, "Par", "Impar")
  ) %>%
  select(-surv_dec)

# … siga com a gravação em Excel normalmente …

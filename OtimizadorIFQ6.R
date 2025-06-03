# --- defina calc_metrics, codes e falhas ANTES desse trecho ---

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
  pmap_dfr(function(...) {
    calc_metrics(c(...))
  })

conts <- df_final %>%
  count(CD_PROJETO, CD_TALHAO, NM_PARCELA, CD_01) %>%
  pivot_wider(names_from = CD_01,
              values_from = n,
              values_fill  = list(.default = 0))

df_c <- bind_cols(pivot_c, met_c) %>%
  left_join(conts, by = c("CD_PROJETO","CD_TALHAO","NM_PARCELA")) %>%
  mutate(
    Stand_tree_ha = (rowSums(across(all_of(codes))) -
                     rowSums(across(all_of(falhas)))) * 10000 /
                    as.numeric(NM_AREA_PARCELA),
    Pits_ha       = ((n - L) * 10000 / as.numeric(NM_AREA_PARCELA)),
    surv_dec      = (rowSums(across(all_of(codes))) -
                     rowSums(across(all_of(falhas)))) /
                    rowSums(across(all_of(codes))),
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
  pmap_dfr(function(...) {
    calc_metrics(c(...))
  })

df_d <- bind_cols(pivot_d, met_d) %>%
  left_join(conts, by = c("CD_PROJETO","CD_TALHAO","NM_PARCELA")) %>%
  mutate(
    Stand_tree_ha  = (rowSums(across(all_of(codes))) -
                      rowSums(across(all_of(falhas)))) * 10000 /
                     as.numeric(NM_AREA_PARCELA),
    Pits_ha        = ((n - L) * 10000 / as.numeric(NM_AREA_PARCELA)),
    surv_dec       = (rowSums(across(all_of(codes))) -
                      rowSums(across(all_of(falhas)))) /
                     rowSums(across(all_of(codes))),
    surv_pct       = percent(surv_dec/100, accuracy = 0.1, decimal.mark = ","),
    Check_covas    = Stand_tree_ha / (Pits_ha / Pits_por_sob),
    Check_imp_par  = if_else(n %% 2 == 0, "Par", "Impar")
  ) %>%
  select(-surv_dec)

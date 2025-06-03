      # 8) gera tabelas C e D
      df_final <- df_final %>%
        # garante NM_COVA (já renumerado) e cria as colunas que faltavam:
        mutate(
          Ht_media         = as.numeric(NM_ALTURA),
          NM_COVA_ORDENADO = NM_COVA,
          chave_stand      = paste(CD_PROJETO, CD_TALHAO, NM_PARCELA, sep = "-"),
          dt_medicao1      = DT_INICIAL,
          equipe2          = CD_EQUIPE
        ) %>%
        select(-check_dup, -check_cd, -check_sqc)

      # agora sim pivota para montar a tabela C
      pivot_c <- df_final %>%
        pivot_wider(
          id_cols    = c("Ht_media","chave_stand","CD_PROJETO","CD_TALHAO","NM_PARCELA","NM_AREA_PARCELA"),
          names_from = NM_COVA_ORDENADO,
          values_from= Ht_media,
          values_fill= 0
        )
      covas <- setdiff(names(pivot_c), c("Ht_media","chave_stand","CD_PROJETO","CD_TALHAO","NM_PARCELA","NM_AREA_PARCELA"))
      met_c <- pivot_c %>%
        select(all_of(covas)) %>%
        pmap_dfr(calc_metrics)
      conts <- df_final %>%
        count(CD_PROJETO, CD_TALHAO, NM_PARCELA, CD_01) %>%
        pivot_wider(names_from=CD_01, values_from=n, values_fill=0)
      df_c <- bind_cols(pivot_c, met_c) %>%
        left_join(conts, by=c("CD_PROJETO","CD_TALHAO","NM_PARCELA")) %>%
        replace_na(list()) %>%
        mutate(
          Stand_tree_ha = (rowSums(across(all_of(codes))) - rowSums(across(all_of(falhas)))) * 10000 / as.numeric(NM_AREA_PARCELA),
          Pits_ha       = ((n - L)*10000 / as.numeric(NM_AREA_PARCELA)),
          surv_dec      = (rowSums(across(all_of(codes))) - rowSums(across(all_of(falhas)))) / rowSums(across(all_of(codes))),
          surv_pct      = percent(surv_dec/100, accuracy=0.1, decimal.mark=","),
          Pits_por_sob  = Stand_tree_ha / surv_dec,
          Check_pits    = Pits_por_sob - Pits_ha
        ) %>%
        select(-surv_dec)

      # e para a tabela D, aproveitamos essa mesma Ht_media:
      pivot_d <- df_final %>%
        mutate(Ht3 = Ht_media^3) %>%
        pivot_wider(
          id_cols    = c("Ht_media","chave_stand","CD_PROJETO","CD_TALHAO","NM_PARCELA","NM_AREA_PARCELA"),
          names_from = NM_COVA_ORDENADO,
          values_from= Ht3,
          values_fill= 0
        )
      covas_d <- covas
      met_d <- pivot_d %>%
        select(all_of(covas_d)) %>%
        pmap_dfr(calc_metrics)
      df_d <- bind_cols(pivot_d, met_d) %>%
        left_join(conts, by=c("CD_PROJETO","CD_TALHAO","NM_PARCELA")) %>%
        replace_na(list()) %>%
        mutate(
          Stand_tree_ha = (rowSums(across(all_of(codes))) - rowSums(across(all_of(falhas)))) * 10000 / as.numeric(NM_AREA_PARCELA),
          Pits_ha       = ((n - L)*10000 / as.numeric(NM_AREA_PARCELA)),
          surv_dec      = (rowSums(across(all_of(codes))) - rowSums(across(all_of(falhas)))) / rowSums(across(all_of(codes))),
          surv_pct      = percent(surv_dec/100, accuracy=0.1, decimal.mark=","),
          Check_covas   = Stand_tree_ha / (Pits_ha/Pits_por_sob),
          Check_imp_par = if_else(n%%2==0, "Par","Impar")
        ) %>%
        select(-surv_dec)

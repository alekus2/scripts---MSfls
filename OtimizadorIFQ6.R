   conts <- df_final %>%
     count(CD_PROJETO, CD_TALHAO, NM_PARCELA, CD_01) %>%
     pivot_wider(
       names_from  = CD_01,
       values_from = n,
       values_fill = list(.default = 0)
     )

+  # Garante que conts tenha TODAS as colunas de 'codes' e 'falhas'
+  faltantes <- setdiff(codes, names(conts))
+  if (length(faltantes) > 0) {
+    conts <- conts %>% mutate(across(all_of(faltantes), ~ 0))
+  }
+  faltantes_f <- setdiff(falhas, names(conts))
+  if (length(faltantes_f) > 0) {
+    conts <- conts %>% mutate(across(all_of(faltantes_f), ~ 0))
+  }

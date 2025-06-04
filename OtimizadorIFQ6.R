                                # 5) concatenação e verificações iniciais
                                df_final <- bind_rows(lista_df) %>%
                                  mutate(NM_COVA = as.numeric(NM_COVA)) %>%
                                  arrange(CD_PROJETO, CD_TALHAO, NM_PARCELA, NM_FILA, NM_COVA) %>% #ele deveria toda vez que ele contasse cd_projeto,cd_talhao_nm_parcela e nm_fila toda vez que um desses mudasse ele reiniciasse a contage, indo 1,2,3,4,5,6 sequencialmente e claro que seguindo a regra da bifurcação do L.
                                  group_by(CD_PROJETO, CD_TALHAO, NM_PARCELA, NM_FILA) %>%
                                  mutate(NM_COVA = row_number()) %>%
                                  ungroup()

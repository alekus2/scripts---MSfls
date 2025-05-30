library(lubridate)

# Dentro da função process_data, logo antes do return
bind_rows(result_pts) %>%
  group_by(Index) %>%
  mutate(
    NM_PARCELA = row_number(),
    mes_prog = paste(month(DATA_PLANT, label = TRUE, abbr = FALSE), 
                     format(DATA_PLANT, "%Y"), sep = "-")  # Nome do mês completo e ano
  ) %>%
  ungroup() %>%
  select(
    everything(),  # Mantém todas as colunas
    NM_PARCELA,     # Coloca NM_PARCELA na posição desejada
    mes_prog        # Coloca mes_prog na posição desejada
  )
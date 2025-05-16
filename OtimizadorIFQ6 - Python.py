# formata PV50 com duas casas decimais e vírgula como separador
df_tabela["PV50"] = df_tabela["PV50"].map(lambda x: f"{x:.2f}".replace(".", ","))

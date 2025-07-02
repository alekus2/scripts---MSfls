# Remover a máscara para o ano atual
# mask = novo_df["Year/Month Measurement"] == ano_atual

# Criar uma nova coluna "Ordem Mês" com base em todos os meses
novo_df["Ordem Mês"] = novo_df["Months"].str.split("/").str[0].map(mapeamento)

# Se "Ordem Mês" tiver que ser numérica, você pode usar a seguinte linha:
novo_df["Ordem Mês"] = novo_df["Ordem Mês"].fillna(0).astype(int)

# Não é mais necessário remover a coluna "Month" pois não a estamos utilizando
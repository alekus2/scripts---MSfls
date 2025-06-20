ano_atual = datetime.now().year

# prepara a coluna em branco
novo_df["Ordem Mês"] = ""

# cria o mapping de meses pra números
mapeamento = {
    "January":   1, "February":  2, "March":     3,
    "April":     4, "May":       5, "June":      6,
    "July":      7, "August":    8, "September": 9,
    "October":  10, "November": 11, "December": 12
}

# máscara só para linhas de 2025
mask = novo_df["Year/Month Measurement"] == ano_atual

# extrai o nome do mês (antes de “/”) **apenas** nessas linhas
novo_df.loc[mask, "Month"] = novo_df.loc[mask, "Months"].str.split("/").str[0]

# mapeia para o número do mês **apenas** nessas linhas
novo_df.loc[mask, "Ordem Mês"] = novo_df.loc[mask, "Month"].map(mapeamento)

# (opcional) se não quiser a coluna auxiliar “Month” no arquivo final
# novo_df.drop(columns=["Month"], inplace=True)

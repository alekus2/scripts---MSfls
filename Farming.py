# Adicione isso antes da linha que mapeia os meses
ano_atual = datetime.now().year

# Atualize essa parte do código
if ano_atual in novo_df["Year/Month Measurement"].values:  # Verifique se o ano atual está na coluna
    mapeamento = {
        "Janeiro":   1,
        "Fevereiro": 2,
        "Março":     3,
        "Abril":     4,
        "Maio":      5,
        "Junho":     6,
        "Julho":     7,
        "Agosto":    8,
        "Setembro":  9,
        "Outubro":   10,
        "Novembro":  11,
        "Dezembro":  12
    }
    novo_df["Ordem Mês"] = novo_df["Months"].map(mapeamento)
else:
    novo_df["Ordem Mês"] = ""  # Deixa em branco se o ano não for o atual
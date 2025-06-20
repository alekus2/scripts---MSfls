# ... depois de criar novo_df e mapear "Ordem Class", antes de extrair o mês:

ano_atual = datetime.now().year

# 1) Filtra só as linhas em que Year/Month Measurement == ano_atual
#    (ajuste o tipo se necessário — aqui assumo que são ints)
mask = novo_df["Year/Month Measurement"] == ano_atual
if mask.any():
    novo_df = novo_df.loc[mask].copy()  # copia só 2025

    # 2) Extrai o nome do mês e converte em número de ordem
    mapeamento = {
        "January":   1, "February":  2, "March":     3,
        "April":     4, "May":       5, "June":      6,
        "July":      7, "August":    8, "September": 9,
        "October":  10, "November": 11, "December": 12
    }
    # supondo que "Months" seja algo como "June/2025"
    novo_df["Month"] = novo_df["Months"].str.split("/").str[0]
    novo_df["Ordem Mês"] = novo_df["Month"].map(mapeamento)
else:
    # se realmente não tiver linha de 2025
    novo_df["Ordem Mês"] = ""
    print("Ano atual não encontrado.")

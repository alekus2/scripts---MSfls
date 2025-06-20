import pandas as pd
from datetime import datetime

# Supondo que você já tenha carregado seu DataFrame
# novo_df = pd.read_excel('caminho/do/arquivo.xlsx')

ano_atual = datetime.now().year

# Verifique se o ano atual está na coluna
if ano_atual in novo_df["Year/Month Measurement"].values:
    print("Ano atual encontrado.")
    
    # Mapeamento de meses em inglês para números
    mapeamento = {
        "January":   1,
        "February":  2,
        "March":     3,
        "April":     4,
        "May":       5,
        "June":      6,
        "July":      7,
        "August":    8,
        "September": 9,
        "October":   10,
        "November":  11,
        "December":  12
    }
    
    # Extrair o mês do formato "June/2025"
    novo_df["Month"] = novo_df["Months"].str.split('/').str[0]  # Pega a parte do mês
    novo_df["Ordem Mês"] = novo_df["Month"].map(mapeamento)  # Mapeia para o número do mês
    
    # Limpar a coluna "Month" se necessário
    novo_df.drop(columns=["Month"], inplace=True)

    print(novo_df[["Months", "Ordem Mês"]].head())
else:
    novo_df["Ordem Mês"] = ""  # Deixa em branco se o ano não for o atual
    print("Ano atual não encontrado.")
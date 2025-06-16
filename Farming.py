# logo após criar novo_df:
if "Final classification" in novo_df.columns:
    mapeamento = {
        "Bad":   1,
        "Weak":  2,
        "Good":  3,
        "Great": 4
    }
    # Cria a coluna 'Ordem Class' aplicando o mapping; valores não encontrados ficam NaN
    novo_df["Ordem Class"] = novo_df["Final classification"].map(mapeamento)

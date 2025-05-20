# Criação da tabela D_Tabela_Resultados_Ht3 com valores de NM_COVA_ORDENADO ao cubo
        df_D_tabela = df_tabela.copy()

        # Elevar ao cubo apenas as colunas que correspondem a NM_COVA_ORDENADO
        cols_cova_ordenado = [col for col in df_D_tabela.columns if col.isdigit()]  # supõe que colunas numéricas são as que têm nome de número
        for col in cols_cova_ordenado:
            df_D_tabela[col] = df_D_tabela[col] ** 3

        # Calcular as métricas para D_Tabela_Resultados_Ht3
        metrics_D = df_D_tabela.apply(_calc_row, axis=1)
        df_D_tabela = pd.concat([df_D_tabela, metrics_D], axis=1)

        df_D_tabela["PV50"] = df_D_tabela["PV50"].map(lambda x: f"{x:.2f}%".replace(".", ","))
        
        # Adicionar D_Tabela_Resultados_Ht3 ao arquivo Excel
        with pd.ExcelWriter(out, engine="openpyxl", mode='a') as w:  # mode='a' para adicionar novas abas
            df_D_tabela.to_excel(w, sheet_name="D_Tabela_Resultados_Ht3", index=False)
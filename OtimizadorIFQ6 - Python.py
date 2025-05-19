        # … logo após calcular '%_Sobrevivência':

        # Pits/ha: (n − L) * 10000 / nm_area_parcela
        df_tabela["Pits/ha"] = (
            (df_tabela["n"] - df_tabela["L"])
            * 10000
            / df_tabela["nm_area_parcela"].astype(float)
        ).fillna(0)

        # CST: só concatena CD_TALHAO e nm_parcela com "-"
        df_tabela["CST"] = df_tabela["CD_TALHAO"].astype(str) + "-" + df_tabela["nm_parcela"].astype(str)

        # Pits por sob: Stand(tree/ha) dividido por %_Sobrevivência (como fração), arredondando para cima
        pct = (
            df_tabela["%_Sobrevivência"]
            .str.replace("%","")
            .str.replace(",",".")
            .astype(float)
            / 100
        )
        df_tabela["Pits por sob"] = (
            df_tabela["Stand (tree/ha)"] / pct
        ).apply(math.ceil)

        # Check pits segue igual: diferença entre Pits por sob e Pits/ha
        df_tabela["Check pits"] = df_tabela["Pits por sob"] - df_tabela["Pits/ha"]

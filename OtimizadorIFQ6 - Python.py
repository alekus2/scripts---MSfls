        # processa parte 2
        df_cadastro = pd.read_excel(cadastro_path, sheet_name=0, dtype=str)
        cols_cad = df_cadastro.columns.tolist()
        area_col = next((c for c in cols_cad if "AREA" in c.upper()), None)
        df_cadastro["Index"] = df_cadastro["Id Projeto"].str.strip() + df_cadastro["Talhão"].str.strip()

        df_final["Index"] = (
            df_final["CD_PROJETO"].astype(str).str.strip() +
            df_final["CD_TALHAO"].astype(str).str.strip()
        )

        df_res = pd.merge(
            df_final,
            df_cadastro[["Index", area_col]],
            on="Index",
            how="left"
        )

        # renomeia colunas para o padrão que vamos usar
        df_res.rename(columns={
            area_col:          "Área(ha)",
            "Chave_stand_1":   "Chave_stand_1",
            "NM_PARCELA":      "nm_parcela",
            "NM_AREA_PARCELA": "nm_area_parcela",
            "Ht média":        "Ht média"   # só pra garantir que existe
        }, inplace=True)

        # garante que Ht média é número
        df_res["Ht média"] = pd.to_numeric(df_res["Ht média"], errors="coerce").fillna(0)

        # debug: veja se df_res tem dados
        print("=== DEBUG df_res.head() ===")
        print(df_res[["Área(ha)", "Chave_stand_1", "CD_PROJETO", "CD_TALHAO", "nm_parcela", "nm_area_parcela", "NM_COVA_ORDENADO", "Ht média"]].head())

        cols0 = ["Área(ha)", "Chave_stand_1", "CD_PROJETO", "CD_TALHAO", "nm_parcela", "nm_area_parcela"]
        df_res = df_res[cols0 + ["NM_COVA_ORDENADO", "Ht média"]]

        df_pivot = df_res.pivot_table(
            index=cols0,
            columns="NM_COVA_ORDENADO",
            values="Ht média",
            aggfunc="first",
            fill_value=0
        ).reset_index()

        df_pivot.columns = [str(c) if isinstance(c, int) else c for c in df_pivot.columns]
        num_cols = sorted([c for c in df_pivot.columns if c.isdigit()], key=lambda x: int(x))
        df_tabela = df_pivot[cols0 + num_cols]

        nome_base = f"BASE_IFQ6_{nome_mes}_{data_emissao}"
        cnt = 1
        out = os.path.join(pasta_output, f"{nome_base}_{str(cnt).zfill(2)}.xlsx")
        while os.path.exists(out):
            cnt += 1
            out = os.path.join(pasta_output, f"{nome_base}_{str(cnt).zfill(2)}.xlsx")

        with pd.ExcelWriter(out, engine="openpyxl") as w:
            df_cadastro.to_excel(w, sheet_name="Cadastro_SGF", index=False)
            df_final.to_excel(w, sheet_name=f"Dados_CST_{nome_mes}", index=False)
            df_tabela.to_excel(w, sheet_name="C_tabela_resultados", index=False)

        print(f"✅ Tudo gravado em '{out}'")

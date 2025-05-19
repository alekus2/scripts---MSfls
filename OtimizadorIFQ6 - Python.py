import pandas as pd
import os
import numpy as np
from datetime import datetime
import math

class OtimizadorIFQ6:
    def validacao(self, paths):
        nomes_colunas = [
            "CD_PROJETO","CD_TALHAO","NM_PARCELA","DC_TIPO_PARCELA","NM_AREA_PARCELA",
            "NM_LARG_PARCELA","NM_COMP_PARCELA","NM_DEC_LAR_PARCELA","NM_DEC_COM_PARCELA",
            "DT_INICIAL","DT_FINAL","CD_EQUIPE","NM_LATITUDE","NM_LONGITUDE","NM_ALTITUDE",
            "DC_MATERIAL","NM_FILA","NM_COVA","NM_FUSTE","NM_DAP_ANT","NM_ALTURA_ANT",
            "NM_CAP_DAP1","NM_DAP2","NM_DAP","NM_ALTURA","CD_01","CD_02","CD_03"
        ]
        lista_df, equipes = [], {}
        meses = ["Janeiro","Fevereiro","Março","Abril","Maio","Junho",
                 "Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"]
        nome_mes = meses[datetime.now().month-1]
        data_emissao = datetime.now().strftime("%Y%m%d")
        pasta_output = os.path.join(os.path.dirname(os.path.dirname(paths[0])), nome_mes, "output")
        os.makedirs(pasta_output, exist_ok=True)
        cadastro_path = next((p for p in paths if "SGF" in os.path.basename(p).upper()), None)

        for path in paths:
            if path == cadastro_path or not os.path.exists(path):
                continue
            nome = os.path.basename(path).upper()
            if "LEBATEC" in nome:
                base = "lebatec"
            elif "BRAVORE" in nome:
                base = "bravore"
            elif "PROPRIA" in nome:
                base = "propria"
            else:
                while True:
                    e = input("Selecione a equipe (1-LEBATEC,2-BRAVORE,3-PROPRIA):")
                    if e in ["1","2","3"]:
                        break
                base = ["lebatec","bravore","propria"][int(e)-1]
            equipes[base] = equipes.get(base,0) + 1
            equipe = base if equipes[base] == 1 else f"{base}_{equipes[base]:02d}"
            try:
                df = pd.read_excel(path, sheet_name=0)
            except:
                continue
            df.columns = [str(c).strip().upper() for c in df.columns]
            falt = [c for c in nomes_colunas if c not in df.columns]
            if falt:
                try:
                    df = pd.read_excel(path, sheet_name=1)
                    df.columns = [str(c).strip().upper() for c in df.columns]
                    falt = [c for c in nomes_colunas if c not in df.columns]
                    if falt:
                        continue
                except:
                    continue
            dff = df[nomes_colunas].copy()
            dff["EQUIPE"] = equipe
            lista_df.append(dff)

        if not lista_df:
            print("❌ Nenhum arquivo processado.")
            return

        df_final = pd.concat(lista_df, ignore_index=True)

        dup = ['CD_PROJETO','CD_TALHAO','NM_PARCELA','NM_FILA','NM_COVA','NM_FUSTE','NM_ALTURA']
        df_final["check dup"] = df_final.duplicated(subset=dup, keep=False).map({True:"VERIFICAR",False:"OK"})
        df_final["check cd"] = df_final.apply(
            lambda r: "VERIFICAR" if r["CD_01"] == "L" and r["NM_FUSTE"] == 1 else "OK",
            axis=1
        )
        df_final["CD_TALHAO"] = df_final["CD_TALHAO"].astype(str).str[-3:].str.zfill(3)

        def seq(g):
            last = None
            for _, r in g.iterrows():
                if r["CD_01"] == "L":
                    last = r["NM_COVA"] if last is None else last
                    if r["NM_COVA"] != last:
                        return False
                if r["CD_01"] == "N":
                    if last is None or r["NM_COVA"] != last + 1:
                        return False
                    last = r["NM_COVA"]
            return True

        bif = any(not seq(g) for _, g in df_final.groupby("NM_FILA"))
        df_final["check SQC"] = "OK"
        df_final["NM_COVA_ORIG"] = df_final["NM_COVA"]
        df_final["group_id"] = (df_final["NM_FILA"] != df_final["NM_FILA"].shift()).cumsum()

        if bif:
            for _, g in df_final.groupby("group_id"):
                idxs = list(g.index)
                seqs = list(range(1, len(idxs) + 1))
                for i, idx in enumerate(idxs):
                    if df_final.at[idx, "CD_01"] == "L":
                        ori = df_final.at[idx, "NM_COVA_ORIG"]
                        if i > 0 and ori == df_final.at[idxs[i-1], "NM_COVA_ORIG"]:
                            seqs[i] = seqs[i-1]
                        elif i < len(idxs)-1 and ori == df_final.at[idxs[i+1], "NM_COVA_ORIG"]:
                            seqs[i] = seqs[i+1]
                            df_final.at[idx, "check SQC"] = "VERIFICAR"
                for i, idx in enumerate(idxs):
                    df_final.at[idx, "NM_COVA"] = seqs[i]
        else:
            for i in range(1, len(df_final)):
                a, b = df_final.iloc[i], df_final.iloc[i-1]
                if (a["NM_COVA"] == b["NM_COVA"] and
                    a["CD_01"] == "N" and b["CD_01"] == "L" and
                    b["NM_FUSTE"] == 2):
                    df_final.at[a.name, "check SQC"] = "VERIFICAR"

        df_final.drop(["NM_COVA_ORIG","group_id"], axis=1, inplace=True)
        print(f"Quantidade de 'VERIFICAR': {df_final['check SQC'].eq('VERIFICAR').sum()}")

        df_final["Ht média"] = df_final["NM_ALTURA"].fillna(0)
        df_final = df_final.sort_values(["CD_PROJETO","CD_TALHAO","NM_PARCELA","Ht média"])
        df_final["NM_COVA_ORDENADO"] = df_final.groupby(
            ["CD_PROJETO","CD_TALHAO","NM_PARCELA"]
        ).cumcount() + 1

        df_final["Chave_stand_1"] = (
            df_final["CD_PROJETO"].astype(str) + "-" +
            df_final["CD_TALHAO"].astype(str) + "-" +
            df_final["NM_PARCELA"].astype(str)
        )
        df_final["DT_MEDIÇÃO1"] = df_final["DT_INICIAL"]
        df_final["EQUIPE_2"] = df_final["CD_EQUIPE"]
        df_final.drop(["check dup","check cd","check SQC"], axis=1, inplace=True)

        df_cadastro = pd.read_excel(cadastro_path, sheet_name=0, dtype=str)
        df_cadastro["Talhão_z3"] = df_cadastro["Talhão"].str[-3:].str.zfill(3)
        df_cadastro["Index_z3"] = df_cadastro["Id Projeto"].str.strip() + df_cadastro["Talhão_z3"]
        df_final["Index_z3"] = df_final["CD_PROJETO"].str.strip() + df_final["CD_TALHAO"].str.strip()

        area_col = next(c for c in df_cadastro.columns if "ÁREA" in c.upper())
        df_res = df_final.merge(df_cadastro[["Index_z3", area_col]], on="Index_z3", how="left")
        df_res.rename(columns={area_col: "Área (ha)", "NM_PARCELA": "nm_parcela", "NM_AREA_PARCELA": "nm_area_parcela"}, inplace=True)
        df_res["Área (ha)"] = df_res["Área (ha)"].fillna("")

        cols0 = ["Área (ha)", "Chave_stand_1", "CD_PROJETO", "CD_TALHAO", "nm_parcela", "nm_area_parcela"]
        df_res["Ht média"] = pd.to_numeric(df_res["Ht média"], errors="coerce").fillna(0)
        df_pivot = df_res.pivot_table(index=cols0, columns="NM_COVA_ORDENADO", values="Ht média", aggfunc="first", fill_value=0).reset_index()
        df_pivot.columns = [str(c) if isinstance(c, int) else c for c in df_pivot.columns]
        num_cols = sorted([c for c in df_pivot.columns if c.isdigit()], key=lambda x: int(x))
        df_tabela = df_pivot[cols0 + num_cols]

        counts = df_final.groupby(["CD_PROJETO","CD_TALHAO","NM_PARCELA"])["CD_01"].value_counts().unstack(fill_value=0)
        codes_to_count = ["A","B","D","F","G","H","I","J","L","M","N","O","Q","K","T","V","S","E"]
        falhas = ["M","H","F","L","S"]
        counts = counts.reindex(columns=codes_to_count, fill_value=0).reset_index()
        df_tabela = df_tabela.merge(
            counts,
            left_on=["CD_PROJETO","CD_TALHAO","nm_parcela"],
            right_on=["CD_PROJETO","CD_TALHAO","NM_PARCELA"],
            how="left"
        ).fillna(0)

        df_tabela["Stand (tree/ha)"] = (
            df_tabela[codes_to_count].sum(axis=1)
            - df_tabela[falhas].sum(axis=1)
        ) * 10000 / df_tabela["nm_area_parcela"].astype(float)

        total = df_tabela[codes_to_count].sum(axis=1)
        valid = df_tabela[codes_to_count].sum(axis=1) - df_tabela[falhas].sum(axis=1)
        df_tabela["%_Sobrevivência"] = (
            (valid / total * 100).round(1)
            .map(lambda x: f"{x:.1f}%".replace(".",","))
        )

        df_tabela["Pits/ha"] = (
            df_tabela["n"]
            / df_tabela["L"].replace(0, np.nan)
            * 10000
            / df_tabela["nm_area_parcela"].astype(float)
        ).fillna(0)

        df_tabela["CST"] = df_tabela["CD_TALHAO"].astype(str) + "-" + df_tabela["nm_parcela"].astype(str)
        pct = df_tabela["%_Sobrevivência"].str.replace("%","").str.replace(",",".").astype(float) / 100
        df_tabela["Pits por sob"] = (df_tabela["Stand (tree/ha)"] / pct).apply(math.ceil)
        df_tabela["Check pits"] = df_tabela["Pits por sob"] - df_tabela["Pits/ha"]

        nome_base = f"BASE_IFQ6_{nome_mes}_{data_emissao}"
        cnt = 1
        out = os.path.join(pasta_output, f"{nome_base}_{str(cnt).zfill(2)}.xlsx")
        while os.path.exists(out):
            cnt += 1
            out = os.path.join(pasta_output, f"{nome_base}_{str(cnt).zfill(2)}.xlsx")

        with pd.ExcelWriter(out, engine="openpyxl") as w:
            df_cadastro.drop(["Talhão_z3","Index_z3"], axis=1, inplace=True)
            df_cadastro.to_excel(w, sheet_name="Cadastro_SGF", index=False)
            df_final.drop("Index_z3", axis=1, inplace=True)
            df_final.to_excel(w, sheet_name=f"Dados_CST_{nome_mes}", index=False)
            df_tabela.to_excel(w, sheet_name="C_tabela_resultados", index=False)

        print(f"✅ Tudo gravado em '{out}'")

import pandas as pd
import numpy as np
import os
import math
from datetime import datetime

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
            na = os.path.basename(path).upper()
            if "LEBATEC" in na:
                base = "lebatec"
            elif "BRAVORE" in na:
                base = "bravore"
            elif "PROPRIA" in na:
                base = "propria"
            else:
                escolha = input("1-LEBATEC,2-BRAVORE,3-PROPRIA:")
                base = ["lebatec","bravore","propria"][int(escolha)-1]
            equipes[base] = equipes.get(base,0) + 1
            equipe = base if equipes[base]==1 else f"{base}_{equipes[base]:02d}"
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
        df_final["CD_TALHAO"] = df_final["CD_TALHAO"].astype(str).str[-3:].str.zfill(3)
        df_final["Ht média"] = df_final["NM_ALTURA"].fillna(0)
        df_final.sort_values(by=["CD_PROJETO","CD_TALHAO","NM_PARCELA","Ht média"], inplace=True)
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
        df_cadastro = pd.read_excel(cadastro_path, sheet_name=0, dtype=str)
        df_cadastro["Talhão_z3"] = df_cadastro["Talhão"].str[-3:].str.zfill(3)
        df_cadastro["Index_z3"] = df_cadastro["Id Projeto"].str.strip() + df_cadastro["Talhão_z3"]
        df_final["Index_z3"] = df_final["CD_PROJETO"].astype(str).str.strip() + df_final["CD_TALHAO"].astype(str).str.strip()
        area_col = next((c for c in df_cadastro.columns if "ÁREA" in c.upper()), None)
        df_res = pd.merge(
            df_final,
            df_cadastro[["Index_z3", area_col]],
            on="Index_z3", how="left"
        )
        df_res.rename(columns={area_col: "Área (ha)"}, inplace=True)
        df_res["Área (ha)"] = df_res["Área (ha)"].fillna("")
        df_res.rename(columns={"NM_PARCELA":"nm_parcela","NM_AREA_PARCELA":"nm_area_parcela"}, inplace=True)
        cols0 = ["Área (ha)","Chave_stand_1","CD_PROJETO","CD_TALHAO","nm_parcela","nm_area_parcela"]
        df_res["Ht média"] = pd.to_numeric(df_res["Ht média"], errors="coerce").fillna(0)
        codes = ["A","B","D","F","G","H","I","J","L","M","N","O","Q","K","T","V","S","E"]
        falhas = ["M","H","F","L","S"]

        def calc_metrics(row, covas):
            vals = [row[c] for c in covas]
            last = max([i for i,v in enumerate(vals) if v>0], default=-1)
            vals = vals[:last+1] if last>=0 else []
            n = len(vals)
            med = np.median(vals) if n>0 else 0.0
            tot = sum(vals)
            ordered = sorted(vals)
            meio = n//2
            le = sum(v for v in ordered[:meio] if v<=med) if n%2==0 else sum(ordered[:meio]) + med/2.0
            pv50 = (le/tot*100) if tot else 0.0
            return pd.Series({"n":n,"n/2":meio,"Mediana":med,"∑Ht":tot,"∑Ht(<=Med)":le,"PV50":pv50})

        df_pivot = df_res.pivot_table(
            index=cols0,
            columns="NM_COVA_ORDENADO",
            values="Ht média",
            aggfunc="first",
            fill_value=0
        ).reset_index()
        df_pivot.columns = [str(c) if isinstance(c,int) else c for c in df_pivot.columns]
        num_cols = sorted([c for c in df_pivot.columns if c.isdigit()], key=int)

        df_tabela = pd.concat(
            [df_pivot[cols0 + num_cols], df_pivot.apply(calc_metrics, axis=1, covas=num_cols)],
            axis=1
        )
        counts = (
            df_final
            .groupby(["CD_PROJETO","CD_TALHAO","NM_PARCELA"])["CD_01"]
            .value_counts()
            .unstack(fill_value=0)
            .reindex(columns=codes, fill_value=0)
            .reset_index()
        )
        df_tabela = df_tabela.merge(
            counts,
            left_on=["CD_PROJETO","CD_TALHAO","nm_parcela"],
            right_on=["CD_PROJETO","CD_TALHAO","NM_PARCELA"],
            how="left"
        ).fillna(0)
        df_tabela["Stand (tree/ha)"] = (
            df_tabela[codes].sum(axis=1) - df_tabela[falhas].sum(axis=1)
        ) * 10000 / df_tabela["nm_area_parcela"].astype(float)
        df_tabela["Pits/ha"] = (
            (df_tabela["n"] - df_tabela["L"]) * 10000
            / df_tabela["nm_area_parcela"].astype(float)
        ).fillna(0)
        medianas = (
            df_final
            .groupby(["CD_PROJETO","CD_TALHAO"])["Ht média"]
            .median()
            .reset_index(name="Média Ht")
        )
        df_tabela = df_tabela.merge(medianas, on=["CD_PROJETO","CD_TALHAO"], how="left")
        tot = df_tabela[codes].sum(axis=1)
        valid = tot - df_tabela[falhas].sum(axis=1)
        surv = np.divide(valid, tot, out=np.zeros_like(valid, dtype=float), where=tot!=0)
        df_tabela["%_Sobrevivência_decimal"] = surv
        df_tabela["%_Sobrevivência"] = (
            np.round(surv*100,1).astype(str).str.replace(r"\.",",",regex=True) + "%"
        )

        df_D = df_res.pivot_table(
            index=cols0,
            columns="NM_COVA_ORDENADO",
            values="Ht média",
            aggfunc="first",
            fill_value=0
        ).reset_index()
        df_D.columns = [str(c) if isinstance(c,int) else c for c in df_D.columns]
        num_cols_D = sorted([c for c in df_D.columns if c.isdigit()], key=int)
        df_D[num_cols_D] = df_D[num_cols_D] ** 3

        df_D_resultados = pd.concat(
            [df_D[cols0 + num_cols_D], df_D.apply(calc_metrics, axis=1, covas=num_cols_D)],
            axis=1
        )
        df_D_resultados = df_D_resultados.merge(
            counts,
            left_on=["CD_PROJETO","CD_TALHAO","nm_parcela"],
            right_on=["CD_PROJETO","CD_TALHAO","NM_PARCELA"],
            how="left"
        ).fillna(0)
        df_D_resultados["Stand (tree/ha)"] = (
            df_D_resultados[codes].sum(axis=1) - df_D_resultados[falhas].sum(axis=1)
        ) * 10000 / df_D_resultados["nm_area_parcela"].astype(float)
        df_D_resultados["Pits/ha"] = (
            (df_D_resultados["n"] - df_D_resultados["L"]) * 10000
            / df_D_resultados["nm_area_parcela"].astype(float)
        ).fillna(0)
        df_D_resultados = df_D_resultados.merge(medianas, on=["CD_PROJETO","CD_TALHAO"], how="left")
        tot_D = df_D_resultados[codes].sum(axis=1)
        valid_D = tot_D - df_D_resultados[falhas].sum(axis=1)
        surv_D = np.divide(valid_D, tot_D, out=np.zeros_like(valid_D, dtype=float), where=tot_D!=0)
        df_D_resultados["%_Sobrevivência_decimal"] = surv_D
        df_D_resultados["%_Sobrevivência"] = (
            np.round(surv_D*100,1).astype(str).str.replace(r"\.",",",regex=True) + "%"
        )
        df_D_resultados["Pits por sob"] = df_D_resultados["Stand (tree/ha)"] / df_D_resultados["%_Sobrevivência_decimal"]
        df_D_resultados["CHECK pits"] = df_D_resultados["Pits por sob"] - df_D_resultados["Pits/ha"]
        df_D_resultados["CHECK covas"] = df_D_resultados["Stand (tree/ha)"] / df_D_resultados["%_Sobrevivência_decimal"]
        df_D_resultados["CHECK impares/pares"] = df_D_resultados["n"].apply(lambda x: "Par" if x%2==0 else "Impar")
        df_D_resultados["%_K"] = (
            df_D_resultados["K"] / (df_D_resultados["n"] - df_D_resultados["L"])
        ).map(lambda x: f"{x:.1%}".replace(".",","))
        df_D_resultados["%_L"] = (
            (df_D_resultados["H"] + df_D_resultados["I"]) / (df_D_resultados["n"] - df_D_resultados["L"])
        ).map(lambda x: f"{x:.1%}".replace(".",","))

        out2 = os.path.join(pasta_output, f"BASE_IFQ6_{nome_mes}_{data_emissao}_01.xlsx")
        with pd.ExcelWriter(out2, engine="openpyxl") as w:
            df_cadastro.drop(columns=["Talhão_z3","Index_z3"], inplace=True)
            df_cadastro.to_excel(w, sheet_name="Cadastro_SGF", index=False)
            df_final.drop(columns=["Index_z3"], inplace=True)
            df_final.to_excel(w, sheet_name=f"Dados_CST_{nome_mes}", index=False)
            df_tabela.to_excel(w, sheet_name="C_tabela_resultados", index=False)
            df_D_resultados.to_excel(w, sheet_name="D_tabela_resultados_Ht3", index=False)
        print(f"✅ Tudo gravado em '{out2}'")

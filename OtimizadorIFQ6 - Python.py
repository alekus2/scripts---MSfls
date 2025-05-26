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
        mes_atual = datetime.now().month
        nome_mes = meses[mes_atual-1]
        data_emissao = datetime.now().strftime("%Y%m%d")
        base_dir = os.path.dirname(paths[0])
        pasta_mes = os.path.join(os.path.dirname(base_dir), nome_mes)
        pasta_output = os.path.join(pasta_mes, "output")
        os.makedirs(pasta_output, exist_ok=True)

        cadastro_path = next((p for p in paths if "SGF" in os.path.basename(p).upper()), None)

        for path in paths:
            if path == cadastro_path or not os.path.exists(path):
                continue
            nome_arquivo = os.path.basename(path).upper()
            if "LEBATEC" in nome_arquivo:
                base = "lebatec"
            elif "BRAVORE" in nome_arquivo:
                base = "bravore"
            elif "PROPRIA" in nome_arquivo:
                base = "propria"
            else:
                while True:
                    escolha = input("Selecione a equipe (1-LEBATEC,2-BRAVORE,3-PROPRIA):")
                    if escolha in ["1","2","3"]:
                        break
                base = ["lebatec","bravore","propria"][int(escolha)-1]

            equipes[base] = equipes.get(base, 0) + 1
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
        dup_cols = ['CD_PROJETO','CD_TALHAO','NM_PARCELA','NM_FILA','NM_COVA','NM_FUSTE','NM_ALTURA']
        df_final["check dup"] = df_final.duplicated(subset=dup_cols, keep=False).map({True:"VERIFICAR",False:"OK"})
        df_final["check cd"] = df_final.apply(
            lambda r: "OK" if r["CD_01"] in set("ABCDEFGHIKMNOPQRSTUVWX") and r["NM_FUSTE"] == 1
                      else ("VERIFICAR" if r["CD_01"] == "L" and r["NM_FUSTE"] == 1 else "OK"),
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
                idxs = g.index.tolist()
                seqs = list(range(1, len(idxs)+1))
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

        df_final.drop(columns=["NM_COVA_ORIG","group_id"], inplace=True)
        count_ver = df_final["check SQC"].value_counts().get("VERIFICAR", 0)
        print(f"Quantidade de 'VERIFICAR': {count_ver}")
        if count_ver > 0:
            resposta = input("Deseja verificar a planilha agora? (s/n): ")
            if resposta.lower() == 's':
                nome_base = f"IFQ6_{nome_mes}_{data_emissao}"
                cnt = 1
                out = os.path.join(pasta_output, f"{nome_base}_{str(cnt).zfill(2)}.xlsx")
                while os.path.exists(out):
                    cnt += 1
                    out = os.path.join(pasta_output, f"{nome_base}_{str(cnt).zfill(2)}.xlsx")
                df_final.to_excel(out, index=False)
                print(f"✅ Dados verificados e salvos em '{out}'.")
                return

        df_final["Ht média"] = df_final["NM_ALTURA"].fillna(0)
        df_final = df_final.sort_values(by=["CD_PROJETO","CD_TALHAO","NM_PARCELA","Ht média"])
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
        df_final.drop(columns=["check dup","check cd","check SQC"], inplace=True)

        df_cadastro = pd.read_excel(cadastro_path, sheet_name=0, dtype=str)
        df_cadastro["Index"] = df_cadastro["Id Projeto"].str.strip() + df_cadastro["Talhão"].str.strip()
        df_cadastro["Talhão_z3"] = df_cadastro["Talhão"].str[-3:].str.zfill(3)
        df_cadastro["Index_z3"] = df_cadastro["Id Projeto"].str.strip() + df_cadastro["Talhão_z3"]
        df_final["Index_z3"] = df_final["CD_PROJETO"].astype(str).str.strip() + df_final["CD_TALHAO"].astype(str).str.strip()

        area_col = next((c for c in df_cadastro.columns if "ÁREA" in c.upper()), None)
        df_res = pd.merge(
            df_final,
            df_cadastro[["Index_z3", area_col]],
            on="Index_z3",
            how="left"
        )
        df_res.rename(columns={area_col: "Área (ha)"}, inplace=True)
        df_res["Área (ha)"] = df_res["Área (ha)"].fillna("")
        df_res.rename(columns={
            "Chave_stand_1":   "Chave_stand_1",
            "NM_PARCELA":      "nm_parcela",
            "NM_AREA_PARCELA": "nm_area_parcela"
        }, inplace=True)

        cols0 = ["Área (ha)", "Chave_stand_1", "CD_PROJETO", "CD_TALHAO", "nm_parcela", "nm_area_parcela"]
        df_res["Ht média"] = pd.to_numeric(df_res["Ht média"], errors="coerce").fillna(0)

        df_pivot = df_res.pivot_table(
            index=cols0,
            columns="NM_COVA_ORDENADO",
            values="Ht média",
            aggfunc="first",
            fill_value=0
        ).reset_index()
        df_pivot.columns = [str(c) if isinstance(c, int) else c for c in df_pivot.columns]
        num_cols = sorted([c for c in df_pivot.columns if c.isdigit()], key=int)

        def calc_metrics(row, covas):
            vals = [row[c] for c in covas]
            last = max([i for i,v in enumerate(vals) if v>0], default=-1)
            vals = vals[:last+1] if last>=0 else []
            n = len(vals)
            med = np.median(vals) if n>0 else 0.0
            tot = sum(vals)
            ordered = sorted(vals)
            meio = n//2
            if n%2==0:
                le = sum(v for v in ordered[:meio] if v<=med)
            else:
                le = sum(ordered[:meio]) + med/2.0
            pv50 = (le/tot*100) if tot else 0.1
            return pd.Series({"n":n, "n/2":meio, "Mediana":med, "∑Ht":tot, "∑Ht(<=Med)":le, "PV50":pv50})

        df_tabela = df_pivot[cols0 + num_cols].copy()
        metrics_C = df_tabela.apply(calc_metrics, axis=1, covas=num_cols)
        df_tabela = pd.concat([df_tabela, metrics_C], axis=1)
        df_tabela["PV50"] = df_tabela["PV50"].map(lambda x: f"{x:.2f}%".replace(".",","))

        codes = ["A","B","D","F","G","H","I","J","L","M","N","O","Q","K","T","V","S","E"]
        falhas = ["M","H","F","L","S"]
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

        tot = df_tabela[codes].sum(axis=1)
        valid = tot - df_tabela[falhas].sum(axis=1)
        df_tabela["%_Sobrevivência"] = (
            (valid/tot*100).round(1).map(lambda x: f"{x:.1f}%".replace(".",","))
        )

        df_tabela["Pits/ha"] = (
            (df_tabela["n"] - df_tabela["L"]) * 10000
            / df_tabela["nm_area_parcela"].astype(float)
        ).fillna(0)

        df_tabela["CST"] = df_tabela["CD_TALHAO"].astype(str) + "-" + df_tabela["nm_parcela"].astype(str)

        pct = df_tabela["%_Sobrevivência"].str.rstrip("%").str.replace(",",".").astype(float)/100
        df_tabela["Pits por sob"] = (df_tabela["Stand (tree/ha)"] / pct).apply(math.ceil)
        df_tabela["Check pits"] = df_tabela["Pits por sob"] - df_tabela["Pits/ha"]

        df_D_resultados = df_tabela.copy()
        df_pivot = df_res.pivot_table(
            index=cols0,
            columns="NM_COVA_ORDENADO",
            values="Ht média",
            aggfunc="first",
            fill_value=0
        ).reset_index()
        df_pivot.columns = [str(c) if isinstance(c, int) else c for c in df_pivot.columns]
        num_cols = sorted([c for c in df_pivot.columns if c.isdigit()], key=int)

        def calc_metrics(row, covas):
            vals = [row[c] for c in covas]
            last = max([i for i,v in enumerate(vals) if v>0], default=-1)
            vals = vals[:last+1] if last>=0 else []
            n = len(vals)
            med = np.median(vals) if n>0 else 0.0
            tot = sum(vals)
            ordered = sorted(vals)
            meio = n//2
            if n%2==0:
                le = sum(v for v in ordered[:meio] if v<=med)
            else:
                le = sum(ordered[:meio]) + med/2.0
            pv50 = (le/tot*100) if tot else 0.1
            return pd.Series({"n":n, "n/2":meio, "Mediana":med, "∑Ht":tot, "∑Ht(<=Med)":le, "PV50":pv50})

        df_D_resultados = df_pivot[cols0 + num_cols].copy()
        metrics_C = df_D_resultados.apply(calc_metrics, axis=1, covas=num_cols)
        df_D_resultados = pd.concat([df_D_resultados, metrics_C], axis=1)
        df_D_resultados["PV50"] = df_D_resultados["PV50"].map(lambda x: f"{x:.2f}%".replace(".",","))

        codes = ["A","B","D","F","G","H","I","J","L","M","N","O","Q","K","T","V","S","E"]
        falhas = ["M","H","F","L","S"]
        counts = (
            df_final
            .groupby(["CD_PROJETO","CD_TALHAO","NM_PARCELA"])["CD_01"]
            .value_counts()
            .unstack(fill_value=0)
            .reindex(columns=codes, fill_value=0)
            .reset_index()
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

        tot = df_D_resultados[codes].sum(axis=1)
        valid = tot - df_D_resultados[falhas].sum(axis=1)
        df_D_resultados["%_Sobrevivência"] = (
            (valid/tot*100).round(1).map(lambda x: f"{x:.1f}%".replace(".",","))
        )
        medianas = (
            df_final
            .groupby(["CD_PROJETO","CD_TALHAO"])["Ht média"]
            .median()
            .reset_index(name="Média Ht")
        )

        df_D_resultados = df_D_resultados.merge(
            medianas,
            on=["CD_PROJETO","CD_TALHAO"],
            how="left"
        )
        
        df_D_resultados["Pits/ha"] = (
            (df_D_resultados["n"] - df_D_resultados["L"]) * 10000
            / df_D_resultados["nm_area_parcela"].astype(float)
        ).fillna(0)

        df_D_resultados["CST"] = df_D_resultados["CD_TALHAO"].astype(str) + "-" + df_D_resultados["nm_parcela"].astype(str)
        df_D_resultados["%_Sobrevivência"] = (
            (valid/tot*100).round(1).map(lambda x: f"{x:.1f}%".replace(".",","))
        )
        df_D_resultados["%_Sobrevivência_decimal"] = df_D_resultados["%_Sobrevivência"].str.rstrip('%')  
        df_D_resultados["%_Sobrevivência_decimal"] = pd.to_numeric(df_D_resultados["%_Sobrevivência_decimal"], errors='coerce')  
        df_D_resultados["%_Sobrevivência_decimal"] = df_D_resultados["%_Sobrevivência_decimal"] / 100

        print("Verificando NaN em df_final:")
        print(df_final.isna().sum())
        print("Linhas com NaN em df_final:")
        print(df_final[df_final.isna().any(axis=1)])

        print("Verificando NaN em df_tabela:")
        print(df_tabela.isna().sum())
        print("Linhas com NaN em df_tabela:")
        print(df_tabela[df_tabela.isna().any(axis=1)])

        print("Verificando NaN em df_D_resultados:")
        print(df_D_resultados.isna().sum())
        print("Linhas com NaN em df_D_resultados:")
        print(df_D_resultados[df_D_resultados.isna().any(axis=1)])


        df_D_resultados["Pits por sob"] = (df_D_resultados["Stand (tree/ha)"] / df_D_resultados["%_Sobrevivência_decimal"])
        df_D_resultados["CHECK pits"] = df_D_resultados["Pits por sob"] - df_D_resultados["Pits/ha"]
        df_D_resultados["CHECK covas"] = df_D_resultados["Stand (tree/ha)"] / df_D_resultados["%_Sobrevivência_decimal"]
        df_D_resultados["%_Sobrevivência"] = (df_D_resultados["%_Sobrevivência_decimal"] * 100).round(1).map(lambda x: f"{x:.1f}%".replace(".",","))
        df_D_resultados.drop(columns=["%_Sobrevivência_decimal"], inplace=True)

        
        df_D_resultados["CHECK impares/pares"] = df_D_resultados["n"].apply(lambda x: "Par" if x % 2 == 0 else "Impar")

        df_D_resultados["%_K"] = (df_D_resultados["K"] / (df_D_resultados["n"] - df_D_resultados["L"])).map(lambda x: f"{x:.1%}".replace(".",","))
        df_D_resultados["%_L"] = ((df_D_resultados["H"] + df_D_resultados["I"]) / (df_D_resultados["n"] - df_D_resultados["L"])).map(lambda x: f"{x:.1%}".replace(".",","))

        nome_base = f"BASE_IFQ6_{nome_mes}_{data_emissao}"
        cnt = 1
        out2 = os.path.join(pasta_output, f"{nome_base}_{str(cnt).zfill(2)}.xlsx")
        while os.path.exists(out2):
            cnt += 1
            out2 = os.path.join(pasta_output, f"{nome_base}_{str(cnt).zfill(2)}.xlsx")

        with pd.ExcelWriter(out2, engine="openpyxl") as w:
            df_cadastro.drop(columns=["Talhão_z3","Index_z3"], inplace=True)
            df_cadastro.to_excel(w, sheet_name="Cadastro_SGF", index=False)
            df_final.drop(columns=["Index_z3"], inplace=True)
            df_final.to_excel(w, sheet_name=f"Dados_CST_{nome_mes}", index=False)
            df_tabela.to_excel(w, sheet_name="C_tabela_resultados", index=False)
            df_D_resultados.to_excel(w, sheet_name="D_tabela_resultados_Ht3", index=False)
        print(f"✅ Tudo gravado em '{out2}'")

otimizador = OtimizadorIFQ6()
arquivos = [
    "/content/6271_TABOCA_SRP - IFQ6 (4).xlsx",
    "/content/6304_DOURADINHA_I_GLEBA_A_RRP - IFQ6 (8).xlsx",
    "/content/6348_BERRANTE_II_RRP - IFQ6 (29).xlsx",
    "/content/6362_PONTAL_III_GLEBA_A_RRP - IFQ6 (22).xlsx",
    "/content/6371_SÃO_ROQUE_BTG - IFQ6 (33).xlsx",
    "/content/6371_SÃO_ROQUE_BTG - IFQ6 (8).xlsx",
    "/content/6418_SÃO_JOÃO_IV_SRP - IFQ6 (6).xlsx",
    "/content/6439_TREZE_DE_JULHO_RRP - IFQ6 (4) - Copia.xlsx",
    "/content/IFQ6_MS_Florestal_Bravore_10032025.xlsx",
    "/content/IFQ6_MS_Florestal_Bravore_17032025.xlsx",
    "/content/IFQ6_MS_Florestal_Bravore_24032025.xlsx",
    "/content/base_dados_IFQ6_propria_fev.xlsx",
    "/content/Cadastro SGF (correto).xlsx"
]
otimizador.validacao(arquivos)

Verificando NaN em df_final:
CD_PROJETO                0
CD_TALHAO                 0
NM_PARCELA                0
DC_TIPO_PARCELA        3450
NM_AREA_PARCELA           0
NM_LARG_PARCELA           0
NM_COMP_PARCELA        8678
NM_DEC_LAR_PARCELA     4110
NM_DEC_COM_PARCELA     8678
DT_INICIAL                0
DT_FINAL                  0
CD_EQUIPE                 0
NM_LATITUDE             662
NM_LONGITUDE            662
NM_ALTITUDE            8678
DC_MATERIAL           12734
NM_FILA                   0
NM_COVA                   0
NM_FUSTE                  0
NM_DAP_ANT             8678
NM_ALTURA_ANT          8678
NM_CAP_DAP1            8678
NM_DAP2                8678
NM_DAP                 8678
NM_ALTURA                94
CD_01                     0
CD_02                 12733
CD_03                 12734
EQUIPE                    0
Ht média                  0
NM_COVA_ORDENADO          0
Chave_stand_1             0
DT_MEDIÇÃO1               0
EQUIPE_2                  0
Index_z3                  0
dtype: int64
Linhas com NaN em df_final:
      CD_PROJETO CD_TALHAO  NM_PARCELA DC_TIPO_PARCELA  NM_AREA_PARCELA  \
6681        6236       002           1             NaN              400   
6683        6236       002           1             NaN              400   
6684        6236       002           1             NaN              400   
6710        6236       002           1             NaN              400   
6696        6236       002           1             NaN              400   
...          ...       ...         ...             ...              ...   
5018        6418       005          11      PERMANENTE              400   
5011        6418       005          11      PERMANENTE              400   
5035        6418       005          11      PERMANENTE              400   
5012        6418       005          11      PERMANENTE              400   
5004        6418       005          11      PERMANENTE              400   

      NM_LARG_PARCELA  NM_COMP_PARCELA  NM_DEC_LAR_PARCELA  \
6681            11.28              NaN                 NaN   
6683            11.28              NaN                 NaN   
6684            11.28              NaN                 NaN   
6710            11.28              NaN                 NaN   
6696            11.28              NaN                 NaN   
...               ...              ...                 ...   
5018            11.28              NaN                 1.0   
5011            11.28              NaN                 1.0   
5035            11.28              NaN                 1.0   
5012            11.28              NaN                 1.0   
5004            11.28              NaN                 1.0   

      NM_DEC_COM_PARCELA DT_INICIAL  ... CD_01 CD_02  CD_03      EQUIPE  \
6681                 NaN 2025-03-13  ...     F   NaN    NaN  bravore_02   
6683                 NaN 2025-03-13  ...     F   NaN    NaN  bravore_02   
6684                 NaN 2025-03-13  ...     F   NaN    NaN  bravore_02   
6710                 NaN 2025-03-13  ...     F   NaN    NaN  bravore_02   
6696                 NaN 2025-03-13  ...     O   NaN    NaN  bravore_02   
...                  ...        ...  ...   ...   ...    ...         ...   
5018                 NaN 2025-03-09  ...     N   NaN    NaN  lebatec_07   
5011                 NaN 2025-03-09  ...     N   NaN    NaN  lebatec_07   
5035                 NaN 2025-03-09  ...     N   NaN    NaN  lebatec_07   
5012                 NaN 2025-03-09  ...     N   NaN    NaN  lebatec_07   
5004                 NaN 2025-03-09  ...     N   NaN    NaN  lebatec_07   

      Ht média  NM_COVA_ORDENADO  Chave_stand_1  DT_MEDIÇÃO1  EQUIPE_2  \
6681       0.0                 1     6236-002-1   2025-03-13     pablo   
6683       0.0                 2     6236-002-1   2025-03-13     pablo   
6684       0.0                 3     6236-002-1   2025-03-13     pablo   
6710       0.0                 4     6236-002-1   2025-03-13     pablo   
6696       1.8                 5     6236-002-1   2025-03-13     pablo   
...        ...               ...            ...          ...       ...   
5018       4.4                43    6418-005-11   2025-03-09    HEITOR   
5011       4.5                44    6418-005-11   2025-03-09    HEITOR   
5035       4.5                45    6418-005-11   2025-03-09    HEITOR   
5012       4.6                46    6418-005-11   2025-03-09    HEITOR   
5004       4.7                47    6418-005-11   2025-03-09    HEITOR   

      Index_z3  
6681   6236002  
6683   6236002  
6684   6236002  
6710   6236002  
6696   6236002  
...        ...  
5018   6418005  
5011   6418005  
5035   6418005  
5012   6418005  
5004   6418005  

[12734 rows x 35 columns]
Verificando NaN em df_tabela:
Área (ha)          0
Chave_stand_1      0
CD_PROJETO         0
CD_TALHAO          0
nm_parcela         0
                  ..
%_Sobrevivência    0
Pits/ha            0
CST                0
Pits por sob       0
Check pits         0
Length: 96, dtype: int64
Linhas com NaN em df_tabela:
Empty DataFrame
Columns: [Área (ha), Chave_stand_1, CD_PROJETO, CD_TALHAO, nm_parcela, nm_area_parcela, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, n, n/2, Mediana, ∑Ht, ∑Ht(<=Med), PV50, NM_PARCELA, A, B, D, F, G, H, I, J, L, M, N, O, Q, K, T, V, S, E, Stand (tree/ha), %_Sobrevivência, Pits/ha, CST, Pits por sob, Check pits]
Index: []

[0 rows x 96 columns]
Verificando NaN em df_D_resultados:
Área (ha)                    0
Chave_stand_1                0
CD_PROJETO                   0
CD_TALHAO                    0
nm_parcela                   0
                          ... 
%_Sobrevivência              0
Média Ht                     0
Pits/ha                      0
CST                          0
%_Sobrevivência_decimal    266
Length: 96, dtype: int64
Linhas com NaN em df_D_resultados:
    Área (ha) Chave_stand_1  CD_PROJETO CD_TALHAO  nm_parcela  \
0                6236-002-1        6236       002           1   
1                6236-002-3        6236       002           3   
2                6236-002-5        6236       002           5   
3                6271-022-1        6271       022           1   
4                6271-022-2        6271       022           2   
..        ...           ...         ...       ...         ...   
261             6418-005-11        6418       005          11   
262              6418-005-3        6418       005           3   
263              6418-005-5        6418       005           5   
264              6418-005-7        6418       005           7   
265              6418-005-9        6418       005           9   

     nm_area_parcela    1    2    3    4  ...  T  V  S  E  Stand (tree/ha)  \
0                400  0.0  0.0  0.0  0.0  ...  0  0  0  0           1100.0   
1                400  0.0  1.3  2.1  3.4  ...  0  0  0  0           1150.0   
2                400  0.0  0.0  0.0  1.5  ...  0  0  0  0           1075.0   
3                400  0.0  3.4  3.4  3.4  ...  0  0  0  0           1200.0   
4                400  3.3  3.6  3.7  3.8  ...  0  0  0  0           1225.0   
..               ...  ...  ...  ...  ...  ... .. .. .. ..              ...   
261              400  3.5  3.5  3.6  3.6  ...  0  0  0  0           1175.0   
262              400  0.0  0.0  2.6  3.4  ...  0  0  0  0           1125.0   
263              400  0.0  0.0  3.2  4.0  ...  0  0  0  0           1075.0   
264              400  3.2  3.4  3.7  3.8  ...  0  0  0  0           1100.0   
265              400  0.0  0.0  0.0  2.9  ...  0  0  0  0           1075.0   

     %_Sobrevivência  Média Ht  Pits/ha     CST  %_Sobrevivência_decimal  
0              89,8%       3.4   1200.0   002-1                      NaN  
1              95,8%       3.4   1200.0   002-3                      NaN  
2              93,5%       3.4   1150.0   002-5                      NaN  
3              98,0%       4.0   1225.0   022-1                      NaN  
4             100,0%       4.0   1225.0   022-2                      NaN  
..               ...       ...      ...     ...                      ...  
261           100,0%       4.2   1175.0  005-11                      NaN  
262            95,7%       4.2   1175.0   005-3                      NaN  
263            93,5%       4.2   1125.0   005-5                      NaN  
264           100,0%       4.2   1100.0   005-7                      NaN  
265            93,5%       4.2   1150.0   005-9                      NaN 

import pandas as pd
import os
from difflib import get_close_matches

class MachtCols:
    def __init__(self, nomes_colunas_trans, cutoff=0.6):
        self.nomes_colunas_trans = nomes_colunas_trans
        self.cutoff = cutoff

    def _achar_coluna_em_lista(self, cols, alvo):
        # 1) exato
        for c in cols:
            if c.strip().lower() == alvo.strip().lower():
                return c
        # 2) aproximado
        sugestões = get_close_matches(alvo, cols, n=3, cutoff=self.cutoff)
        if sugestões:
            print(f"\nSugestões para '{alvo}':")
            for i, s in enumerate(sugestões, start=1):
                print(f"  {i}. {s}")
            escolha = input(f"Escolha 1-{len(sugestões)} ou 0 para manual: ").strip() #Pq isso n aparece no output?tipo eu n vi isso aparecendo,ent n tem sugestoes?
            try:
                i = int(escolha)
                if 1 <= i <= len(sugestões):
                    return sugestões[i-1]
            except ValueError:
                pass
        return None

    def _achar_coluna(self, sheets_dict, alvo):
        # Tenta em cada sheet
        for nome_sheet, df_sheet in sheets_dict.items():
            cols = df_sheet.columns.tolist()
            achada = self._achar_coluna_em_lista(cols, alvo)
            if achada:
                return nome_sheet, achada
        #devera criar outra coluna com o nome do arquivo que é esses dados.
        print(f"\nNão achei '{alvo}' automaticamente em nenhuma sheet.")
        for nome_sheet, df_sheet in sheets_dict.items():
            print(f"  Sheet '{nome_sheet}': {df_sheet.columns.tolist()}")
        correção = input(f"\nDigite o nome exato da coluna para '{alvo}', no formato 'Sheet|Coluna' (ou ENTER p/ pular): ").strip()
        if '|' in correção:
            sheet_corr, col_corr = correção.split('|', 1)
            sheet_corr, col_corr = sheet_corr.strip(), col_corr.strip()
            if sheet_corr in sheets_dict and col_corr in sheets_dict[sheet_corr].columns:
                return sheet_corr, col_corr
        print(f"§ Pulando '{alvo}'.")
        return None, None

    def trans_colunas(self, paths, nome_saida="Dados_IFC_24-25"):
        base = os.path.abspath(paths[0])
        pasta_out = (os.path.dirname(base)
                     if "output" in base.lower()
                     else os.path.join(os.path.dirname(base), "output"))
        os.makedirs(pasta_out, exist_ok=True)

        acumulados = []
        for path in paths:
            if not os.path.exists(path):
                print(f"Aviso: não encontrei '{path}', pulando.")
                continue

            print(f"\n=== Processando {os.path.basename(path)} ===")
            sheets = pd.read_excel(path, sheet_name=None)
            novo = pd.DataFrame()

            for alvo in self.nomes_colunas_trans:
                nome_sheet, achada = self._achar_coluna(sheets, alvo)
                novo[alvo] = sheets[nome_sheet][achada]
            acumulados.append(novo)

        # concatena tudo e salva
        resultado = pd.concat(acumulados, ignore_index=True)
        cnt = 1
        arquivo = os.path.join(pasta_out, f"{nome_saida}_{cnt:02d}.xlsx")
        while os.path.exists(arquivo):
            cnt += 1
            arquivo = os.path.join(pasta_out, f"{nome_saida}_{cnt:02d}.xlsx")
        resultado.to_excel(arquivo, index=False)
        print(f"\n✅ Arquivo unificado salvo em:\n   {arquivo}")

nomes = [
    'FaseID','cd_fazenda','cd_talhao','nm_parcela','dc_tipo_parcela',
    'dc_forma_parcela','nm_area_parcela','nm_larg_parcela','nm_comp_parcela',
    'nm_dec_lar_parcela','nm_dec_com_parcela','dt_inicial','dt_final',
    'cd_equipe','nm_latitude','nm_longitude','nm_altitude','dc_material',
    'tx_observacao','nm_fila','nm_cova','nm_fuste','nm_dap_ant',
    'nm_altura_ant','nm_cap_dap1','nm_dap','nm_altura','cd_01',
    'cd_02','cd_03','nm_nota'
]

copiador = MachtCols(nomes_colunas_trans=nomes)
arquivos = [r"/content/Base_Abril_IFC_2024_MS.xlsx",
            r"/content/Base_Agosto_IFC_2024_MS.xlsx",
            r"/content/Base_Fevereiro_IFC_2024_MS.xlsx",
            r"/content/Base_IFC_Novembro_MS.xlsx",
            r"/content/Base_IFC_Outubro_MS.xlsx",
            r"/content/Base_Janeiro_IFC_2024_MS.xlsx",
            r"/content/Base_Julho_IFC_2024_MS.xlsx",
            r"/content/Base_Junho_IFC_2024_MS.xlsx",
            r"/content/Base_Maio_IFC_2024_MS.xlsx",
            r"/content/Base_Março_IFC_2024_MS.xlsx",
            r"/content/Cópia de Base_IFC_Setembro.xlsx",
            r"/content/Base_IFC_Dezembro_MS_2024.xlsx"
]
copiador.trans_colunas(arquivos)

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
            escolha = input(f"Escolha 1-{len(sugestões)} ou 0 para manual: ").strip()
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

        # Não encontrou em nenhuma: mostra todas as sheets e colunas
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
        # prepara pasta de saída
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
            # carrega todas as sheets
            sheets = pd.read_excel(path, sheet_name=None)
            # novo DF só com as colunas alvo
            novo = pd.DataFrame()

            for alvo in self.nomes_colunas_trans:
                nome_sheet, achada = self._achar_coluna(sheets, alvo)
                if achada:
                    novo[alvo] = sheets[nome_sheet][achada]
                else:
                    novo[alvo] = pd.NA
                    print(f"**'{alvo}'** ficará com NaN neste arquivo.")

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

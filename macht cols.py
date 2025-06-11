import pandas as pd
import os
from difflib import get_close_matches

class MachtCols:
    def __init__(self, nomes_colunas_trans, cutoff=0.6):
        self.nomes_colunas_trans = nomes_colunas_trans
        self.cutoff = cutoff

    def _achar_coluna_em_lista(self, cols, alvo, arquivo, sheet):
        # 1) correspondência exata
        for c in cols:
            if c.strip().lower() == alvo.strip().lower():
                return c

        # 2) correspondência aproximada
        sugestões = get_close_matches(alvo, cols, n=3, cutoff=self.cutoff)
        if sugestões:
            print(f"\nSugestões em '{sheet}' para '{alvo}': {sugestões}")
            escolha = input(f"Escolha 1-{len(sugestões)} ou 0 para ver lista completa: ").strip()
            try:
                i = int(escolha)
                if 1 <= i <= len(sugestões):
                    return sugestões[i-1]
            except ValueError:
                pass

        # 3) manual (sempre)
        print(f"\nColunas disponíveis em '{sheet}' do arquivo '{arquivo}':\n  {cols}\n")
        correção = input(f"Digite o nome exato da coluna para '{alvo}' (ou ENTER para pular): ").strip()
        return correção if correção in cols else None

    def _achar_coluna(self, sheets_dict, alvo, arquivo):
        # percorre sheets tentando achar
        for nome_sheet, df_sheet in sheets_dict.items():
            cols = df_sheet.columns.tolist()
            achada = self._achar_coluna_em_lista(cols, alvo, arquivo, nome_sheet)
            if achada:
                return nome_sheet, achada
        # se não achou em nenhuma
        print(f"\nNão achei '{alvo}' em nenhuma sheet de '{arquivo}'. Pulando.")
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

            arquivo = os.path.basename(path)
            print(f"\n=== Processando '{arquivo}' ===")
            sheets = pd.read_excel(path, sheet_name=None)
            novo = pd.DataFrame()

            # adiciona coluna de origem
            novo['origem_arquivo'] = arquivo

            for alvo in self.nomes_colunas_trans:
                nome_sheet, achada = self._achar_coluna(sheets, alvo, arquivo)
                if nome_sheet and achada:
                    novo[alvo] = sheets[nome_sheet][achada]
                else:
                    # preenche NaN se não achou
                    novo[alvo] = pd.NA

            acumulados.append(novo)

        # concatena tudo e salva
        resultado = pd.concat(acumulados, ignore_index=True)
        cnt = 1
        arquivo_saida = os.path.join(pasta_out, f"{nome_saida}_{cnt:02d}.xlsx")
        while os.path.exists(arquivo_saida):
            cnt += 1
            arquivo_saida = os.path.join(pasta_out, f"{nome_saida}_{cnt:02d}.xlsx")

        resultado.to_excel(arquivo_saida, index=False)
        print(f"\n✅ Arquivo unificado salvo em:\n   {arquivo_saida}")

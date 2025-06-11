import pandas as pd
import os
from difflib import get_close_matches

class MachtCols:
    def __init__(self, nomes_colunas_trans, cutoff=0.6):
        self.nomes_colunas_trans = nomes_colunas_trans
        self.cutoff = cutoff

    def _achar_coluna(self, df_cols, alvo):
        # 1) exato
        for c in df_cols:
            if c.strip().lower() == alvo.strip().lower():
                return c

        # 2) aproximado
        sugestões = get_close_matches(alvo, df_cols, n=3, cutoff=self.cutoff)
        if sugestões:
            print(f"\nSugestões para '{alvo}':")
            for i, s in enumerate(sugestões, 1):
                print(f"  {i}. {s}")
            escolha = input(f"Escolha 1-{len(sugestões)} ou 0 para digitar manualmente: ")
            try:
                i = int(escolha)
                if 1 <= i <= len(sugestões):
                    return sugestões[i-1]
            except ValueError:
                pass

        # 3) sem sugestões: mostrar todas as colunas existentes
        print(f"\nAs colunas disponíveis no arquivo são:\n{df_cols}\n")
        correção = input(f"Digite o nome exato da coluna para corresponder a '{alvo}' (ou ENTER para pular): ").strip()
        if correção in df_cols:
            return correção
        else:
            print(f"'{correção}' não encontrada na lista de colunas; pulando.")
            return None

    def trans_colunas(self, paths, nome_saida="Dados_IFC_24-25"):
        base = os.path.abspath(paths[0])
        pasta_out = (os.path.dirname(base)
                     if "output" in base.lower()
                     else os.path.join(os.path.dirname(base), "output"))
        os.makedirs(pasta_out, exist_ok=True)

        lista_dfs = []
        for path in paths:
            if not os.path.exists(path):
                print(f"Aviso: não encontrou '{path}', pulando.")
                continue

            print(f"\n--- Processando {os.path.basename(path)} ---")
            df = pd.read_excel(path, sheet_name=0)
            novo = pd.DataFrame()

            for alvo in self.nomes_colunas_trans:
                achada = self._achar_coluna(df.columns.tolist(), alvo)
                if achada:
                    novo[alvo] = df[achada]
                else:
                    print(f"**Não encontrada** coluna para '{alvo}', será preenchida com NaN.")
                    novo[alvo] = pd.NA

            lista_dfs.append(novo)

        resultado = pd.concat(lista_dfs, ignore_index=True)
        cnt = 1
        arquivo = os.path.join(pasta_out, f"{nome_saida}_{cnt:02d}.xlsx")
        while os.path.exists(arquivo):
            cnt += 1
            arquivo = os.path.join(pasta_out, f"{nome_saida}_{cnt:02d}.xlsx")

        resultado.to_excel(arquivo, index=False)
        print(f"\nArquivo unificado salvo em:\n{arquivo}")

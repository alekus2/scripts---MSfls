import pandas as pd
import os
from difflib import get_close_matches

class MachtCols:
    def __init__(self, nomes_colunas_trans, cutoff=0.6):
        # nomes finais que queremos, na ordem final
        self.nomes_colunas_trans = nomes_colunas_trans
        self.cutoff = cutoff  # sensibilidade da correspondência aproximada

    def _achar_coluna(self, df_cols, alvo):
        """
        Busca em df_cols algo que case com 'alvo':
        1) exato ignorando case e espaços
        2) get_close_matches
        3) input manual
        """
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

        # 3) manual
        correção = input(f"Digite o nome exato da coluna correspondente a '{alvo}' (ou ENTER para pular): ").strip()
        return correção if correção in df_cols else None

    def trans_colunas(self, paths, nome_saida="Dados_IFC_24-25"):
        # prepara pasta de saída
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

            # para cada coluna que queremos
            for alvo in self.nomes_colunas_trans:
                achada = self._achar_coluna(df.columns.tolist(), alvo)
                if achada:
                    novo[alvo] = df[achada]
                else:
                    print(f"**Não encontrada** coluna para '{alvo}', será preenchida com NaN.")
                    novo[alvo] = pd.NA

            lista_dfs.append(novo)

        # concatena tudo
        resultado = pd.concat(lista_dfs, ignore_index=True)

        # salva com contador
        cnt = 1
        arquivo = os.path.join(pasta_out, f"{nome_saida}_{cnt:02d}.xlsx")
        while os.path.exists(arquivo):
            cnt += 1
            arquivo = os.path.join(pasta_out, f"{nome_saida}_{cnt:02d}.xlsx")

        resultado.to_excel(arquivo, index=False)
        print(f"\nArquivo unificado salvo em:\n{arquivo}")

# Uso:
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
arquivos = [
    "/content/Base_Abril_IFC_2024_MS.xlsx",
    "/content/Base_Agosto_IFC_2024_MS.xlsx",
    # ... restantes
]
copiador.trans_colunas(arquivos)

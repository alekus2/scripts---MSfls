import pandas as pd
import os
from datetime import datetime

class farming:
    def trans_colunas(self, paths):
        nomes_colunas_trans = [
            'FaseID',	'cd_fazenda',	'cd_talhao',	'nm_parcela',	'dc_tipo_parcela',	'dc_forma_parcela',	'nm_area_parcela',	'nm_larg_parcela',	'nm_comp_parcela',	
            'nm_dec_lar_parcela',	'nm_dec_com_parcela',	'dt_inicial',	'dt_final',	'cd_equipe',	'nm_latitude',	'nm_longitude',	'nm_altitude',	'dc_material',	
            'tx_observacao',	'nm_fila',	'nm_cova',	'nm_fuste',	'nm_dap_ant',	'nm_altura_ant',	'nm_cap_dap1',	'nm_dap',	'nm_altura',	'cd_01',	'cd_02',	'cd_03',	'nm_nota'
        ]
        colunas_map = {
            "coluna 1": "FaseID",
            "Data Plantio": "cd_fazenda",
            "Data Avaliação": "cd_talhao",
            "GM": "nm_parcela",
            "Fazenda": "dc_tipo_parcela",
            "cd_talhao2": "dc_forma_parcela",
            "Clone":"nm_area_parcela",
            "Área (ha)": "nm_larg_parcela",
            "Média de %_Sobrevivência": "nm_comp_parcela",       
            "Stand (tree/ha)": "nm_dec_lar_parcela",
            "Ht (m)": "nm_dec_com_parcela",
            "Média de PV50 CF": "dt_inicial",
            "Média Pits/ha": "dt_final",
            "Arrow_Survival": "cd_equipe",
            "Arrow_Ht": "nm_latitude",
            "Arrow_PV50": "nm_longitude",
            "Arrow_Stand (tree/ha)": "nm_altitude",
            "Projeto": "dc_material",
            "Talhão": "tx_observacao",
            "coluna 20": "nm_fila",
            "coluna 21": "nm_cova",
            "coluna 22": "nm_fuste",
            "coluna 23": "nm_dap_ant",
            "coluna 24": "nm_altura_ant",
            "coluna 25": "nm_cap_dap1",
            "coluna 26": "nm_dap",
            "coluna 27": "nm_altura",
            "coluna 28": "cd_01",
            "coluna 29": "cd_02",
            "coluna 30": "cd_03",
            "coluna 31": "nm_nota"
        }
      
        #o codigo devera fazer meio q um caça tesouro, pois as colunas em colunas_trans em cada arquivo estão organizadas de formas diferentes e com nomes diferentes tipo com um espaço a mais ou em maiusculas, então quero que o codigo tente achar essas colunas por si só dentro de cada arquivo para juntar todas em um arquivo final e unico.
        #as colunas em que o codigo nao encontrar ele deverá me mostrar as colunas do arquivo q nao encontrou e me dar a opção de escrever o nome da coluna corretamente para o codigo procurar denovo.
        #unificar todas os dados de cada coluna em um unico arquivo asssim como dito.
      
      
        base_path = os.path.abspath(paths[0])
        if "output" in base_path.lower():
            pasta_output = os.path.dirname(base_path)
        else:
            pasta_output = os.path.join(os.path.dirname(base_path), 'output')
        os.makedirs(pasta_output, exist_ok=True)

        for path in paths:
            if not os.path.exists(path):
                print(f"Erro: Arquivo '{path}' não encontrado.")
                continue
            print(f"Processando: {path}")
            df = pd.read_excel(path, sheet_name=0, header=0)

            novo_df = pd.DataFrame(columns=nomes_colunas_trans)

            for col_orig, col_dest in colunas_map.items():
                if col_orig in df.columns:
                    novo_df[col_dest] = df[col_orig]
                else:
                  print(f"A coluna {col_orig} não foi localizada.")

            nome_base = "Dados_IFC_24-25"
            contador = 1
            novo_arquivo = os.path.join(pasta_output, f"{nome_base}_{contador:02d}.xlsx")
            while os.path.exists(novo_arquivo):
                contador += 1
                novo_arquivo = os.path.join(pasta_output, f"{nome_base}_{contador:02d}.xlsx")

            # Salva
            novo_df.to_excel(novo_arquivo, index=False)
            print(f"Arquivo salvo como: {novo_arquivo}")

fazenda = farming()
arquivos = [r"/content/04_Base IFQ6_APRIL_Ht3_2025copia.xlsx"] 
fazenda.trans_colunas(arquivos)

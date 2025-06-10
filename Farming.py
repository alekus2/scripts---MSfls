import pandas as pd
import os
from datetime import datetime

class farming:
    def trans_colunas(self, paths):
        nomes_colunas_trans = ["INDEX_2","MONTHS","MONTH/YEAR MEASUREMENT","PLANTED DATE","MEASURING DATE","AGE(DAYS)",
                               "GM","FARM","INDEX","GENETIC MATERIAL","ÁREA(HA)","Survival(%)","Stand (tree/ha)",
                               "Height AVG(m)","PV50(%)","Pits/ha","Arrow_survival","Arrow_stand","Arrow_height",
                               "ID_FARM","TALHAO"
        ]
        colunas_copiadas=["cd_talhao","Área(ha)","Data Plantio","Data Avaliação","Avaliação","GM","Média de PV50 CF",
                          "Ht (m)","Stand (tree/ha)","Média Pits/ha","Média de %_Sobrevivência","Arrow_PV50","Arrow_Ht",
                          "Arrow_Stand (tree/ha)","Arrow_Survival","Projeto","Talhão","Mês"]
        

        meses = ["Janeiro","Fevereiro","Março","Abril","Maio","Junho",
                 "Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"]
        nome_mes = meses[datetime.now().month - 1]
        data_emissao = datetime.now().strftime("%Y%m%d")

        base_path = os.path.abspath(paths[0])
        if nome_mes.lower() in base_path.lower():
            parent_dir = os.path.dirname(base_path)
            pasta_output = parent_dir if os.path.basename(parent_dir).lower()=='output' \
                           else os.path.join(parent_dir,'output')
        else:
            base_dir = os.path.dirname(paths[0])
            pasta_mes = os.path.join(os.path.dirname(base_dir), nome_mes)
            pasta_output = os.path.join(pasta_mes, 'output')
        os.makedirs(pasta_output, exist_ok=True)

        for path in paths:
            if not os.path.exists(path):
                print(f"Erro: Arquivo '{path}' não encontrado.")
                continue
            print(f"Processando: {path}")
            df = pd.read_excel(path, sheet_name=0, header=1)

            # Aqui construíremos começar o processamento de dados onde iremos pegar os dados de cada coluna e colocar em cada local exato.

            nome_base = f"marcar_col_{nome_mes}_{data_emissao}"
            contador = 1
            destino = lambda c: os.path.join(pasta_output, f"{c}_{str(contador).zfill(2)}.xlsx")
            novo_arquivo = destino(nome_base)
            while os.path.exists(novo_arquivo):
                contador += 1
                novo_arquivo = destino(nome_base)

# Exemplo de uso
fazenda = farming()
arquivos = [r""]
fazenda.trans_colunas(arquivos)

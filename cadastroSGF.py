import pandas as pd
import os
from datetime import datetime

class CadastroSGF:
    def verificar(self, paths):
        nomes_colunas = [
            "Id", "Tipo Propriedade", "Cód. Região", "Região", "Id Projeto", "Projeto", "Localidade",
            "Talhão", "Ciclo", "Rotação", "Tipo", "Uso do Talhão", "Descrição do Uso do talhão", "Fase",
            "Bacia", "Solo", "Relevo", "Espaçamento", "Sistema de Propagação", "Mat.Genético", "Espécie",
            "Plantio", "Mês de Plantio", "Regime", "Sitio", "Área(ha)", "Área GIS", "Atualizar via GIS",
            "Distância Total", "Status", "Cód. Projeto Investimento", "Dcr. Projeto Investimento",
            "Cód. Tarefa Proj. Invest.", "ID Terra Potencial", "Observacao", "DCAA Data Emissão",
            "DCAA Data Validade", "Início vigência", "Fim vigência", "Distância Terra", "Precipitação",
            "Distância asfalto", "Tipo de Contrato", "Proj. de Expansão", "DCAA Número", "Cod Antigo Proj.",
            "Área MRP", "Regional colheita", "Regional silvicultura", "Região climática", "Terra", "Bioma",
            "Classe", "FlagCTOVirtual", "Registro", "Ativo"
        ]

        meses = [
            "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
            "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
        ]
        mes_atual = datetime.now().month
        nome_mes = meses[mes_atual - 1]
        data_emissao = datetime.now().strftime("%Y%m%d")
        
        base_path = os.path.abspath(paths[0])
        if nome_mes.lower() in base_path.lower():
            parent_dir = os.path.dirname(base_path)
            if os.path.basename(parent_dir).lower() == 'output':
                pasta_output = parent_dir
            else:
                pasta_output = os.path.join(parent_dir, 'output')
                os.makedirs(pasta_output, exist_ok=True)
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
            df = pd.read_excel(path, sheet_name=0)

            colunas_presentes = []
            colunas_faltando = []

            # Verifica quais colunas estão presentes
            for col in nomes_colunas:
                if col in df.columns:
                    colunas_presentes.append(col)
                else:
                    colunas_faltando.append(col)
                    print(f"Coluna não encontrada: {col}")

            if not colunas_presentes:
                print(f"Erro: Nenhuma coluna esperada encontrada no arquivo '{path}'. Pulando...")
                continue  # Pula para o próximo arquivo se nenhuma coluna estiver presente
            
            # Reorganiza as colunas na ordem especificada, apenas com as colunas que foram encontradas
            df_reorganizado = df[colunas_presentes]

            # Salvar o DataFrame reorganizado
            nome_base = f"SGF_{nome_mes}_{data_emissao}"
            contador = 1
            novo_arquivo_excel = os.path.join(pasta_output, f"{nome_base}_{str(contador).zfill(2)}.xlsx")
            while os.path.exists(novo_arquivo_excel):
                contador += 1
                novo_arquivo_excel = os.path.join(pasta_output, f"{nome_base}_{str(contador).zfill(2)}.xlsx")

            df_reorganizado.to_excel(novo_arquivo_excel, index=False)
            print(f"✅ Dados foram reorganizados e salvos em '{novo_arquivo_excel}'.")
            if colunas_faltando:
                print(f"As seguintes colunas não foram encontradas: {', '.join(colunas_faltando)}")

cadastrar = CadastroSGF()     

arquivos = [
    r"F:\Qualidade_Florestal\02- MATO GROSSO DO SUL\11- Administrativo Qualidade MS\00- Colaboradores\17 - Alex Vinicius\Automações em python\Automatização_cadastro_SGF\dados\Modelo_atual_cadastr.xlsx"
]

cadastrar.verificar(arquivos)
import pandas as pd
import os
from datetime import datetime

class CadastroSGF:
    def verificar(self, paths):
        # Lista de colunas desejadas (com nomes originais)
        colunas_desejadas = [
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
        
        # Normaliza os nomes das colunas desejadas para comparação (minúsculas e sem espaços)
        colunas_desejadas_norm = [col.lower().strip() for col in colunas_desejadas]
        
        # Determina informações de data e pasta de saída
        meses = [
            "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
            "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
        ]
        mes_atual = datetime.now().month
        nome_mes = meses[mes_atual - 1]
        data_emissao = datetime.now().strftime("%Y%m%d")
        
        # Define a pasta de output, baseado no caminho do primeiro arquivo
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
        
        # Processa cada arquivo
        for path in paths:
            if not os.path.exists(path):
                print(f"Erro: Arquivo '{path}' não encontrado.")
                continue

            print(f"Processando: {path}")
            df = pd.read_excel(path, sheet_name=0)
            
            # Normaliza os nomes das colunas do DataFrame (minúsculas e sem espaços extras)
            df.columns = df.columns.str.lower().str.strip()
            print(f"Colunas encontradas no DataFrame: {df.columns.tolist()}")

            # Verifica quais colunas desejadas estão presentes ou ausentes
            colunas_presentes = []
            colunas_ausentes = []
            for original, norm in zip(colunas_desejadas, colunas_desejadas_norm):
                if norm in df.columns:
                    colunas_presentes.append(original)
                else:
                    colunas_ausentes.append(original)
                    print(f"Coluna não encontrada: {original}")
            
            print(f"\nColunas presentes: {colunas_presentes}")
            print(f"Colunas ausentes: {colunas_ausentes}\n")
            
            # Seleciona somente as colunas presentes (usando os nomes normalizados para selecionar)
            # Mapeia os nomes presentes para a versão normalizada correspondente
            colunas_para_selecionar = [col.lower().strip() for col in colunas_presentes]
            df_reorganizado = df[colunas_para_selecionar]
            
            # Salva o DataFrame reorganizado em um novo arquivo Excel
            nome_base = f"SGF_{nome_mes}_{data_emissao}"
            contador = 1
            novo_arquivo_excel = os.path.join(pasta_output, f"{nome_base}_{str(contador).zfill(2)}.xlsx")
            while os.path.exists(novo_arquivo_excel):
                contador += 1
                novo_arquivo_excel = os.path.join(pasta_output, f"{nome_base}_{str(contador).zfill(2)}.xlsx")
            
            df_reorganizado.to_excel(novo_arquivo_excel, index=False)
            print(f"✅ Dados reorganizados e salvos em '{novo_arquivo_excel}'.")

# Exemplo de uso:
# arquivos = ["/caminho/para/seu/arquivo.xlsx"]
# cadastro = CadastroSGF()
# cadastro.verificar(arquivos)

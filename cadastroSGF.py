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

        # Normaliza os nomes das colunas da lista
        nomes_colunas_normalizados = [col.lower().strip() for col in nomes_colunas]

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

            # Normaliza os nomes das colunas do DataFrame
            colunas_df_normalizadas = [col.lower().strip() for col in df.columns]

            # Printar as colunas do DataFrame para comparação
            print(f"Colunas encontradas no DataFrame: {colunas_df_normalizadas}")

            colunas_presentes = []
            colunas_faltando = []

            # Verifica quais colunas estão presentes
            for col in nomes_colunas_normalizados:
                if col in colunas_df_normalizadas:
                    colunas_presentes.append(col)
                else:
                    colunas_faltando.append(col)
                    print(f"Coluna não encontrada: {col}")

            if not colunas_presentes:
                print(f"Erro: Nenhuma coluna esperada encontrada no arquivo '{path}'. Pulando...")
                continue  # Pula para o próximo arquivo se nenhuma coluna estiver presente
            
            # Reorganiza as colunas na ordem especificada, apenas com as colunas que foram encontradas
            colunas_presentes_originais = [nomes_colunas[i] for i, col in enumerate(nomes_colunas_normalizados) if col in colunas_presentes]
            df_reorganizado = df[colunas_presentes_originais]

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

Processando: /content/Modelo_atual_cadastro.xlsx
Colunas encontradas no DataFrame: ['ativo', 'região', 'feição pai', 'descrição de uso do solo', 'tipo propriedade', 'id região', 'id projeto', 'projeto', 'localidade', 'talhão', 'ciclo', 'rotação', 'tipo', 'fase', 'bacia', 'solo', 'relevo', 'espaçamento', 'sistema de propagação', 'mat.genético', 'espécie', 'data plantio', 'mês de plantio', 'regime', 'sítio', 'área (ha)', 'área gis', 'atualizar via gis', 'distância total', 'situação', 'cód. projeto investimento', 'dcr. projeto investimento', 'processo comercial', 'processo jurídico', 'organização', 'cód. tarefa proj. invest.', 'fazendas', 'registro', 'id', 'gênero', 'idade', 'manejo', 'distância média baldeio', 'cd uso solo pai', 'planooperacao', 'responsável', 'observações', 'data plantio projetado', 'início vigência', 'fim vigência', 'dcaa data emissão', 'dcaa data validade', 'data primeiro plantio', 'distância terra', 'distância asfalto', 'precipitação', 'ciclo de investimento', '% saída madeira - chuva', 'volume madeira', 'chave', 'tipo contrato', 'projeto expansão', 'dcaa número', 'regional colheita', 'regional silvicultura', 'região climática', 'certificação', 'tipo de licença', 'produto', 'fábrica', 'manejo futuro', 'bioma', 'tipologia', 'coletor de custo']
Coluna não encontrada: cód. região
Coluna não encontrada: uso do talhão
Coluna não encontrada: descrição do uso do talhão
Coluna não encontrada: plantio
Coluna não encontrada: sitio
Coluna não encontrada: área(ha)
Coluna não encontrada: status
Coluna não encontrada: id terra potencial
Coluna não encontrada: observacao
Coluna não encontrada: tipo de contrato
Coluna não encontrada: proj. de expansão
Coluna não encontrada: cod antigo proj.
Coluna não encontrada: área mrp
Coluna não encontrada: terra
Coluna não encontrada: classe
Coluna não encontrada: flagctovirtual
---------------------------------------------------------------------------
KeyError                                  Traceback (most recent call last)
<ipython-input-5-cdc3712b18e4> in <cell line: 0>()
     89 ]
     90 
---> 91 cadastrar.verificar(arquivos)

3 frames
/usr/local/lib/python3.11/dist-packages/pandas/core/indexes/base.py in _raise_if_missing(self, key, indexer, axis_name)
   6250 
   6251             not_found = list(ensure_index(key)[missing_mask.nonzero()[0]].unique())
-> 6252             raise KeyError(f"{not_found} not in index")
   6253 
   6254     @overload

KeyError: "['Início vigência', 'Fim vigência', 'Distância asfalto', 'Regional colheita', 'Regional silvicultura', 'Região climática'] not in index"

Processando: /content/Modelo_atual_cadastro.xlsx
Colunas encontradas no DataFrame: ['ativo', 'região', 'feição pai', 'descrição de uso do solo', 'tipo propriedade', 'id região', 'id projeto', 'projeto', 'localidade', 'talhão', 'ciclo', 'rotação', 'tipo', 'fase', 'bacia', 'solo', 'relevo', 'espaçamento', 'sistema de propagação', 'mat.genético', 'espécie', 'data plantio', 'mês de plantio', 'regime', 'sítio', 'área (ha)', 'área gis', 'atualizar via gis', 'distância total', 'situação', 'cód. projeto investimento', 'dcr. projeto investimento', 'processo comercial', 'processo jurídico', 'organização', 'cód. tarefa proj. invest.', 'fazendas', 'registro', 'id', 'gênero', 'idade', 'manejo', 'distância média baldeio', 'cd uso solo pai', 'planooperacao', 'responsável', 'observações', 'data plantio projetado', 'início vigência', 'fim vigência', 'dcaa data emissão', 'dcaa data validade', 'data primeiro plantio', 'distância terra', 'distância asfalto', 'precipitação', 'ciclo de investimento', '% saída madeira - chuva', 'volume madeira', 'chave', 'tipo contrato', 'projeto expansão', 'dcaa número', 'regional colheita', 'regional silvicultura', 'região climática', 'certificação', 'tipo de licença', 'produto', 'fábrica', 'manejo futuro', 'bioma', 'tipologia', 'coletor de custo']
Colunas encontradas: id
Colunas encontradas: tipo propriedade
Coluna não encontrada: cód. região
Colunas encontradas: região
Colunas encontradas: id projeto
Colunas encontradas: projeto
Colunas encontradas: localidade
Colunas encontradas: talhão
Colunas encontradas: ciclo
Colunas encontradas: rotação
Colunas encontradas: tipo
Coluna não encontrada: uso do talhão
Coluna não encontrada: descrição do uso do talhão
Colunas encontradas: fase
Colunas encontradas: bacia
Colunas encontradas: solo
Colunas encontradas: relevo
Colunas encontradas: espaçamento
Colunas encontradas: sistema de propagação
Colunas encontradas: mat.genético
Colunas encontradas: espécie
Coluna não encontrada: plantio
Colunas encontradas: mês de plantio
Colunas encontradas: regime
Coluna não encontrada: sitio
Coluna não encontrada: área(ha)
Colunas encontradas: área gis
Colunas encontradas: atualizar via gis
Colunas encontradas: distância total
Coluna não encontrada: status
Colunas encontradas: cód. projeto investimento
Colunas encontradas: dcr. projeto investimento
Colunas encontradas: cód. tarefa proj. invest.
Coluna não encontrada: id terra potencial
Coluna não encontrada: observacao
Colunas encontradas: dcaa data emissão
Colunas encontradas: dcaa data validade
Colunas encontradas: início vigência
Colunas encontradas: fim vigência
Colunas encontradas: distância terra
Colunas encontradas: precipitação
Colunas encontradas: distância asfalto
Coluna não encontrada: tipo de contrato
Coluna não encontrada: proj. de expansão
Colunas encontradas: dcaa número
Coluna não encontrada: cod antigo proj.
Coluna não encontrada: área mrp
Colunas encontradas: regional colheita
Colunas encontradas: regional silvicultura
Colunas encontradas: região climática
Coluna não encontrada: terra
Colunas encontradas: bioma
Coluna não encontrada: classe
Coluna não encontrada: flagctovirtual
Colunas encontradas: registro
Colunas encontradas: ativo
As seguintes colunas não foram encontradas: cód. região, uso do talhão, descrição do uso do talhão, plantio, sitio, área(ha), status, id terra potencial, observacao, tipo de contrato, proj. de expansão, cod antigo proj., área mrp, terra, classe, flagctovirtual
Colunas encontradas: 
---------------------------------------------------------------------------
KeyError                                  Traceback (most recent call last)
<ipython-input-8-4a70e61a20e6> in <cell line: 0>()
     93 ]
     94 
---> 95 cadastrar.verificar(arquivos)

3 frames
/usr/local/lib/python3.11/dist-packages/pandas/core/indexes/base.py in _raise_if_missing(self, key, indexer, axis_name)
   6247         if nmissing:
   6248             if nmissing == len(indexer):
-> 6249                 raise KeyError(f"None of [{key}] are in the [{axis_name}]")
   6250 
   6251             not_found = list(ensure_index(key)[missing_mask.nonzero()[0]].unique())

KeyError: "None of [Index(['Id', 'Tipo Propriedade', 'Região', 'Id Projeto', 'Projeto',\n       'Localidade', 'Talhão', 'Ciclo', 'Rotação', 'Tipo', 'Fase', 'Bacia',\n       'Solo', 'Relevo', 'Espaçamento', 'Sistema de Propagação',\n       'Mat.Genético', 'Espécie', 'Mês de Plantio', 'Regime', 'Área GIS',\n       'Atualizar via GIS', 'Distância Total', 'Cód. Projeto Investimento',\n       'Dcr. Projeto Investimento', 'Cód. Tarefa Proj. Invest.',\n       'DCAA Data Emissão', 'DCAA Data Validade', 'Início vigência',\n       'Fim vigência', 'Distância Terra', 'Precipitação', 'Distância asfalto',\n       'DCAA Número', 'Regional colheita', 'Regional silvicultura',\n       'Região climática', 'Bioma', 'Registro', 'Ativo'],\n      dtype='object')] are in the [columns]"

for path in paths:
    if not os.path.exists(path):
        print(f"Arquivo '{path}' não encontrado.")
        while True:
            eqp = input("Selecione a equipe para localizar a pasta deste arquivo (1 - LEBATEC, 2 - BRAVORE, 3 - PROPRIA): ")
            if eqp in ['1', '2', '3']:
                break
            print("Escolha inválida. Digite 1, 2 ou 3.")
        
        if eqp == '1':
            nome_equipe = "LEBATEC"
        elif eqp == '2':
            nome_equipe = "BRAVORE"
        else:
            nome_equipe = "PROPRIA"
        
        # Defina o novo caminho com base na equipe selecionada
        novo_caminho = os.path.join(pasta_mes, 'dados', nome_equipe, os.path.basename(path))
        print(f"Verificando no caminho: {novo_caminho}")
        
        if os.path.exists(novo_caminho):
            path = novo_caminho
            print(f"Arquivo encontrado no caminho: {novo_caminho}")
        else:
            print(f"Erro: O arquivo '{novo_caminho}' também não foi encontrado.")
            continue
    # Continue com o processamento do arquivo

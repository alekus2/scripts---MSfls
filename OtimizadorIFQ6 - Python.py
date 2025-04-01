if colunas_faltando:
    print(f"colunas da planilha: {df.columns}")
    print(f"Erro: As colunas esperadas não foram encontradas no arquivo '{path}': {', '.join(colunas_faltando)}")
    
    # Tente ler a segunda aba (sheet 1)
    try:
        df = pd.read_excel(path, sheet_name=1)
        df.columns = [str(col).strip().upper() for col in df.columns]
        
        # Verifique novamente as colunas
        colunas_faltando = [col for col in nomes_colunas if col not in df.columns]
        if colunas_faltando:
            print(f"Erro: As colunas esperadas não foram encontradas na segunda aba do arquivo '{path}': {', '.join(colunas_faltando)}")
            continue  # Continue para o próximo arquivo caso as colunas ainda estejam faltando
    except Exception as e:
        print(f"Erro ao ler a segunda aba do arquivo '{path}': {e}")
        continue  # Continue caso ocorra um erro na leitura
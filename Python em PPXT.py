# --- Parte 2: Criar o gráfico com os ajustes solicitados ---
try:
    # Supondo que df já contenha todas as semanas (mesmo aquelas sem dados)
    # e que os valores faltantes já foram substituídos por 0.
    categorias = [
        'Semana ' + str(int(semana)) if isinstance(semana, (int, float)) else str(semana)
        for semana in df['Semanas']
    ]
    # Se houver semanas sem valor, elas já terão 0.
    valores_sof = df['Porcentagem SOF'].fillna(0).values
    valores_vpd = df['Porcentagem VPD'].fillna(0).values
    semanas = categorias
    quantidade_realizada = {'SOF': valores_sof, 'VPD': valores_vpd}

    # Identifica a última semana com dados (valor > 0 em pelo menos uma série)
    data_sum = np.array(valores_sof) + np.array(valores_vpd)
    if np.any(data_sum > 0):
        last_data_idx = np.where(data_sum > 0)[0][-1]
    else:
        last_data_idx = len(semanas) - 1

    fig, ax = plt.subplots(figsize=(12, 6))
    bottom = np.zeros(len(semanas))
    
    # Variável para a largura ajustável das barras
    bar_width = 0.6  # ajuste conforme necessário
    cores = ['#548235', '#A9D18E']

    # Plota as barras para cada série; semanas sem dados terão barra de altura 0.
    for i, (quantidade, valores) in enumerate(quantidade_realizada.items()):
        ax.bar(semanas, valores, width=bar_width, label=quantidade, bottom=bottom, color=cores[i])
        bottom += valores
        # Removido: loop para adicionar valores sobre as barras.

    # Desenha a linha da meta somente até a última semana com dados.
    meta = 100
    # O eixo x, mesmo com categorias, pode ser tratado como índices:
    # A posição inicial é -0.5 (início da primeira barra) e a final é last_data_idx + 0.5.
    ax.plot([-0.5, last_data_idx + 0.5], [meta, meta],
            color='darkgrey', linewidth=2, linestyle='--', label='Meta')

    ax.set_title(f'ACOMPANHAMENTO CICLO SOF - {nome}', fontsize=14)
    ax.set_ylim(0, 200)
    
    # Exibe a legenda abaixo do gráfico.
    ax.legend(loc='upper center', bbox_to_anchor=(0.5, -0.12), ncol=3)
    
    # Rótulos do eixo x alinhados, sem rotação.
    plt.xticks(rotation=0, ha='center')

    # Prepara o nome do arquivo e salva o gráfico.
    nome_arquivo = "".join(c for c in nome if c.isalnum() or c in "_-.").strip()
    nome_arquivo = nome_arquivo if nome_arquivo else "grafico"
    nome_arquivo += ".png"
    
    plt.savefig(nome_arquivo, format='png', dpi=300)

except Exception as e:
    print(f"Erro ao gerar o gráfico: {e}")
    sys.exit(1)

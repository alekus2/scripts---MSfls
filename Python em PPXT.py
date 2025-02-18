# --- Parte 2: Criar o gráfico com os ajustes solicitados ---
try:
    # Garante que todas as semanas sejam exibidas, mesmo com valores zero
    categorias = [
        'Semana ' + str(int(semana)) if isinstance(semana, (int, float)) else str(semana)
        for semana in df['Semanas']
    ]
    valores_sof = df['Porcentagem SOF'].fillna(0).values
    valores_vpd = df['Porcentagem VPD'].fillna(0).values
    semanas = categorias
    quantidade_realizada = {'SOF': valores_sof, 'VPD': valores_vpd}

    # Identifica a última semana com dados (soma dos valores > 0)
    data_sum = np.array(valores_sof) + np.array(valores_vpd)
    if np.any(data_sum > 0):
        last_data_idx = np.where(data_sum > 0)[0][-1]
    else:
        last_data_idx = len(semanas) - 1

    fig, ax = plt.subplots(figsize=(12, 6))
    bottom = np.zeros(len(semanas))
    
    bar_width = 0.6  # Largura ajustável das barras
    cores = ['#548235', '#A9D18E']

    # Plota as barras para cada série
    for i, (quantidade, valores) in enumerate(quantidade_realizada.items()):
        bars = ax.bar(semanas, valores, width=bar_width, label=quantidade, bottom=bottom, color=cores[i])
        bottom += valores
        # Se você quiser que as porcentagens apareçam dentro das barras, descomente o trecho abaixo:
        """
        for rect, valor in zip(bars, valores):
            if valor > 0:
                ax.text(rect.get_x() + rect.get_width() / 2,
                        rect.get_y() + rect.get_height() / 2,
                        f'{valor:.0f}%',
                        ha='center', va='center', fontsize=10, color='white')
        """

    # Linha da meta desenhada somente até a última semana com dados
    meta = 100
    ax.plot([-0.5, last_data_idx + 0.5], [meta, meta],
            color='darkgrey', linewidth=2, linestyle='--', label='Meta')

    ax.set_title(f'ACOMPANHAMENTO CICLO SOF - {nome}', fontsize=14)
    ax.set_ylim(0, 200)
    
    # Exibe a legenda abaixo do gráfico
    ax.legend(loc='upper center', bbox_to_anchor=(0.5, -0.12), ncol=3)
    
    # Rótulos do eixo x alinhados (sem rotação)
    plt.xticks(rotation=0, ha='center')
    
    # Remove os números do eixo y (0 a 200)
    ax.tick_params(axis='y', labelleft=False)
    
    # Salva o gráfico
    nome_arquivo = "".join(c for c in nome if c.isalnum() or c in "_-.").strip()
    nome_arquivo = nome_arquivo if nome_arquivo else "grafico"
    nome_arquivo += ".png"
    
    plt.savefig(nome_arquivo, format='png', dpi=300)

except Exception as e:
    print(f"Erro ao gerar o gráfico: {e}")
    sys.exit(1)

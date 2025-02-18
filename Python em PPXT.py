# --- Parte 2: Criar o gráfico com ajustes ---
try:
    # Filtrar linhas com valores válidos (última linha com dados)
    df = df[(df['Porcentagem SOF'].notna()) | (df['Porcentagem VPD'].notna())].reset_index(drop=True)

    categorias = [
        'Semana ' + str(int(semana)) if isinstance(semana, (int, float)) else str(semana)
        for semana in df['Semanas']
    ]
    valores_sof = df['Porcentagem SOF'].fillna(0).values
    valores_vpd = df['Porcentagem VPD'].fillna(0).values

    semanas = categorias
    quantidade_realizada = {'SOF': valores_sof, 'VPD': valores_vpd}

    fig, ax = plt.subplots(figsize=(12, 6))
    bottom = np.zeros(len(semanas))
    
    # Largura ajustável da barra
    bar_width = 0.6  # Altere conforme necessário
    cores = ['#548235', '#A9D18E']

    for i, (quantidade, valores) in enumerate(quantidade_realizada.items()):
        bars = ax.bar(semanas, valores, width=bar_width, label=quantidade, bottom=bottom, color=cores[i])
        bottom += valores
        for rect, valor in zip(bars, valores):
            if valor > 0:
                ax.text(rect.get_x() + rect.get_width() / 2,
                        rect.get_y() + rect.get_height() / 2,
                        f'{valor:.0f}%',
                        ha='center', va='center', fontsize=10, color='white')

    meta = 100
    ax.plot([-0.5, len(semanas) - 0.5], [meta, meta],
            color='darkgrey', linewidth=2, linestyle='--', label='Meta')

    ax.set_title(f'ACOMPANHAMENTO CICLO SOF - {nome}', fontsize=14)
    ax.set_ylim(0, 200)
    
    # Legenda posicionada abaixo do eixo x
    ax.legend(loc='upper center', bbox_to_anchor=(0.5, -0.12), ncol=len(quantidade_realizada))
    
    # Rótulos do eixo x alinhados (sem rotação)
    plt.xticks(rotation=0, ha='center')

    # Salvar imagem
    nome_arquivo = "".join(c for c in nome if c.isalnum() or c in "_-.").strip()
    nome_arquivo = nome_arquivo if nome_arquivo else "grafico"
    nome_arquivo += ".png"

    if os.path.exists(nome_arquivo):
        print("Esse arquivo já existe. Vou facilitar para você...")
    else:
        plt.savefig(nome_arquivo, format='png', dpi=300)

except Exception as e:
    print(f"Erro ao gerar o gráfico: {e}")
    sys.exit(1)

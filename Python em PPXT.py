import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import os
import sys

# --- Parte 1: Ler os dados do Excel ---
try:
    arquivo_excel = r'/content/TesteExcel.xlsx'

    if not os.path.exists(arquivo_excel):
        raise FileNotFoundError(f"Erro: O arquivo '{arquivo_excel}' não foi encontrado no diretório atual.")

    df = pd.read_excel(arquivo_excel, sheet_name=1)

    colunas_esperadas = ['Nome', 'Valores Reais', 'Plano']
    for coluna in colunas_esperadas:
        if coluna not in df.columns:
            raise KeyError(f"Erro: A coluna esperada '{coluna}' não foi encontrada no arquivo Excel.")
    titulos = df['Titulo'].astype(str).values
    nomes = df['Nome'].astype(str).values
    valores_real = df['Valores Reais'].fillna(0).values
    valores_plano = df['Plano'].fillna(0).values

except Exception as e:
    print(f"Erro ao processar o Excel: {e}")
    sys.exit(1)

# --- Parte 2: Criar o gráfico ---
try:
    fig, ax = plt.subplots(figsize=(12, 6))

    indices = np.arange(len(nomes))  
    largura = 0.5  

    bars_real = ax.bar(indices, valores_real, width=largura, color='#4472c4', label='Real')

    for i in range(len(nomes)):
        ax.add_patch(plt.Rectangle(
            (indices[i] - largura / 2, 0),  
            largura, valores_plano[i],      
            fill=False, edgecolor='#5e774c', linestyle='dashed', linewidth=2, label='Plano' if i == 0 else ""
        ))

    # Remover texto nas barras se o valor for zero, mas as barras continuam visíveis
    for bar, real, plano in zip(bars_real, valores_real, valores_plano):
        height = bar.get_height()
        
        # Adicionar texto dentro da barra Real apenas se o valor for diferente de zero
        if real != 0:
            ax.text(bar.get_x() + bar.get_width()/2, height/2, f'{real:,.0f}', 
                    ha='center', va='center', fontsize=10, color='white', fontweight='bold')
        
        # Adicionar texto em cima da barra Plano apenas se o valor for diferente de zero
        if plano != 0:
            ax.text(bar.get_x() + bar.get_width()/2, plano, f'{plano:,.0f}', 
                    ha='center', va='bottom', fontsize=10, color='black', fontweight='bold')

    ax.set_ylim(0, max(max(valores_real), max(valores_plano)) + 2000)
    ax.set_yticks(np.arange(0, ax.get_ylim()[1] + 1, 2000))
    
    # Remover o traço do eixo Y
    ax.yaxis.set_tick_params(length=0)

    ax.tick_params(axis='y', labelsize=10)
    ax.set_title(titulos[0], fontsize=14)
    ax.set_xticks(indices)
    ax.set_xticklabels(nomes, rotation=0, ha='center')
    
    plt.xticks(rotation=0, ha='center')

    # Habilitar a barra do eixo Y, mas sem a linha
    ax.spines['left'].set_visible(True)  # A linha do eixo Y será visível agora
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)

    ax.tick_params(axis='y', labelleft=True)

    # Remover a barra de "bottom" (se preferir)
    ax.spines['bottom'].set_visible(False)

    ax.legend(loc='upper right', frameon=False, fontsize=10)

    for spine in ['top', 'right']:
        ax.spines[spine].set_visible(False)

    # nome_arquivo = "grafico_empilhado.png"
    # plt.savefig(nome_arquivo, format='png', dpi=300, bbox_inches='tight')

    # print(f"Gráfico salvo como: {nome_arquivo}")

except Exception as e:
    print(f"Erro ao gerar o gráfico: {e}")

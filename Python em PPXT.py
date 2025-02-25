import pandas as pd
import matplotlib.pyplot as plt
from pptx import Presentation
from pptx.util import Inches
import numpy as np
import os
import sys
from pptx.dml.color import RGBColor
from pptx.util import Pt

# --- Parte 1: Ler os dados do Excel ---
try:
    arquivo_excel = r'/content/TesteExcel.xlsx'

    if not os.path.exists(arquivo_excel):
        raise FileNotFoundError(f"Erro: O arquivo '{arquivo_excel}' não foi encontrado no diretório atual.")

    df = pd.read_excel(arquivo_excel, sheet_name=1)

    colunas_esperadas = ['Nome', 'Leg', 'Valores Reais', 'Plano']
    for coluna in colunas_esperadas:
        if coluna not in df.columns:
            raise KeyError(f"Erro: A coluna esperada '{coluna}' não foi encontrada no arquivo Excel.")

    nome = df['Nome'].fillna("Desconhecido").iloc[0]
    semanas = df['Leg'].astype(str).values
    valores_real = df['Valores Reais'].fillna(0).values
    valores_plano = df['Plano'].fillna(0).values

except Exception as e:
    print(f"Erro ao processar o Excel: {e}")
    sys.exit(1)

# --- Parte 2: Criar o gráfico ---
try:
    fig, ax = plt.subplots(figsize=(14, 6))

    bar_width = 0.3
    indices = np.arange(len(semanas))
    cores = ['#4472c4', '#5e774c']

    bars_real = ax.bar(indices - bar_width/2, valores_real, width=bar_width, label='Real', color=cores[0])
    bars_plano = ax.bar(indices + bar_width/2, valores_plano, width=bar_width, label='Plano', color=cores[1])

    # Adicionando rótulos de valores nas barras
    for bars in [bars_real, bars_plano]:
        for rect in bars:
            height = rect.get_height()
            if height > 0:
                ax.text(rect.get_x() + rect.get_width()/2, height, f'{height:,.0f}', 
                        ha='center', va='bottom', fontsize=10, color='black')

    # Adicionando a linha de meta
    meta = 10000  # Ajuste conforme necessário
    ax.axhline(y=meta, color='darkgrey', linewidth=2, linestyle='--', label='Meta')

    # Configuração do eixo Y
    ax.set_ylim(0, max(max(valores_real), max(valores_plano), meta) + 2000)
    ax.set_yticks(np.arange(0, ax.get_ylim()[1] + 1, 2000))
    ax.tick_params(axis='y', labelsize=10)

    # Configuração do eixo X
    ax.set_xticks(indices)
    ax.set_xticklabels(semanas, rotation=0, ha='center')

    # Configuração da legenda
    ax.legend(loc='upper right', frameon=False, fontsize=10)

    # Removendo bordas desnecessárias
    for spine in ['top', 'right']:
        ax.spines[spine].set_visible(False)

    # Salvando o gráfico
    nome_arquivo = "".join(c for c in nome if c.isalnum() or c in "_-.").strip()
    nome_arquivo = nome_arquivo if nome_arquivo else "grafico"
    nome_arquivo += ".png"

    plt.savefig(nome_arquivo, format='png', dpi=300, bbox_inches='tight')

    print(f"Gráfico salvo como: {nome_arquivo}")

except Exception as e:
    print(f"Erro ao gerar o gráfico: {e}")
    sys.exit(1)

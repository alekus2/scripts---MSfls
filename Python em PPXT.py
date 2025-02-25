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

    colunas_esperadas = ['Nome', 'Leg', 'Valores Reais','Plano']
    for coluna in colunas_esperadas:
        if coluna not in df.columns:
            raise KeyError(f"Erro: A coluna esperada '{coluna}' não foi encontrada no arquivo Excel.")


    nome = df['Nome'].fillna("Desconhecido").iloc[0]
    valores_real = df['Valores Reais'].fillna(0).values
    valores_plano = df['Plano'].fillna(0).values

except Exception as e:
    print(f"Erro ao processar o Excel: {e}")
    sys.exit(1)

# --- Parte 2: Criar o gráfico para apresentação (ou apagar se ja existir) ---
try:
    quantidade_realizada = {'Real': valores_real, 'Plano': valores_plano}

    fig, ax = plt.subplots(figsize=(14, 6))
    bottom = np.zeros(len(semanas))

    bar_width = 0.3
    cores = ['#4472c4', '#5e774c']

    for i, (quantidade, valores) in enumerate(quantidade_realizada.items()):
        bars = ax.bar(semanas, valores, width=bar_width, label=quantidade, bottom=bottom, color=cores[i])
        for rect, valor in zip(bars, valores):
            if valor > 0:
                ax.text(rect.get_x() + rect.get_width() / 2,
                        rect.get_y() + rect.get_height() / 2,
                        f'{valor:.0f}%',
                        ha='center', va='center', fontsize=10, color='black')
        bottom += valores

    meta = 100
    ax.plot([-0.5, last_data_idx + 0.5], [meta, meta],
            color='darkgrey', linewidth=2, linestyle='--', label='Meta')
    
    ax.set_ylim(0, 200)

    ax.legend(loc='upper center', bbox_to_anchor=(0.5, -0.05), ncol= 3,  frameon=False)

    plt.xticks(rotation=0, ha='center')

    ax.tick_params(axis='y', labelleft=False)
    
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.spines['left'].set_visible(False)

    ax.tick_params(axis='y',length=0)

    nome_arquivo = "".join(c for c in nome if c.isalnum() or c in "_-.").strip()
    nome_arquivo = nome_arquivo if nome_arquivo else "grafico"
    nome_arquivo += ".png"
    

    plt.savefig(nome_arquivo, format='png', dpi=300)

except Exception as e:
    print(f"Erro ao gerar o gráfico: {e}")
    sys.exit(1)

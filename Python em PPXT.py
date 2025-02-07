import pandas as pd
import matplotlib.pyplot as plt
from pptx import Presentation
from pptx.util import Inches
import numpy as np 

# --- Parte 1: Ler os dados do Excel ---

df = pd.read_excel('TesteExcel.xlsx', sheet_name=2)

categorias = ['Semana ' + str(int(semana)) if isinstance(semana, (int, float)) else str(semana) for semana in df['Semanas']]
nome = df['Nome']
valores_sof = df['Porcentagem SOF'].fillna(0).values  
valores_vpd = df['Porcentagem VPD'].fillna(0).values  

if not any(valores_sof) and not any(valores_vpd):
    valores_sof = np.zeros(len(categorias))
    valores_vpd = np.zeros(len(categorias))

# --- Parte 2: Criar o gráfico ---
semanas = categorias  
quantidade_realizada = {
    'SOF': valores_sof,  
    'VPD': valores_vpd,
}
width = 0.6 
fig, ax = plt.subplots(figsize=(12, 6))  
bottom = np.zeros(len(semanas))  
cores = ['#548235', '#A9D18E'] 

for i, (quantidade, valores) in enumerate(quantidade_realizada.items()):
    p = ax.bar(semanas, valores, width, label=quantidade, bottom=bottom, color=cores[i])
    bottom += valores
    for rect, valor in zip(p, valores):
        if valor > 0:
            ax.text(rect.get_x() + rect.get_width() / 2, rect.get_y() + rect.get_height() / 2, f'{valor:.0f}%', 
                    ha='center', va='center', fontsize=10, color='white')
meta = 100
indices_com_valores = np.where((valores_sof > 0) | (valores_vpd > 0))[0]

if len(indices_com_valores) > 0:
    ultima_semana_idx = indices_com_valores[-1] 
    ax.plot([0, ultima_semana_idx + 0.5], [meta, meta], color='darkgrey', linewidth=2, linestyle='--', label='Meta')

ax.set_title('ACOMPANHAMENTO CICLO SOF - Bloco 05 - Janeiro/Fevereiro', fontsize=14)
ax.set_ylim(0, 200) 
ax.set_yticks([])
ax.legend()

if 'Nome' in df.columns and not df['Nome'].isnull().all():
    nome_arquivo = str(df['Nome'].iloc[0]).strip()  
    titulo_slide = nome_arquivo
    nome_arquivo = nome_arquivo.replace(" ", "_") 
    nome_arquivo = "".join(c for c in nome_arquivo if c.isalnum() or c in "_-.") 
    if nome_arquivo == "":
        nome_arquivo = "grafico"  
else:
    nome_arquivo = "grafico"

nome_arquivo += "png"  
plt.savefig(nome_arquivo, format='png', dpi=300)
plt.xticks(rotation=30, ha='right')
plt.show()

# --- Parte 3: Inserir a imagem no slide do PowerPoint ---

def adicionar_imagem_ao_slide(arquivo_modelo, slide_index, titulo, imagem_path, arquivo_saida):
    prs = Presentation(arquivo_modelo)
    slide = prs.slides[slide_index]
    for shape in slide.shapes:
        if shape.has_text_frame:
            shape.text = titulo
            break
    x = Inches(2)
    y = Inches(1.5)
    cx = Inches(5)
    cy = Inches(3)
    slide.shapes.add_picture(imagem_path, x, y, cx, cy)
    prs.save(arquivo_saida)

arquivo_modelo = "Acompanhamento semanal_04_edit.pptx" 
slide_index = 2
arquivo_saida = "Acompanhamento semanal_04_atualizado.pptx" #FAVOR:lembrar de mudar os nomes para que o excel pegue na tabela para transformar o modelo para ser totalmente editavel de forma de so precisar do excel e o script
imagem_grafico = nome_arquivo
adicionar_imagem_ao_slide(arquivo_modelo, slide_index, titulo_slide, imagem_grafico, arquivo_saida)

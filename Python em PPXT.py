import matplotlib.pyplot as plt
from pptx import Presentation
from pptx.util import Inches
import os

# --- Parte 1: Criar o gráfico com Matplotlib ---

# Dados do gráfico
categorias = ['1', '2', '3', '4']
valores = [300, 200, 300, 200]

# Criação da figura e eixos
fig, ax = plt.subplots()

# Plot das barras
bars = ax.bar(categorias, valores, color='tab:green', label='Realizados')

# Desenha uma linha horizontal estilizada em y=300
ax.axhline(300, color='blue', linestyle='--', linewidth=2.5, label='Meta 300')

# Adiciona marcadores (pontos em azul claro) na linha, na posição central de cada barra
# Para barras categóricas, os centros são 0, 1, 2, ... (matplotlib faz o mapeamento automaticamente)
x_positions = list(range(len(categorias)))
ax.scatter(x_positions, [300] * len(categorias), color='lightblue', s=100, zorder=5)

# Configura título e legenda
ax.set_title('Acompanhamento Semanal - LEBATEC')
ax.legend(title='Legenda')

# Salva a figura como imagem (PNG)
imagem_grafico = "grafico.png"
fig.savefig(imagem_grafico, bbox_inches="tight")
plt.close(fig)  # Fecha a figura para liberar memória

# --- Parte 2: Inserir a imagem no slide do PowerPoint ---

def adicionar_imagem_ao_slide(arquivo_modelo, slide_index, titulo, imagem_path, arquivo_saida):
    prs = Presentation(arquivo_modelo)
    slide = prs.slides[slide_index]

    # Atualiza o título do slide (se houver um shape com text frame)
    for shape in slide.shapes:
        if shape.has_text_frame:
            shape.text = titulo
            break

    # Define posição e tamanho para a imagem (ajuste conforme necessário)
    x = Inches(2)
    y = Inches(1.5)
    cx = Inches(5)
    cy = Inches(3)
    
    # Adiciona a imagem ao slide
    slide.shapes.add_picture(imagem_path, x, y, cx, cy)
    
    # Salva a apresentação modificada
    prs.save(arquivo_saida)

# Parâmetros de exemplo
arquivo_modelo = "Modelo_ppt_Inventario_edit.pptx"  # Apresentação modelo existente
slide_index = 3  # Por exemplo, insere no 4º slide (índice 3)
titulo_slide = "Modelo de acompanhamento."
arquivo_saida = "modelo_editado.pptx"

adicionar_imagem_ao_slide(arquivo_modelo, slide_index, titulo_slide, imagem_grafico, arquivo_saida)

import pandas as pd
import matplotlib.pyplot as plt
from pptx import Presentation
from pptx.util import Inches

# --- Parte 1: Ler os dados do Excel ---

# Lê o arquivo Excel (supondo que os dados estejam na primeira planilha)
df = pd.read_excel('dados.xlsx')

# Extraindo as colunas necessárias
categorias = df['Categoria'].astype(str).tolist()  # Converter para string, se necessário
valores = df['Realizados'].tolist()

# --- Parte 2: Criar o gráfico com Matplotlib usando os dados lidos ---
fig, ax = plt.subplots()

# Plot das barras com largura ajustada
bars = ax.bar(categorias, valores, color='tab:green', label='Realizados', width=0.3)

# Desenha uma linha horizontal estilizada (por exemplo, fixa em 300)
ax.axhline(300, color='blue', linestyle='--', linewidth=2.5, label='Meta 300')

# Adiciona marcadores (pontos em azul claro) na linha, centralizados em cada barra
x_positions = [bar.get_x() + bar.get_width()/2 for bar in bars]
ax.scatter(x_positions, [300] * len(categorias), color='lightblue', s=100, zorder=5)

ax.set_title('Acompanhamento Semanal - LEBATEC')
ax.legend(title='Legenda')

# Salva o gráfico como imagem
imagem_grafico = "grafico.png"
fig.savefig(imagem_grafico, bbox_inches="tight")
plt.close(fig)

# --- Parte 3: Inserir a imagem no slide do PowerPoint ---

def adicionar_imagem_ao_slide(arquivo_modelo, slide_index, titulo, imagem_path, arquivo_saida):
    prs = Presentation(arquivo_modelo)
    slide = prs.slides[slide_index]

    # Atualiza o título do slide (caso haja algum shape com text frame)
    for shape in slide.shapes:
        if shape.has_text_frame:
            shape.text = titulo
            break

    # Define posição e tamanho para a imagem
    x = Inches(2)
    y = Inches(1.5)
    cx = Inches(5)
    cy = Inches(3)
    
    slide.shapes.add_picture(imagem_path, x, y, cx, cy)
    prs.save(arquivo_saida)

arquivo_modelo = "Modelo_ppt_Inventario_edit.pptx"  # Apresentação modelo existente
slide_index = 3  # Exemplo: insere no 4º slide (índice 3)
titulo_slide = "Modelo de acompanhamento."
arquivo_saida = "modelo_editado.pptx"

adicionar_imagem_ao_slide(arquivo_modelo, slide_index, titulo_slide, imagem_grafico, arquivo_saida)

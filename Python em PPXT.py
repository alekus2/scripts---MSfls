import pandas as pd
import matplotlib.pyplot as plt
from pptx import Presentation
from pptx.util import Inches

# --- Parte 1: Ler os dados do Excel ---

df = pd.read_excel('TesteExcel.xlsx',sheet_name=0)
print(df.head())

categorias = df['Equipe'].astype(str).tolist() 
valores = df['Realizados'].tolist()

# --- Parte 2: Criar o gráfico com Matplotlib usando os dados lidos ---
fig, ax = plt.subplots()

bars = ax.bar(categorias, valores, color='tab:green', label='Realizados', width=0.3)

ax.axhline(300, color='blue', linestyle='--', linewidth=2.5, label='Meta')

x_positions = [bar.get_x() + bar.get_width()/2 for bar in bars]
ax.scatter(x_positions, [300] * len(categorias), color='lightblue', s=100, zorder=5)

ax.set_title('Acompanhamento Semanal - LEBATEC')
ax.legend(title='Legenda')

imagem_grafico = "grafico.png"
fig.savefig(imagem_grafico, bbox_inches="tight")
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

arquivo_modelo = "Modelo_ppt_Inventario_edit.pptx" 
slide_index = 3 
titulo_slide = "Modelo de acompanhamento."
arquivo_saida = "modelo_editado.pptx"

adicionar_imagem_ao_slide(arquivo_modelo, slide_index, titulo_slide, imagem_grafico, arquivo_saida)

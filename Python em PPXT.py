import pandas as pd
import matplotlib.pyplot as plt
from pptx import Presentation
from pptx.util import Inches

# 🔹 1. Carregar dados do Excel
file_path = "dados.xlsx"  # Nome do arquivo Excel
df = pd.read_excel(file_path)

# 🔹 2. Criar o gráfico de barras
plt.figure(figsize=(8, 5))
plt.bar(df["Espécie"], df["Volume (m³)"], color="green", alpha=0.7)

plt.xlabel("Espécie", fontsize=12, color="green")
plt.ylabel("Volume (m³)", fontsize=12, color="green")
plt.title("Volume de Madeira por Espécie", fontsize=14, color="green")
plt.xticks(rotation=30)
plt.grid(axis="y", linestyle="--", alpha=0.5)

# 🔹 3. Salvar o gráfico como imagem
graph_path = "grafico_barras.png"
plt.savefig(graph_path, bbox_inches="tight", dpi=300, facecolor="white")
plt.close()

# 🔹 4. Carregar ou criar um arquivo PowerPoint
try:
    ppt = Presentation("modelo.pptx")  # Carregar modelo existente
except FileNotFoundError:
    ppt = Presentation()  # Criar um novo PowerPoint

# 🔹 5. Criar um novo slide e adicionar o gráfico
slide_layout = ppt.slide_layouts[5]  # Layout em branco
slide = ppt.slides.add_slide(slide_layout)

# Inserir título no slide
title_shape = slide.shapes.add_textbox(Inches(1), Inches(0.5), Inches(8), Inches(1))
text_frame = title_shape.text_frame
text_frame.text = "Inventário Florestal - Gráfico de Volume"

# Adicionar o gráfico ao slide
slide.shapes.add_picture(graph_path, Inches(1), Inches(2), width=Inches(8))

# 🔹 6. Salvar a apresentação
ppt.save("Inventario_Florestal.pptx")

print("PowerPoint atualizado com sucesso!")

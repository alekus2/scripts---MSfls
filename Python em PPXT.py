import pandas as pd
import matplotlib.pyplot as plt
from pptx import Presentation
from pptx.util import Inches

file_path = "dados.xlsx"  # Nome do arquivo Excel
df = pd.read_excel(file_path)

equipes = df["Equipe"]
meta = df["Meta"].iloc[0]  # Pegando o valor da meta (assumindo que está na primeira linha da coluna)

plt.figure(figsize=(8, 5))
plt.bar(equipes, color="green", alpha=0.7, label="Quantidade Realizada")

plt.axhline(y=meta, color="blue", linestyle="--", linewidth=2, label=f"Meta ({meta} m³)")

plt.ylabel("Realizado", fontsize=12, color="green")
plt.title("Acompanhamento Semanal -LEBATEC", fontsize=14, color="green")
plt.xticks(rotation=30)
plt.grid(axis="y", linestyle="--", alpha=0.5)
plt.legend()

graph_path = "grafico_barras.png"
plt.savefig(graph_path, bbox_inches="tight", dpi=300, facecolor="white")
plt.close()

xtry:
    ppt = Presentation("modelo.pptx")  # Carregar modelo existente
except FileNotFoundError:
    ppt = Presentation()  # Criar um novo PowerPoint
slide_layout = ppt.slide_layouts[6]  # Layout em branco
slide = ppt.slides.add_slide(slide_layout)

title_shape = slide.shapes.add_textbox(Inches(1), Inches(0.5), Inches(8), Inches(1))
text_frame = title_shape.text_frame
text_frame.text = "Inventário Florestal - Gráfico de Volume"

slide.shapes.add_picture(graph_path, Inches(1), Inches(2), width=Inches(8))

ppt.save("Inventario_Florestal.pptx")

print("PowerPoint atualizado com sucesso!")

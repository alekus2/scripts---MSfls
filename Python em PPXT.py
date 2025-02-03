from pptx import Presentation
from pptx.util import Inches
from pptx.dml.color import RGBColor

# Criando uma nova apresentação
ppt = Presentation()

# Adicionando um slide com layout em branco
slide_layout = ppt.slide_layouts[5]  # Layout em branco
slide = ppt.slides.add_slide(slide_layout)

# Definindo as cores (fundo branco, texto verde)
background = slide.background
fill = background.fill
fill.solid()
fill.fore_color.rgb = RGBColor(255, 255, 255)  # Branco

# Adicionando o título "Inventário Florestal"
title_shape = slide.shapes.add_textbox(Inches(1), Inches(0.5), Inches(8), Inches(1))
text_frame = title_shape.text_frame
text_frame.text = "Inventário Florestal"
p = text_frame.paragraphs[0]
p.font.size = Inches(0.8)
p.font.bold = True
p.font.color.rgb = RGBColor(0, 128, 0)  # Verde

# Adicionando o gráfico ao slide
graph_path = "grafico.png"  # Caminho da imagem gerada
slide.shapes.add_picture(graph_path, Inches(1), Inches(2), width=Inches(8))

# Salvando a apresentação
ppt_path = "Inventario_Florestal.pptx"
ppt.save(ppt_path)

print(f"Apresentação salva como {ppt_path}")

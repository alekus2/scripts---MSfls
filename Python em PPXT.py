from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.chart.data import CategoryChartData
from pptx.enum.chart import XL_CHART_TYPE
from pptx.enum.shapes import MSO_SHAPE
from pptx.dml.color import RGBColor

# Criação da apresentação
ppt = Presentation()

# Slide 1 - Título e descrição
slide1 = ppt.slides.add_slide(ppt.slide_layouts[5])  # slide_layouts[5] é um slide em branco

# Adicionando texto em negrito e não negrito
textbox = slide1.shapes.add_textbox(Inches(1), Inches(1), Inches(8), Inches(2))
text_frame = textbox.text_frame

# Adicionando texto formatado
p = text_frame.add_paragraph()
p.text = "Modelo de Acompanhamento"
p.font.bold = True

p = text_frame.add_paragraph()
p.text = " - Este é um modelo de acompanhamento das equipes."
p.font.bold = False

# Slide 2 - Gráfico
slide2 = ppt.slides.add_slide(ppt.slide_layouts[6])

# Dados do gráfico
equipes = ["1", "2", "3", "4"]
realizadas = [200, 300, 200, 300]

x = Inches(1)
y = Inches(1)
largura = Inches(5)
altura = Inches(3)

dados_grafico = CategoryChartData()
dados_grafico.categories = equipes
dados_grafico.add_series("Acompanhamento Semanal - LEBATEC", realizadas)

# Adicionando o gráfico
chart = slide2.shapes.add_chart(XL_CHART_TYPE.COLUMN_CLUSTERED, x, y, largura, altura, dados_grafico).chart

# Adicionando a linha azul para a meta
meta = 300
# A linha precisa ser adicionada como um retângulo estreito
line = slide2.shapes.add_shape(MSO_SHAPE.RECTANGLE, x, y + altura.inches + 0.2, largura, Pt(2))
line.fill.solid()  # Preenchendo com cor sólida
line.fill.fore_color.rgb = RGBColor(0, 0, 255)  # Azul
line.line.color.rgb = RGBColor(0, 0, 255)  # Azul

# Adicionando o texto da meta
text_box_meta = slide2.shapes.add_textbox(x + largura / 2 - Inches(1), y + altura.inches + 0.4, Inches(2), Inches(0.5))
text_frame_meta = text_box_meta.text_frame
p = text_frame_meta.add_paragraph()
p.text = f"Meta: {meta}"
p.font.bold = True
p.font.size = Pt(14)

# Salvando a apresentação
ppt.save("Acompanhamento_Semanal_LEBATEC.pptx")
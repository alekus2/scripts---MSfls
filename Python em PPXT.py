from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.chart.data import CategoryChartData
from pptx.enum.chart import XL_CHART_TYPE

ppt = Presentation()
slide2 = ppt.slides.add_slide(ppt.slide_layouts[6])







equipes = ["1","2","3","4"]
realizadas = [200,300,200,300]

x = Inches(1)
y = Inches (1)
largura = Inches (5)
altura = Inches (3)

dados_grafico = CategoryChartData()
dados_grafico.categories = equipes
dados_grafico.add_series("Acompanhamento Semanal -LEBATEC", realizadas)
slide.shapes.add_chart(XL_CHART_TYPE.COLUMN_CLUSTERED, x, y, largura, altura, dados_grafico)

ppt.save("Acompanhamento Semanal -LEBATEC.pptx")

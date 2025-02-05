from pptx import Presentation
from pptx.chart.data import CategoryChartData
from pptx.enum.chart import XL_CHART_TYPE
from pptx.enum.chart import XL_LEGEND_POSITION
from pptx.util import Inches
from pptx.dml.color import RGBColor


import matplotlib.pyplot as plt

fig, ax = plt.subplots()

fruits = ['1', '2', '3', '4']
counts = [300, 200, 300, 200]
bar_labels = ['Realizados','','','']
bar_colors = ['tab:green']

ax.bar(fruits, counts, label=bar_labels, color=bar_colors)

ax.set_title('Acompanhamento Semanal - LEBATEC')
ax.legend(title='Legenda')

plt.show()


def adicionar_grafico_com_linha_meta(arquivo_modelo, slide_index, titulo, categorias, valores_realizados, arquivo_saida):
    prs = Presentation(arquivo_modelo)
    slide = prs.slides[slide_index]

    for shape in slide.shapes:
        if shape.has_text_frame:
            shape.text = titulo
            break

    x, y, cx, cy = Inches(2), Inches(1.5), Inches(5), Inches(3)

    dados_grafico = CategoryChartData()
    dados_grafico.categories = categorias
    dados_grafico.add_series("Realizados", valores_realizados)  # Série de barras
    
    graphic_frame = slide.shapes.add_chart(XL_CHART_TYPE.COLUMN_CLUSTERED, x, y, cx, cy, dados_grafico)
    chart = graphic_frame.chart

    series_realizado = chart.series[0]
    series_realizado.format.fill.solid()
    series_realizado.format.fill.fore_color.rgb = RGBColor(0, 128, 0)  # Verde

    chart.has_legend = True
    chart.legend.position = XL_LEGEND_POSITION.RIGHT
    prs.save(arquivo_saida)

categorias = ["1", "2", "3", "4"]
valores_realizados = [200, 300, 200, 300]

adicionar_grafico_com_linha_meta("Modelo_ppt_Inventario_edit.pptx", 3, "Modelo de acompanhamento.", categorias, valores_realizados, "modelo_editado.pptx")

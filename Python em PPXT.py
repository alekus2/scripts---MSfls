from pptx import Presentation
from pptx.dml.fill import FillFormat
from pptx.dml.line import LineFormat
from pptx.chart.data import CategoryChartData
from pptx.enum.chart import XL_CHART_TYPE
from pptx.enum.chart import XL_LEGEND_POSITION
from pptx.util import Inches
from pptx.dml.color import RGBColor

def adicionar_grafico_em_modelo(arquivo_modelo, slide_index, titulo, dados_grafico, meta_valores, arquivo_saida):
    prs = Presentation(arquivo_modelo)
    
    slide = prs.slides[slide_index]

    for shape in slide.shapes:
        if shape.has_text_frame:
            shape.text = titulo
            break

    x, y, cx, cy = Inches(2), Inches(1.5), Inches(2), Inches(2)
    dados_grafico = CategoryChartData()
   
    dados_grafico.categories = dados
    dados_grafico.add_series("Realizados", dados_nome)  # Alterando o nome da série
    graphic_frame = slide.shapes.add_chart(XL_CHART_TYPE.COLUMN_CLUSTERED, x, y, cx, cy, dados_grafico)

    dados_do_grafico = graphic_frame.chart

    # Formatação da série realizada
    series_realizado = dados_do_grafico.series[0]
    series_realizado.format.fill.solid()
    series_realizado.format.fill.fore_color.rgb = RGBColor(0, 128, 0)  # Verde

    # Adicionando a linha de meta
    series_meta = dados_do_grafico.series.add_series("Meta", meta_valores)
    series_meta.format.line.fill.solid()
    series_meta.format.line.fill.fore_color.rgb = RGBColor(0, 0, 255)  # Azul
    series_meta.chart_type = XL_CHART_TYPE.LINE  # Definindo como gráfico de linha

    dados_do_grafico.has_legend = True
    dados_do_grafico.legend.position = XL_LEGEND_POSITION.RIGHT  # Posição da legenda à direita

    prs.save(arquivo_saida)

# Exemplo de uso
dados = ["1", "2", "3", "4"]
dados_nome = [200, 300, 200, 300]
meta = [250, 250, 250, 250]  # Definindo os valores da meta
adicionar_grafico_em_modelo("/content/Modelo_ppt_Inventario_edit.pptx", 3, "Modelo de acompanhamento.", dados, meta, "modelo_editado.pptx")
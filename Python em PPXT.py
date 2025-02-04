from pptx import Presentation
from pptx.chart.data import CategoryChartData
from pptx.enum.chart import XL_CHART_TYPE
from pptx.util import Inches
from pptx.dml.color import RGBColor

def adicionar_grafico_em_modelo(arquivo_modelo, slide_index, titulo, dados_grafico, meta_valores, arquivo_saida):
    prs = Presentation(arquivo_modelo)
    
    # Seleciona o slide onde o gráfico será inserido
    slide = prs.slides[slide_index]

    # Adicionar título (se existir um placeholder para texto)
    for shape in slide.shapes:
        if shape.has_text_frame:
            shape.text = titulo
            break

    # Criar dados do gráfico
    chart_data = CategoryChartData()
    categorias = list(dados_grafico.keys())
    valores = list(dados_grafico.values())

    chart_data.categories = categorias
    chart_data.add_series("Valores", valores)  # Barras do gráfico
    chart_data.add_series("Meta", meta_valores)  # Linha de meta

    # Adicionar gráfico ao slide
    x, y, cx, cy = Inches(1), Inches(1.5), Inches(8), Inches(4.5)
    graphic_frame = slide.shapes.add_chart(
        XL_CHART_TYPE.COLUMN_CLUSTERED, x, y, cx, cy, chart_data
    )

    # Estilizar a linha da "Meta"
    chart = graphic_frame.chart
    series_meta = chart.series[1]
    series_meta.format.line.color.rgb = RGBColor(0, 0, 255)  # Azul

    # Salvar a apresentação com as alterações
    prs.save(arquivo_saida)

# Exemplo de uso
dados = {"1": 0, "2": 10, "3": 200, "4": 100}
meta = [50, 50, 50, 50]  # Valores da linha "Meta"

adicionar_grafico_em_modelo("modelo.pptx", 3, "Acompanhamento Semanal - LEBATEC", dados, meta, "modelo_editado.pptx

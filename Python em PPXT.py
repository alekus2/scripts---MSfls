from pptx import Presentation
from pptx.chart.data import CategoryChartData
from pptx.enum.chart import XL_CHART_TYPE
from pptx.enum.chart import XL_LEGEND_POSITION
from pptx.util import Inches
from pptx.dml.color import RGBColor

def adicionar_grafico_com_linha_meta(arquivo_modelo, slide_index, titulo, categorias, valores_realizados, valor_meta, arquivo_saida):
    prs = Presentation(arquivo_modelo)
    slide = prs.slides[slide_index]

    # Alterar o título do slide, se houver
    for shape in slide.shapes:
        if shape.has_text_frame:
            shape.text = titulo
            break

    # Posição e tamanho do gráfico
    x, y, cx, cy = Inches(2), Inches(1.5), Inches(5), Inches(3)

    # Criando os dados do gráfico
    dados_grafico = CategoryChartData()
    dados_grafico.categories = categorias
    dados_grafico.add_series("Realizados", valores_realizados)  # Série de barras
    
    # Criando uma série de linha que cubra todas as categorias
    valores_meta = [valor_meta] * len(categorias)  # Repete o mesmo valor para todas as colunas
    dados_grafico.add_series("Meta", valores_meta)  

    # Adicionando o gráfico ao slide
    graphic_frame = slide.shapes.add_chart(XL_CHART_TYPE.COLUMN_CLUSTERED, x, y, cx, cy, dados_grafico)
    chart = graphic_frame.chart

    # Formatação da série "Realizados" (barras verdes)
    series_realizado = chart.series[0]
    series_realizado.format.fill.solid()
    series_realizado.format.fill.fore_color.rgb = RGBColor(0, 128, 0)  # Verde

    # Formatação da série "Meta" (linha azul contínua)
    series_meta = chart.series[1]
    series_meta.chart_type = XL_CHART_TYPE.LINE  # Linha contínua
    series_meta.format.line.fill.solid()
    series_meta.format.line.fill.fore_color.rgb = RGBColor(0, 0, 255)  # Azul

    # Configuração da legenda
    chart.has_legend = True
    chart.legend.position = XL_LEGEND_POSITION.RIGHT

    # Salvando a apresentação editada
    prs.save(arquivo_saida)

# Exemplo de uso
categorias = ["1", "2", "3", "4"]
valores_realizados = [200, 300, 200, 300]
valor_meta = 250  # Valor da linha meta (fixo)

adicionar_grafico_com_linha_meta("Modelo_ppt_Inventario_edit.pptx", 3, "Modelo de acompanhamento.", categorias, valores_realizados, valor_meta, "modelo_editado.pptx")

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
    chart_data.add_series("Realizado", valores)  # Barras do gráfico
    chart_data.add_series("Meta", meta_valores)  # Linha de meta

    # Adicionar gráfico ao slide
    x, y, cx, cy = Inches(1), Inches(1), Inches(4), Inches(3.5)
    graphic_frame = slide.shapes.add_chart(
        XL_CHART_TYPE.COLUMN_CLUSTERED, x, y, cx, cy, chart_data
    )

    # Estilizar a série "Realizado" (barras verdes)
    chart = graphic_frame.chart
    series_realizado = chart.series[0]
    series_realizado.format.fill.solid()
    series_realizado.format.fill.fore_color.rgb = RGBColor(0, 128, 0)  # Verde

    # Estilizar a linha da "Meta" (linha azul com pontos)
    series_meta = chart.series[1]
    series_meta.format.line.color.rgb = RGBColor(0, 0, 255)  # Azul
    series_meta.format.line.width = Inches(0.1)  # Largura da linha

    # Adicionar legenda
    chart.has_legend = True
    chart.legend.position = xl
    chart.legend.include_in_layout = False

    # Salvar a apresentação com as alterações
    prs.save(arquivo_saida)

# Exemplo de uso
dados = {"1": 0, "2": 10, "3": 200, "4": 100}
meta = [300, 300, 300, 300]  # Valores da linha "Meta"

adicionar_grafico_em_modelo("/content/Modelo_ppt_Inventario_edit.pptx", 3, "Acompanhamento Semanal - LEBATEC", dados, meta, "modelo_editado.pptx")

---------------------------------------------------------------------------
AttributeError                            Traceback (most recent call last)
<ipython-input-9-7c77cb2ea02e> in <cell line: 0>()
     55 meta = [300, 300, 300, 300]  # Valores da linha "Meta"
     56 
---> 57 adicionar_grafico_em_modelo("/content/Modelo_ppt_Inventario_edit.pptx", 3, "Acompanhamento Semanal - LEBATEC", dados, meta, "modelo_editado.pptx")

1 frames
<ipython-input-9-7c77cb2ea02e> in adicionar_grafico_em_modelo(arquivo_modelo, slide_index, titulo, dados_grafico, meta_valores, arquivo_saida)
     45     # Adicionar legenda
     46     chart.has_legend = True
---> 47     chart.legend.position = XL_CHART_TYPE.RIGHT
     48     chart.legend.include_in_layout = False
     49 

/usr/lib/python3.11/enum.py in __getattr__(cls, name)
    784             return cls._member_map_[name]
    785         except KeyError:
--> 786             raise AttributeError(name) from None
    787 
    788     def __getitem__(cls, name):

AttributeError: RIGHT

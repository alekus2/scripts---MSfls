# from os import remove
# import pandas as pd
# import matplotlib.pyplot as plt
# from pptx import Presentation
# from pptx.util import Inches

# file_path = "/content/dados.xlsx"  
# df = pd.read_excel(file_path)

# plt.figure(figsize=(8, 5))
# plt.bar(df["Equipe"],df["Realizados"], color="green", alpha=0.7)
# plt.xlabel("Equipes", fontsize=12, color="green")
# plt.ylabel("Realizados", fontsize=12, color="green")
# plt.title("Acompanhamento Semanal - LEBATEC", fontsize=14, color="green")
# plt.xticks(rotation=30)
# plt.grid(axis="y", linestyle="--", alpha=0.5)
# graph_path = "grafico_barras.png"
# plt.savefig(graph_path, bbox_inches="tight", dpi=300, facecolor="white")
# plt.close()

# def remove_slides (ppt,slide_index):
#   xml_slides=ppt.slides._sldIdLst
#   slides=list(xml_slides)
#   if 0 <= slide_index <len(slides):
#     xml_slides.remove(slides[slide_index])
#   else:
#     print("lascouse")
# try:
#     ppt = Presentation("/content/Modelo_ppt_Inventario_edit.pptx")  # Carregar modelo existente
#     remove_slides(ppt, 3)
# except FileNotFoundError:
#     ppt = Presentation()  # Criar um novo PowerPoint
# slide_layout = ppt.slide_layouts[5]  # Layout em branco
# slide = ppt.slides.add_slide(slide_layout)
# title_shape = slide.shapes.add_textbox(Inches(1), Inches(0.5), Inches(8), Inches(1))
# text_frame = title_shape.text_frame
# text_frame.text = "Modelo de acompanhamento:"



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
    x, y, cx, cy = Inches(1), Inches(1), Inches(4), Inches(3.5)
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
meta = [300, 300, 300, 300]  # Valores da linha "Meta"

adicionar_grafico_em_modelo("/content/Modelo_ppt_Inventario_edit.pptx", 3, "Acompanhamento Semanal - LEBATEC", dados, meta, "modelo_editado.pptx")

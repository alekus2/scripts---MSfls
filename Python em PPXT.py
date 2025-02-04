from pptx import Presentation
from pptx.util import Inches

def atualizar_apresentacao(arquivo_modelo, titulo, dados_grafico, arquivo_saida):
    prs = Presentation(arquivo_modelo)
    slide = prs.slides[3]
    for shape in slide.shapes:
        if shape.has_text_frame:
            shape.text = titulo  # Substitui o texto do primeiro placeholder encontrado
            break

    # Atualizar gráfico
    for shape in slide.shapes:
        if shape.has_chart:
            chart = shape.chart
            chart_data = chart.chart_data

            # Limpa os dados antigos
            categorias = list(dados_grafico.keys())
            valores = list(dados_grafico.values())

            chart_data.categories = categorias
            serie = chart_data.series[0]  # Supondo uma única série
            serie.values = valores
            
            break

    # Salvar a nova apresentação
    prs.save(arquivo_saida)

# Exemplo de uso
dados = {
    "1": 0,
    "2": 00,
    "3": 200,
    "4": 100
}

atualizar_apresentacao("/content/Modelo_ppt_Inventario_edit.pptx", "Acompanhamento Semanal -LEBATEC", dados, "Acompanhamento Semanal -LEBATEC.pptx")

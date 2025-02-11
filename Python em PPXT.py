from pptx import Presentation
from pptx.util import Inches
from pptx.dml.color import RGBColor

def adicionar_imagem_ao_slide(arquivo_modelo, slide_index, titulo, imagem_path, arquivo_saida):
    try:
        if not os.path.exists(arquivo_modelo):
            raise FileNotFoundError(f"Erro: O arquivo do PowerPoint '{arquivo_modelo}' não foi encontrado.")

        prs = Presentation(arquivo_modelo)

        if slide_index >= len(prs.slides):
            raise IndexError(f"Erro: O slide de índice {slide_index} não existe na apresentação.")

        slide = prs.slides[slide_index]
        
        # Remover todas as caixas de texto do slide antes de adicionar novas
        for shape in reversed(slide.shapes):
            if shape.has_text_frame:
                slide.shapes._spTree.remove(shape._element)

        # Adicionar imagem ao slide
        x = Inches(0.5)
        y = Inches(0.6)
        cx = Inches(9)
        cy = Inches(3.3)
        slide.shapes.add_picture(imagem_path, x, y, cx, cy)

        # Adicionar novo título com negrito, itálico e cor RGB(5, 80, 46)
        x_text = Inches(0)
        y_text = Inches(0)
        cx_text = Inches(9)
        cy_text = Inches(0.6)
        caixa_texto = slide.shapes.add_textbox(x_text, y_text, cx_text, cy_text)
        text_frame = caixa_texto.text_frame
        text_frame.clear()  # Remove formatação padrão

        p_titulo = text_frame.add_paragraph()
        run_titulo = p_titulo.add_run()
        run_titulo.text = titulo
        run_titulo.font.bold = True  
        run_titulo.font.italic = True  
        run_titulo.font.color.rgb = RGBColor(5, 80, 46)  

        # Criar a nova caixa de texto "Resumo da Semana" com fundo 251,229,214
        x_text = Inches(0)
        y_text = Inches(3.8)
        cx_text = Inches(9.4)
        cy_text = Inches(1.6)
        nova_caixa_texto = slide.shapes.add_textbox(x_text, y_text, cx_text, cy_text)
        text_frame2 = nova_caixa_texto.text_frame
        text_frame2.text = "Resumo da Semana"

        # Definir a cor de fundo da nova caixa de texto
        fill = nova_caixa_texto.fill
        fill.solid()
        fill.fore_color.rgb = RGBColor(251, 229, 214)  

        # Lista de informações com marcadores personalizados
        informacoes = [
            "Programado: XXX,X mil ha",
            "Meta semanal: XX,X mil ha",
            "Realizado última semana: XX,X mil ha"
        ]

        for item in informacoes:
            partes = item.split(":")
            if len(partes) > 1:
                # Criar um parágrafo com marcador nativo do PowerPoint
                p = text_frame2.add_paragraph()
                p.level = 0  # Define o nível de marcador
                p.text = partes[0] + ": "

                # Definir marcador ✔ (código Unicode: 0x2713)
                p.bullet.character = chr(0x2713)  

                # Criar a segunda parte (negrito e fundo amarelo)
                run2 = p.add_run()
                run2.text = partes[1].strip()
                run2.font.bold = True  
                run2.font.highlight_color = 3  # 3 é o código para amarelo no PowerPoint

        prs.save(arquivo_saida)
        print(f"Arquivo PowerPoint atualizado salvo como: {arquivo_saida}")

    except Exception as e:
        print(f"Erro ao modificar o PowerPoint: {e}")

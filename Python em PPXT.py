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
        
        # Remover a última caixa de texto do slide
        for shape in reversed(slide.shapes):
            if shape.has_text_frame:
                slide.shapes._spTree.remove(shape._element)
                break  

        # Adicionar imagem ao slide
        x = Inches(0.5)
        y = Inches(0.6)
        cx = Inches(9)
        cy = Inches(3.3)
        slide.shapes.add_picture(imagem_path, x, y, cx, cy)

        # Adicionar título
        x_text = Inches(0)
        y_text = Inches(0)
        cx_text = Inches(9)
        cy_text = Inches(0.6)
        caixa_texto = slide.shapes.add_textbox(x_text, y_text, cx_text, cy_text)
        text_frame = caixa_texto.text_frame
        text_frame.text = titulo

        # Criar a nova caixa de texto com fundo na cor 251,229,214
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

        # Lista de informações
        informacoes = [
            "Programado: XXX,X mil ha",
            "Meta semanal: XX,X mil ha",
            "Realizado última semana: XX,X mil ha"
        ]

        for item in informacoes:
            p = text_frame2.add_paragraph()
            partes = item.split(":")
            
            if len(partes) > 1:
                run1 = p.add_run()
                run1.text = partes[0] + ": "  
                run1.font.bold = False  

                run2 = p.add_run()
                run2.text = " " + partes[1].strip() + " "  # Adiciona espaços para realçar o fundo
                run2.font.bold = True  
                
                # Simular fundo amarelo adicionando um espaçamento visual
                run2.font.highlight_color = RGBColor(255, 255, 0)

            p.space_after = Inches(0.1)
            p.level = 0

        prs.save(arquivo_saida)
        print(f"Arquivo PowerPoint atualizado salvo como: {arquivo_saida}")

    except Exception as e:
        print(f"Erro ao modificar o PowerPoint: {e}")

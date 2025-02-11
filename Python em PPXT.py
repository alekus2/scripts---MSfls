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
        
        # Remover o título existente antes de adicionar um novo
        for shape in reversed(slide.shapes):
            if shape.has_text_frame and shape.text_frame.text.strip() == titulo.strip():
                slide.shapes._spTree.remove(shape._element)
                break  

        # Adicionar imagem ao slide
        x = Inches(0.5)
        y = Inches(0.6)
        cx = Inches(9)
        cy = Inches(3.3)
        slide.shapes.add_picture(imagem_path, x, y, cx, cy)

        # Adicionar novo título
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
            partes = item.split(":")
            if len(partes) > 1:
                # Criar a primeira parte (normal)
                p = text_frame2.add_paragraph()
                run1 = p.add_run()
                run1.text = partes[0] + ": "
                run1.font.bold = False  

                # Criar um novo textbox APENAS para a parte que precisa de fundo amarelo
                x_destaque = x_text + Inches(3)  # Ajuste de posição
                y_destaque = y_text + Inches(0.3) + (len(text_frame2.paragraphs) * Inches(0.4))
                cx_destaque = Inches(2)
                cy_destaque = Inches(0.3)
                
                caixa_destaque = slide.shapes.add_textbox(x_destaque, y_destaque, cx_destaque, cy_destaque)
                text_frame_destaque = caixa_destaque.text_frame
                text_frame_destaque.word_wrap = True
                
                # Definir fundo amarelo no novo textbox
                fill_destaque = caixa_destaque.fill
                fill_destaque.solid()
                fill_destaque.fore_color.rgb = RGBColor(255, 255, 0)

                # Adicionar o texto com negrito no novo textbox
                p_destaque = text_frame_destaque.add_paragraph()
                run_destaque = p_destaque.add_run()
                run_destaque.text = partes[1].strip()
                run_destaque.font.bold = True  

        prs.save(arquivo_saida)
        print(f"Arquivo PowerPoint atualizado salvo como: {arquivo_saida}")

    except Exception as e:
        print(f"Erro ao modificar o PowerPoint: {e}")

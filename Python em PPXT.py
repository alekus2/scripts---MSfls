import os

def adicionar_imagem_ao_slide(arquivo_modelo, slide_index, titulo, imagem_path, arquivo_saida):
    try:
        if not os.path.exists(arquivo_modelo):
            raise FileNotFoundError(f"Erro: O arquivo do PowerPoint '{arquivo_modelo}' não foi encontrado.")

        if not os.path.exists(imagem_path):
            raise FileNotFoundError(f"Erro: A imagem '{imagem_path}' não foi encontrada.")

        prs = Presentation(arquivo_modelo)

        if slide_index >= len(prs.slides):
            raise IndexError(f"Erro: O slide de índice {slide_index} não existe na apresentação.")

        slide = prs.slides[slide_index]
        
        for shape in reversed(slide.shapes):
            if shape.has_text_frame:
                slide.shapes._spTree.remove(shape._element)
        
        # Adiciona a imagem ao slide
        x = Inches(0.5)
        y = Inches(0.5)
        cx = Inches(8)
        cy = Inches(3.4)
        slide.shapes.add_picture(imagem_path, x, y, cx, cy)
        
        # Adiciona título ao slide
        x_text = Inches(0)
        y_text = Inches(0)
        cx_text = Inches(9)
        cy_text = Inches(0.5)
        caixa_texto = slide.shapes.add_textbox(x_text, y_text, cx_text, cy_text)
        text_frame = caixa_texto.text_frame
        text_frame.clear()
        
        p_titulo = text_frame.add_paragraph()
        run_titulo = p_titulo.add_run()
        run_titulo.text = titulo
        run_titulo.font.bold = True  
        run_titulo.font.italic = True  
        run_titulo.font.color.rgb = RGBColor(5, 80, 46)  
        
        prs.save(arquivo_saida)
        print(f"Arquivo PowerPoint atualizado salvo como: {arquivo_saida}")

        # Verifica se a imagem existe e a remove
        if os.path.exists(imagem_path):
            os.remove(imagem_path)
            print(f"Imagem '{imagem_path}' removida com sucesso após uso.")

    except Exception as e:
        print(f"Erro ao modificar o PowerPoint: {e}")

arquivo_modelo = r'F:\Qualidade_Florestal\02- MATO GROSSO DO SUL\11- Administrativo Qualidade MS\00- Colaboradores\17 - Alex Vinicius\Pasta exemplos a serem usados\Acompanhamento semanal_04_edit.pptx'
slide_index = 2
arquivo_saida = "Acompanhamento semanal_04_atualizado.pptx"
imagem_grafico = nome_arquivo

adicionar_imagem_ao_slide(arquivo_modelo, slide_index, nome, imagem_grafico, arquivo_saida)

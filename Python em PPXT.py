def adicionar_imagem_ao_slide(arquivo_modelo, slide_index, titulo, imagem_path, arquivo_saida):
    try:
        if not os.path.exists(arquivo_modelo):
            raise FileNotFoundError(f"Erro: O arquivo do PowerPoint '{arquivo_modelo}' não foi encontrado.")

        prs = Presentation(arquivo_modelo)

        if slide_index >= len(prs.slides):
            raise IndexError(f"Erro: O slide de índice {slide_index} não existe na apresentação.")

        slide = prs.slides[slide_index]
        
        # Adicionar imagem
        x = Inches(0.5)
        y = Inches(0.6)
        cx = Inches(9)
        cy = Inches(3.3)
        slide.shapes.add_picture(imagem_path, x, y, cx, cy)

        # Título na parte superior
        x_text = Inches(0)
        y_text = Inches(0)  # Ajustar para o topo
        cx_text = Inches(9)
        cy_text = Inches(0.6)
        caixa_texto = slide.shapes.add_textbox(x_text, y_text, cx_text, cy_text)
        text_frame = caixa_texto.text_frame
        text_frame.text = titulo

        # Remover caixa de texto anterior (se existir) e adicionar nova caixa de texto
        for shape in slide.shapes:
            if shape.has_text_frame and shape.text_frame.text == "Resumo da Semana":
                slide.shapes.remove(shape)

        # Criar nova caixa de texto para resumo
        x_text = Inches(0)
        y_text = Inches(3.8)
        cx_text = Inches(9.4)
        cy_text = Inches(1.6)
        nova_caixa_texto = slide.shapes.add_textbox(x_text, y_text, cx_text, cy_text)
        text_frame2 = nova_caixa_texto.text_frame
        text_frame2.text = "Resumo da Semana"

        # Adicionar itens com formatação
        for item in ["Programado: XXX,X mil ha", "Meta semanal: XX,X mil ha", "Realizado última semana: XX,X mil ha"]:
            p = text_frame2.add_paragraph()
            p.text = item
            
            # Formatar texto após os dois pontos
            if ':' in item:
                # Dividir o texto em duas partes
                partes = item.split(':')
                p.text = partes[0] + ':'  # Texto antes dos dois pontos

                # Adiciona novo parágrafo para o texto após os dois pontos
                p2 = text_frame2.add_paragraph()
                p2.text = partes[1].strip()  # Texto após os dois pontos
                p2.font.bold = True  # Definir em negrito
                
                # Definir fundo amarelo apenas para o parágrafo após os dois pontos
                fill = p2.fill
                fill.solid()
                fill.fore_color.rgb = RGBColor(255, 255, 0)  # Amarelo

            p.space_after = Inches(0.1)
            p.level = 0

        # Definir fundo padrão para a nova caixa de texto (RGB 251, 229, 214)
        fill = nova_caixa_texto.fill
        fill.solid()
        fill.fore_color.rgb = RGBColor(251, 229, 214)  # Cor personalizada
        prs.save(arquivo_saida)
        print(f"Arquivo PowerPoint atualizado salvo como: {arquivo_saida}")

    except Exception as e:
        print(f"Erro ao modificar o PowerPoint: {e}")
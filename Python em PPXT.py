# --- Parte 3: Inserir a imagem no PowerPoint (trecho ajustado para a caixa de texto inferior) ---

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
        
        # Remove os elementos de texto existentes no slide
        for shape in reversed(slide.shapes):
            if shape.has_text_frame:
                slide.shapes._spTree.remove(shape._element)
        
        # Adiciona a imagem do gráfico
        x = Inches(0)
        y = Inches(0.6)
        cx = Inches(10)
        cy = Inches(3.4)
        slide.shapes.add_picture(imagem_path, x, y, cx, cy)
        
        # Adiciona o título no topo do slide
        x_text = Inches(0)
        y_text = Inches(0)
        cx_text = Inches(9)
        cy_text = Inches(0.5)
        caixa_titulo = slide.shapes.add_textbox(x_text, y_text, cx_text, cy_text)
        tf_titulo = caixa_titulo.text_frame
        tf_titulo.clear()  

        p_titulo = tf_titulo.add_paragraph()
        run_titulo = p_titulo.add_run()
        run_titulo.text = titulo
        run_titulo.font.bold = True  
        run_titulo.font.italic = True  
        run_titulo.font.color.rgb = RGBColor(5, 80, 46)  
        
        # Adiciona a caixa de texto inferior
        x_text = Inches(0.2)
        y_text = Inches(4)
        cx_text = Inches(9)
        cy_text = Inches(1.3)
        caixa_inferior = slide.shapes.add_textbox(x_text, y_text, cx_text, cy_text)
        tf_inferior = caixa_inferior.text_frame
        tf_inferior.clear()

        # Remover o parágrafo padrão (vazio) se existir
        if len(tf_inferior.paragraphs) == 1 and not tf_inferior.paragraphs[0].text:
            tf_inferior._element.remove(tf_inferior.paragraphs[0]._element)

        # Formata o fundo da caixa de texto inferior
        fill = caixa_inferior.fill
        fill.solid()
        fill.fore_color.rgb = RGBColor(251, 229, 214)

        # Adiciona as informações sem o parágrafo vazio inicial
        informacoes = [
            "Programado: XXX mil ha.",
            "Meta semanal: XXX mil ha.",
            "Realizado última semana: XXX mil ha.",
            "Semana atual: XXX mil ha",
            "Percentual de realização: XX%",
            "Fechamento do Bloco: XX/XX/XXXX.", 
            "Última Semana: XXXXXXXXXXXXXXXXXXXXXX XXXX XXXXXXXXXXXX"   
        ]
        for item in informacoes:
            partes = item.split(":")
            if len(partes) > 1:
                p = tf_inferior.add_paragraph()
                p.level = 0  
                p.space_after = Pt(0)  # Remove espaçamento extra entre parágrafos
                run1 = p.add_run()
                run1.text = "✔ "
                run1.font.size = Pt(8)

                run2 = p.add_run()
                run2.text = partes[0].strip() + ": "
                run2.font.size = Pt(10)

                run3 = p.add_run()
                run3.text = partes[1].strip()
                run3.font.size = Pt(10)
                run3.font.bold = True         
                
        if os.path.exists(arquivo_saida):
            print("Esse arquivo já existe, então vamos atualizá-lo!")
            os.remove(arquivo_saida)
            prs.save(arquivo_saida)
        else:
            prs.save(arquivo_saida)
            print(f"Arquivo PowerPoint atualizado salvo como: {arquivo_saida}")
        if os.path.exists(imagem_path):
            os.remove(imagem_path)
            print(f"Imagem '{imagem_path}' removida com sucesso após uso.")
    except Exception as e:
        print(f"Erro ao modificar o PowerPoint: {e}")

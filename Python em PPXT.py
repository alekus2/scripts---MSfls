for shape in slide.shapes:
    if shape.has_text_frame and shape.text_frame.text.strip() != "":
        shape.text_frame.paragraphs[0].text = titulo
        break
for shape in slide.shapes:
    if shape.has_text_frame:
        shape.text = titulo
        break
for item in ["Item 1", "Item 2", "Item 3"]:
    p = text_frame.add_paragraph()
    p.text = item
    p.space_after = Inches(0.1)  # Ajusta o espaçamento entre os itens
    p.level = 0  # Define o nível do marcador (0 = padrão)
caixa_texto_encontrada = None
for shape in slide.shapes:
    if shape.has_text_frame and shape.text.strip() != "":
        caixa_texto_encontrada = shape
        break

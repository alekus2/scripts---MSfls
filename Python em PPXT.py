text_frame = caixa_texto_encontrada.text_frame
text_frame.clear()  # Remove o texto existente

# Adiciona novos parágrafos com marcadores
for item in ["Item 1", "Item 2", "Item 3"]:
    p = text_frame.add_paragraph()
    p.text = item
    p.space_after = Inches(0.1)  # Ajusta o espaçamento entre os itens
    p.level = 0  # Define o nível do marcador (0 = padrão)
    p.font.size = Inches(0.3)  # Ajusta o tamanho da fonte (opcional)


caixa_texto_encontrada.fill.solid()  # Define o preenchimento sólido
caixa_texto_encontrada.fill.fore_color.rgb = RGBColor(255, 255, 0)  # Cor amarela

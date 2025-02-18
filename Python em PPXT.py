# CAIXA DE TEXTO SLIDE ABAIXO
x_text = Inches(0)
y_text = Inches(4)
cx_text = Inches(10)
cy_text = Inches(1.7)
nova_caixa_texto = slide.shapes.add_textbox(x_text, y_text, cx_text, cy_text)
text_frame2 = nova_caixa_texto.text_frame
text_frame2.text = "Resumo da Semana"

# FORMATAÇÃO DE CAIXA DE TEXTO SLIDE BAIXO
fill = nova_caixa_texto.fill
fill.solid()
fill.fore_color.rgb = RGBColor(251, 229, 214)

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
        p = text_frame2.add_paragraph()
        p.level = 0  
        run1 = p.add_run()
        run1.text = "✔ " + partes[0] + ": " 
        
        run2 = p.add_run()
        run2.text = partes[1].strip()
        run2.font.bold = True  
        
        # Altere o tamanho do texto aqui
        run2.font.size = Pt(12)  # Ajuste o tamanho conforme necessário

        # Se você quiser adicionar um terceiro run com um estilo específico
        run3 = p.add_run()
        run3.text = partes[1].strip()  # Se necessário, ajuste o texto aqui
        run3.font.size = Pt(10)  # Ajuste o tamanho conforme necessário
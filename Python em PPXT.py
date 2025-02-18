import pandas as pd
import matplotlib.pyplot as plt
from pptx import Presentation
from pptx.util import Inches
import numpy as np
import os
import sys
from pptx.dml.color import RGBColor

# --- Parte 1: Ler os dados do Excel ---
try:
    arquivo_excel = r'F:\Qualidade_Florestal\02- MATO GROSSO DO SUL\11- Administrativo Qualidade MS\00- Colaboradores\17 - Alex Vinicius\Pasta exemplos a serem usados\TesteExcel.xlsx'

    if not os.path.exists(arquivo_excel):
        raise FileNotFoundError(f"Erro: O arquivo '{arquivo_excel}' não foi encontrado no diretório atual.")

    df = pd.read_excel(arquivo_excel, sheet_name=2)

    colunas_esperadas = ['Semanas', 'Nome', 'Porcentagem SOF', 'Porcentagem VPD']
    for coluna in colunas_esperadas:
        if coluna not in df.columns:
            raise KeyError(f"Erro: A coluna esperada '{coluna}' não foi encontrada no arquivo Excel.")

    categorias = ['Semana ' + str(int(semana)) if isinstance(semana, (int, float)) else str(semana) for semana in df['Semanas']]

    nome = df['Nome'].fillna("Desconhecido").iloc[0]
    valores_sof = df['Porcentagem SOF'].fillna(0).values
    valores_vpd = df['Porcentagem VPD'].fillna(0).values

except Exception as e:
    print(f"Erro ao processar o Excel: {e}")
    sys.exit(1)

# --- Parte 2: Criar o gráfico ---
try:
    semanas = categorias
    quantidade_realizada = {'SOF': valores_sof, 'VPD': valores_vpd}

    fig, ax = plt.subplots(figsize=(12, 6))
    bottom = np.zeros(len(semanas))
    cores = ['#548235', '#A9D18E']

    for i, (quantidade, valores) in enumerate(quantidade_realizada.items()):
        bars = ax.bar(semanas, valores, width=0.6, label=quantidade, bottom=bottom, color=cores[i])
        bottom += valores
        for rect, valor in zip(bars, valores):
            if valor > 0:
                ax.text(rect.get_x() + rect.get_width() / 2, rect.get_y() + rect.get_height() / 2, f'{valor:.0f}%',
                        ha='center', va='center', fontsize=10, color='white')

    meta = 100
    ax.plot([-0.5, len(semanas) - 0.5], [meta, meta], color='darkgrey', linewidth=2, linestyle='--', label='Meta')

    ax.set_title(f'ACOMPANHAMENTO CICLO SOF - {nome}', fontsize=14)
    ax.set_ylim(0, 200)
    ax.legend()

    nome_arquivo = "".join(c for c in nome if c.isalnum() or c in "_-.").strip()
    nome_arquivo = nome_arquivo if nome_arquivo else "grafico"
    nome_arquivo += ".png"

    plt.xticks(rotation=30, ha='right')
    plt.savefig(nome_arquivo, format='png', dpi=300)
    plt.show()

except Exception as e:
    print(f"Erro ao gerar o gráfico: {e}")
    sys.exit(1)

# --- Parte 3: Inserir a imagem no PowerPoint ---


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
        
        for shape in reversed(slide.shapes):
            if shape.has_text_frame:
                slide.shapes._spTree.remove(shape._element)
        
        #IMAGEM GRAFICO
        
        x = Inches(0.5)
        y = Inches(0.5)
        cx = Inches(8)
        cy = Inches(3.4)
        slide.shapes.add_picture(imagem_path, x, y, cx, cy)
        
        #TITULO DO NO TOPO SLIDE

        x_text = Inches(0)
        y_text = Inches(0)
        cx_text = Inches(9)
        cy_text = Inches(0.5)
        caixa_texto = slide.shapes.add_textbox(x_text, y_text, cx_text, cy_text)
        text_frame = caixa_texto.text_frame
        text_frame.clear()  

        #FORMATAÇÃO TITULO SLIDE

        p_titulo = text_frame.add_paragraph()
        run_titulo = p_titulo.add_run()
        run_titulo.text = titulo
        run_titulo.font.bold = True  
        run_titulo.font.italic = True  
        run_titulo.font.color.rgb = RGBColor(5, 80, 46)  
        
        #CAIXA DE TEXTO SLIDE ABAIXO

        x_text = Inches(0)
        y_text = Inches(4)
        cx_text = Inches(10)
        cy_text = Inches(1.7)
        nova_caixa_texto = slide.shapes.add_textbox(x_text, y_text, cx_text, cy_text)
        text_frame2 = nova_caixa_texto.text_frame
        text_frame2.text = "Resumo da Semana"

        #FORMATAÇÃO DE CAIXA DE TEXTO SLIDE BAIXO

        fill = nova_caixa_texto.fill
        fill.solid()
        fill.fore_color.rgb = RGBColor(251, 229, 214)  

        informacoes = [
            "Programado: XXX mil ha."
            "Meta semanal: XXX mil ha."
            "Realizado última semana: XXX mil ha."
            "Semana atual: XXX mil ha"
            "Percentual de realização: XX%"
            "Fechamento do Bloco: XX/XX/XXXX." 
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
                run2.font.highlight_color = 3  

                run3 = p.add_run()
                run3.text = partes[0,1]
                run3.font.size = Pt(10)
        prs.save(arquivo_saida)
        print(f"Arquivo PowerPoint atualizado salvo como: {arquivo_saida}")

    except Exception as e:
        print(f"Erro ao modificar o PowerPoint: {e}")
arquivo_modelo = r'F:\Qualidade_Florestal\02- MATO GROSSO DO SUL\11- Administrativo Qualidade MS\00- Colaboradores\17 - Alex Vinicius\Pasta exemplos a serem usados\Acompanhamento semanal_04_edit.pptx'
slide_index = 2
arquivo_saida = "Acompanhamento semanal_04_atualizado.pptx"
imagem_grafico = nome_arquivo

adicionar_imagem_ao_slide(arquivo_modelo, slide_index, nome, imagem_grafico, arquivo_saida)

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
    arquivo_excel = 'TesteExcel.xlsx'
    
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

        # Caixa de texto para resumo
        x_text = Inches(0)
        y_text = Inches(3.8)
        cx_text = Inches(9.4)
        cy_text = Inches(1.6)
        caixa_texto2 = slide.shapes.add_textbox(x_text, y_text, cx_text, cy_text)
        text_frame2 = caixa_texto2.text_frame
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

            p.space_after = Inches(0.1)
            p.level = 0

        # Definir fundo amarelo para a caixa de texto
        fill = caixa_texto2.fill
        fill.solid()
        fill.fore_color.rgb = RGBColor(255, 255, 0)  # Amarelo
        prs.save(arquivo_saida)
        print(f"Arquivo PowerPoint atualizado salvo como: {arquivo_saida}")

    except Exception as e:
        print(f"Erro ao modificar o PowerPoint: {e}")


arquivo_modelo = "Acompanhamento semanal_04_edit.pptx"
slide_index = 2
arquivo_saida = "Acompanhamento semanal_04_atualizado.pptx"
imagem_grafico = nome_arquivo

adicionar_imagem_ao_slide(arquivo_modelo, slide_index, nome, imagem_grafico, arquivo_saida)

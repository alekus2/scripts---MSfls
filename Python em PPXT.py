import pandas as pd
import matplotlib.pyplot as plt
from pptx import Presentation
from pptx.util import Inches
import numpy as np
import os
import sys
from pptx.dml.color import RGBColor
from pptx.util import Pt

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

    categorias = [
        'Semana ' + str(int(semana)) if isinstance(semana, (int, float)) else str(semana)
        for semana in df['Semanas']
    ]

    nome = df['Nome'].fillna("Desconhecido").iloc[0]
    valores_sof = df['Porcentagem SOF'].fillna(0).values
    valores_vpd = df['Porcentagem VPD'].fillna(0).values

except Exception as e:
    print(f"Erro ao processar o Excel: {e}")
    sys.exit(1)

# --- Parte 2: Criar o gráfico para apresentação (ou apagar se ja existir) ---
try:
    categorias = [
        'Semana ' + str(int(semana)) if isinstance(semana, (int, float)) else str(semana)
        for semana in df['Semanas']
    ]
    valores_sof = df['Porcentagem SOF'].fillna(0).values
    valores_vpd = df['Porcentagem VPD'].fillna(0).values
    semanas = categorias
    quantidade_realizada = {'SOF': valores_sof, 'VPD': valores_vpd}

    data_sum = np.array(valores_sof) + np.array(valores_vpd)
    if np.any(data_sum > 0):
        last_data_idx = np.where(data_sum > 0)[0][-1]
    else:
        last_data_idx = len(semanas) - 1

    fig, ax = plt.subplots(figsize=(12, 6))
    bottom = np.zeros(len(semanas))

    bar_width = 0.3
    cores = ['#548235', '#A9D18E']

    for i, (quantidade, valores) in enumerate(quantidade_realizada.items()):
        bars = ax.bar(semanas, valores, width=bar_width, label=quantidade, bottom=bottom, color=cores[i])
        for rect, valor in zip(bars, valores):
            if valor > 0:
                ax.text(rect.get_x() + rect.get_width() / 2,
                        rect.get_y() + rect.get_height() / 2,
                        f'{valor:.0f}%',
                        ha='center', va='center', fontsize=10, color='white')
        bottom += valores

    meta = 100
    ax.plot([-0.5, last_data_idx + 0.5], [meta, meta],
            color='darkgrey', linewidth=2, linestyle='--', label='Meta')

    ax.set_title(f'ACOMPANHAMENTO CICLO SOF - {nome}', fontsize=14)
    ax.set_ylim(0, 200)

    ax.legend(loc='upper center', bbox_to_anchor=(0.5, -0.12), ncol=3)

    plt.xticks(rotation=0, ha='center')

    ax.tick_params(axis='y', labelleft=False)
    
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.spines['left'].set_visible(False)

    nome_arquivo = "".join(c for c in nome if c.isalnum() or c in "_-.").strip()
    nome_arquivo = nome_arquivo if nome_arquivo else "grafico"
    nome_arquivo += ".png"
    
    plt.show()

#     plt.savefig(nome_arquivo, format='png', dpi=300)

except Exception as e:
    print(f"Erro ao gerar o gráfico: {e}")
    sys.exit(1)


# # --- Parte 3: Criação do powerpoint e ajustado para formatação ideal ---

# def adicionar_imagem_ao_slide(arquivo_modelo, slide_index, titulo, imagem_path, arquivo_saida):
#     try:
#         if not os.path.exists(arquivo_modelo):
#             raise FileNotFoundError(f"Erro: O arquivo do PowerPoint '{arquivo_modelo}' não foi encontrado.")

#         if not os.path.exists(imagem_path):
#             raise FileNotFoundError(f"Erro: A imagem '{imagem_path}' não foi encontrada.")

#         prs = Presentation(arquivo_modelo)

#         if slide_index >= len(prs.slides):
#             raise IndexError(f"Erro: O slide de índice {slide_index} não existe na apresentação.")

#         slide = prs.slides[slide_index]
        
#         for shape in reversed(slide.shapes):
#             if shape.has_text_frame:
#                 slide.shapes._spTree.remove(shape._element)
        
#         # Adiciona a imagem do gráfico
#         x = Inches(0)
#         y = Inches(0.6)
#         cx = Inches(10)
#         cy = Inches(3.4)
#         slide.shapes.add_picture(imagem_path, x, y, cx, cy)
        
#         # Adiciona o título no topo do slide
#         x_text = Inches(0)
#         y_text = Inches(0)
#         cx_text = Inches(9)
#         cy_text = Inches(0.5)
#         caixa_titulo = slide.shapes.add_textbox(x_text, y_text, cx_text, cy_text)
#         tf_titulo = caixa_titulo.text_frame
#         tf_titulo.clear()  

#         p_titulo = tf_titulo.add_paragraph()
#         run_titulo = p_titulo.add_run()
#         run_titulo.text = titulo
#         run_titulo.font.bold = True  
#         run_titulo.font.italic = True  
#         run_titulo.font.color.rgb = RGBColor(5, 80, 46)  
        
#         # Adiciona a caixa de texto inferior
#         x_text = Inches(0.2)
#         y_text = Inches(4)
#         cx_text = Inches(9.5)
#         cy_text = Inches(1.3)
#         caixa_inferior = slide.shapes.add_textbox(x_text, y_text, cx_text, cy_text)
#         tf_inferior = caixa_inferior.text_frame
#         tf_inferior.clear()

#         if len(tf_inferior.paragraphs) == 1 and not tf_inferior.paragraphs[0].text:
#             tf_inferior._element.remove(tf_inferior.paragraphs[0]._element)

#         fill = caixa_inferior.fill
#         fill.solid()
#         fill.fore_color.rgb = RGBColor(251, 229, 214)

#         informacoes = [
#             "Programado: XXX mil ha.",
#             "Meta semanal: XXX mil ha.",
#             "Realizado última semana: XXX mil ha.",
#             "Semana atual: XXX mil ha",
#             "Percentual de realização: XX%",
#             "Fechamento do Bloco: XX/XX/XXXX.", 
#             "Última Semana: XXXXXXXXXXXXXXXXXXXXXX XXXX XXXXXXXXXXXX"   
#         ]
#         for item in informacoes:
#             partes = item.split(":")
#             if len(partes) > 1:
#                 p = tf_inferior.add_paragraph()
#                 p.level = 0  
#                 p.space_after = Pt(0)  
#                 run1 = p.add_run()
#                 run1.text = "✔ "
#                 run1.font.size = Pt(8)

#                 run2 = p.add_run()
#                 run2.text = partes[0].strip() + ": "
#                 run2.font.size = Pt(10)

#                 run3 = p.add_run()
#                 run3.text = partes[1].strip()
#                 run3.font.size = Pt(10)
#                 run3.font.bold = True         
                
#         if os.path.exists(arquivo_saida):
#             print("Esse arquivo já existe, então vamos atualizá-lo!")
#             os.remove(arquivo_saida)
#             prs.save(arquivo_saida)
#         else:
#             prs.save(arquivo_saida)
#             print(f"Arquivo PowerPoint atualizado salvo como: {arquivo_saida}")
#         if os.path.exists(imagem_path):
#             os.remove(imagem_path)
#             print(f"Imagem '{imagem_path}' removida com sucesso após uso.")
#     except Exception as e:
#         print(f"Erro ao modificar o PowerPoint: {e}")

# arquivo_modelo = r'F:\Qualidade_Florestal\02- MATO GROSSO DO SUL\11- Administrativo Qualidade MS\00- Colaboradores\17 - Alex Vinicius\Pasta exemplos a serem usados\Acompanhamento semanal_04_edit.pptx'
# slide_index = 2
# arquivo_saida = "Acompanhamento semanal_04_atualizado.pptx"
# imagem_grafico = nome_arquivo

# adicionar_imagem_ao_slide(arquivo_modelo, slide_index, nome, imagem_grafico, arquivo_saida)

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
    
    nome = df['Nome']
    valores_sof = df['Porcentagem SOF'].fillna(0).values  
    valores_vpd = df['Porcentagem VPD'].fillna(0).values  

    if not any(valores_sof) and not any(valores_vpd):
        valores_sof = np.zeros(len(categorias))
        valores_vpd = np.zeros(len(categorias))

except FileNotFoundError as e:
    print(e)
    sys.exit(1)
except KeyError as e:
    print(e)
    sys.exit(1)
except ValueError as e:
    print(f"Erro ao processar os dados do Excel: {e}")
    sys.exit(1)
except Exception as e:
    print(f"Erro inesperado ao ler o Excel: {e}")
    sys.exit(1)

# --- Parte 2: Criar o gráfico ---
try:
    semanas = categorias  
    quantidade_realizada = {'SOF': valores_sof, 'VPD': valores_vpd}
    
    width = 0.6  
    fig, ax = plt.subplots(figsize=(12, 6))  
    bottom = np.zeros(len(semanas))  
    cores = ['#548235', '#A9D18E']

    for i, (quantidade, valores) in enumerate(quantidade_realizada.items()):
        p = ax.bar(semanas, valores, width, label=quantidade, bottom=bottom, color=cores[i])
        bottom += valores
        for rect, valor in zip(p, valores):
            if valor > 0:
                ax.text(rect.get_x() + rect.get_width() / 2, rect.get_y() + rect.get_height() / 2, f'{valor:.0f}%', 
                        ha='center', va='center', fontsize=10, color='white')

    meta = 100
    indices_com_valores = np.where((valores_sof > 0) | (valores_vpd > 0))[0]

    if len(indices_com_valores) > 0:
        ultima_semana_idx = indices_com_valores[-1]  
        ax.plot([0, ultima_semana_idx + 0.5], [meta, meta], color='darkgrey', linewidth=2, linestyle='--', label='Meta')

    ax.set_title('ACOMPANHAMENTO CICLO SOF - Bloco 05 - Janeiro/Fevereiro', fontsize=14)
    ax.set_ylim(0, 200)  
    ax.set_yticks([])
    ax.legend()

    # Processamento do nome do arquivo
    if 'Nome' in df.columns and not df['Nome'].isnull().all():
        nome_arquivo = str(df['Nome'].iloc[0]).strip()  
        titulo_slide = nome_arquivo
        nome_arquivo = nome_arquivo.replace(" ", "_")  
        nome_arquivo = "".join(c for c in nome_arquivo if c.isalnum() or c in "_-.")  
        if nome_arquivo == "":
            nome_arquivo = "grafico"  
    else:
        nome_arquivo = "grafico"

    nome_arquivo += ".png"

    plt.savefig(nome_arquivo, format='png', dpi=300)
    plt.xticks(rotation=30, ha='right')
    plt.show()

except Exception as e:
    print(f"Erro ao gerar o gráfico: {e}")
    sys.exit(1)

# --- Parte 3: Inserir a imagem no slide do PowerPoint ---

def adicionar_imagem_ao_slide(arquivo_modelo, slide_index, titulo, imagem_path, arquivo_saida):
    try:
        if not os.path.exists(arquivo_modelo):
            raise FileNotFoundError(f"Erro: O arquivo do PowerPoint '{arquivo_modelo}' não foi encontrado.")

        prs = Presentation(arquivo_modelo)

        if slide_index >= len(prs.slides):
            raise IndexError(f"Erro: O slide de índice {slide_index} não existe na apresentação.")

        slide = prs.slides[slide_index]

        for shape in slide.shapes:
            if shape.has_text_frame:
                shape.text = titulo
                break
        x = Inches(0)
        y = Inches(0.5)
        cx = Inches(10)
        cy = Inches(3.434595)
        slide.shapes.add_picture(imagem_path, x, y, cx, cy)
        for shape in slide.shapes: 
          if shape.has_text_frame and shape.text_frame.text.strip() != "":    
              shape.text_frame.paragraphs[0].text = titulo 
              break
        for item in ["Item 1", "Item 2", "Item 3"]:
            p = text_frame.add_paragraph()
            p.text = item
            p.space_after = Inches(0.1)  # Ajusta o espaçamento entre os itens
            p.level = 0  # Define o nível do marcador (0 = padrão)
        caixa_texto_encontrada = None       
        
        prs.save(arquivo_saida)
        print(f"Arquivo PowerPoint atualizado salvo como: {arquivo_saida}")

    except FileNotFoundError as e:
            print(e)
    except PermissionError:
            print(f"Erro: O arquivo '{arquivo_saida}' está aberto. Feche o arquivo e tente novamente.")
    except IndexError as e:
            print(e)
    except Exception as e:
            print(f"Erro inesperado ao modificar o PowerPoint: {e}")

arquivo_modelo = "Acompanhamento semanal_04_edit.pptx"
slide_index = 2
arquivo_saida = "Acompanhamento semanal_04_atualizado.pptx"
imagem_grafico = nome_arquivo

adicionar_imagem_ao_slide(arquivo_modelo, slide_index, titulo_slide, imagem_grafico, arquivo_saida)

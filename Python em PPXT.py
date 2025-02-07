import pandas as pd
import matplotlib.pyplot as plt
from pptx import Presentation
from pptx.util import Inches
import numpy as np 

# --- Parte 1: Ler os dados do Excel ---

df = pd.read_excel('TesteExcel.xlsx',sheet_name=0)
print(df.head())

categorias = df['Semanas'].astype(str).tolist() 
valores = df{'Porcentagem SOF': valores}.to_dict()

# --- Parte 2: Criar o gráfico com Matplotlib usando os dados lidos ---

semanas = ('Semana 1', 'Semana 2', 'Semana 3', 'Semana 4')
quantidade_realizada = {
    'SOF': np.array([32, 31, 66, 44]),  
    'VPD': np.array([36, 42, 49, 48]),
}
width = 0.6 

fig, ax = plt.subplots()
bottom = np.zeros(len(semanas))  

# Cores das barras
cores = ['#548235', '#A9D18E'] 

for i, (quantidade, valores) in enumerate(quantidade_realizada.items()):
    p = ax.bar(semanas, valores, width, label=quantidade, bottom=bottom, color=cores[i])
    bottom += valores
    ax.bar_label(p, label_type='center',fmt='%.0f%%')

meta = 100
ax.axhline(meta, color='darkgrey', linewidth=2, linestyle='--', label='Meta')

ax.set_title('ACOMPANHAMENTO CICLO SOF - Bloco 05 - Janeiro/Fevereiro')
ax.set_ylim(0, 200) 
ax.set_yticks([])
ax.legend()
plt.show()

# --- Parte 1: Ler os dados do Excel ---

# df = pd.read_excel('TesteExcel.xlsx',sheet_name=0)
# print(df.head())

# categorias = df['Equipe'].astype(str).tolist() 
# valores = df['Realizados'].tolist()

# --- Parte 2: Criar o gráfico com Matplotlib usando os dados lidos ---
# fig, ax = plt.subplots()

# categorias=["1","2","3","4"]
# valores=[200,300,200,300]

# bars = ax.bar(categorias, valores, color='tab:green', label='Realizados', width=0.3)

# ax.axhline(300, color='blue', linestyle='--', linewidth=2.5, label='Meta')

# x_positions = [bar.get_x() + bar.get_width()/2 for bar in bars]
# ax.scatter(x_positions, [300] * len(categorias), color='lightblue', s=100, zorder=5)

# ax.set_title('Acompanhamento Semanal - LEBATEC')
# ax.legend(title='Legenda')

# imagem_grafico = "grafico.png"
# fig.savefig(imagem_grafico, bbox_inches="tight")
# plt.show()


import numpy as np
import matplotlib.pyplot as plt

semanas = ('Semana 1', 'Semana 2', 'Semana 3', 'Semana 4')
quantidade_realizada = {
    'Male': np.array([73, 34, 61, 45]),  # Adicionando um valor para a quarta semana
    'Female': np.array([73, 34, 58, 50]),  # Adicionando um valor para a quarta semana
}
width = 0.6 

fig, ax = plt.subplots()
bottom = np.zeros(len(semanas))  # Alterado para corresponder ao número de semanas

# Cores das barras
cores = ['#006400', '#90EE90']  # Verde escuro e verde claro

for i, (quantidade, valores) in enumerate(quantidade_realizada.items()):
    p = ax.bar(semanas, valores, width, label=quantidade, bottom=bottom, color=cores[i])
    bottom += valores
    ax.bar_label(p, label_type='center')

# Adicionando linha de meta
meta = 40
ax.axhline(meta, color='darkgrey', linewidth=2, linestyle='--', label='Meta de 40%')

ax.set_title('ACOMPANHAMENTO CICLO SOF - Bloco 05 - Janeiro/Fevereiro')
ax.set_ylim(0, 100)  # Definindo limites do eixo Y
ax.legend()

plt.ylabel('Porcentagem (%)')  # Adicionando rótulo ao eixo Y
plt.show()


ValueError                                Traceback (most recent call last)
<ipython-input-10-1fc3322eb9a3> in <cell line: 0>()
     47 
     48 for i, (quantidade, valores) in enumerate(quantidade_realizada.items()):
---> 49     p = ax.bar(semanas, valores, width, label=quantidade, bottom=bottom, color=cores[i])
     50     bottom += valores
     51     ax.bar_label(p, label_type='center')

3 frames
/usr/local/lib/python3.11/dist-packages/numpy/lib/stride_tricks.py in _broadcast_shape(*args)
    420     # use the old-iterator because np.nditer does not handle size 0 arrays
    421     # consistently
--> 422     b = np.broadcast(*args[:32])
    423     # unfortunately, it cannot handle 32 or more arguments directly
    424     for pos in range(32, len(args), 31):

ValueError: shape mismatch: objects cannot be broadcast to a single shape.  Mismatch is between arg 0 with shape (4,) and arg 1 with shape (3,).

# --- Parte 3: Inserir a imagem no slide do PowerPoint ---

# def adicionar_imagem_ao_slide(arquivo_modelo, slide_index, titulo, imagem_path, arquivo_saida):
#     prs = Presentation(arquivo_modelo)
#     slide = prs.slides[slide_index]
#     for shape in slide.shapes:
#         if shape.has_text_frame:
#             shape.text = titulo
#             break
#     x = Inches(2)
#     y = Inches(1.5)
#     cx = Inches(5)
#     cy = Inches(3)
#     slide.shapes.add_picture(imagem_path, x, y, cx, cy)
#     prs.save(arquivo_saida)

# arquivo_modelo = "Modelo_ppt_Inventario_edit.pptx" 
# slide_index = 3 
# titulo_slide = "Modelo de acompanhamento."
# arquivo_saida = "modelo_editado.pptx"

# adicionar_imagem_ao_slide(arquivo_modelo, slide_index, titulo_slide, imagem_grafico, arquivo_saida)

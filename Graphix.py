from tkinter import *
from tkinter import ttk
from plotly.subplots import make_subplots
import plotly.graph_objects as go

def criar_grafico():
    x = xis.get().strip()
    y = ipislon.get().strip()
    x_values = x.split(',') 
    try:
        y_values = [float(i) for i in y.split(',')]  
    except ValueError:
        resultado_label.config(text="Erro: Certifique-se de inserir números válidos para Y.", foreground='red')
        return
    if len(x_values) != len(y_values):
        resultado_label.config(text="Erro: O número de elementos em X e Y deve ser igual.", foreground='red')
        return

    fig = make_subplots(rows=1, cols=2)

    fig.add_trace(go.Bar(x=x_values, y=y_values), row=1, col=1)

    fig.add_trace(go.Scatter(x=x_values, y=y_values), row=1, col=2)


    fig.show()


def sair():
    root.quit()
root = Tk()
root.title("Graphix")
root.geometry("700x650")  

frm = Frame(root, padx=0, pady=100, background="#66B2FF", width=350, height=700)
frm.grid(row=1, column=0, sticky=(N, S, E, W))

frm_img =Frame(root,padx=100,pady=7,background="#ffffff",width=100,height=150)
frm_img.grid(row=0, column=0,sticky=(W))

imagem = PhotoImage(file="logo.png")
label_imagem = Label(frm_img, image=imagem, background="#ffffff")
label_imagem.grid (row=1,column=0)

label_msg = ttk.Label(frm, text="Do gráfico ao entendimento: crie com facilidade 😉",
                      font=("Book Antiqua", 16),
                      background="#66B2FF",
                      foreground='#404040')
label_msg.place(x=120,y=50) 

label_msg2 = ttk.Label(frm, text="Graphix", 
                       font=("Ravie", 25), 
                       background="#66B2FF", 
                       foreground='#404040')
label_msg2.place(x=245,y=0)  

label_msg3 = ttk.Label(frm, text="Insira os dados do grafico que desejas fazer com virgulas: \n Ex: 1,2,3,4,5,6,7,8,9 ou janeiro,fevereiro,março...etc",
                       font=("Arial", 12), 
                       background="#66B2FF", 
                       foreground='#404040')
label_msg3.place(x=160,y=100) 

label_msg4 = ttk.Label(frm, text="Insira os dados do grafico de cada coluna com virgulas: \n Ex: 1,2,3,4,5,6,7,8,9",
                       font=("Arial", 12), 
                       background="#66B2FF", 
                       foreground='#404040')
label_msg4.place(x=160,y=200)  # Ajuste as coordenadas conforme necessário


xis = Entry(frm, font=("Arial", 10))
xis.place(x=190, y=160,width=300,height=20)

ipislon = Entry(frm, font=("Arial", 10))
ipislon.place(x=190, y=260,width=300,height=20)

# Resultado da validação
resultado_label = ttk.Label(frm, text="",
                            font=("Agrandir", 16), 
                            background="#66B2FF", 
                            foreground='#404040')
resultado_label.place(x=220,y=450)

resultado_label2 = ttk.Label(frm, text="", 
                             font=("Agrandir", 16), 
                             background="#66B2FF", 
                             foreground='#404040')
resultado_label2.place(x=130,y=400)

# Botão apagar
botao_apagar = ttk.Button(frm, text="Cancelar",command=sair)
botao_apagar.place(x=380, y=290)

# Botão salvar
botao_salvar = ttk.Button(frm, text="Salvar",command=criar_grafico)
botao_salvar.place(x=225, y=290)

# Inicia o loop principal da interface gráfica
root.mainloop()
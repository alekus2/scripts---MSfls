# app.py
import dash
from dash import dcc, html, Output, Input, State
import dash_bootstrap_components as dbc
import pandas as pd
import geopandas as gpd
import plotly.express as px
import base64, io, zipfile, os

# Importa funções auxiliares definidas no módulo utils.py
import utils

# Inicializa a aplicação com o tema Sandstone (similar ao shinytheme("sandstone"))
app = dash.Dash(__name__, external_stylesheets=[dbc.themes.SANDSTONE])
server = app.server  # para deploy, se necessário

# Layout da aplicação com abas
app.layout = dbc.Container([
    dbc.Row([
        dbc.Col(html.Img(src='/assets/logo.png', id='logo', 
                         style={'position': 'absolute', 'top': '10px', 'right': '10px', 'width': '100px'}))
    ]),
    dcc.Tabs(id='tabs', value='sobre', children=[
        dcc.Tab(label='Sobre', value='sobre', children=[
            html.Div([
                html.H2("Sobre"),
                html.P("Ferramenta desenvolvida em Dash (Python) para o lançamento de parcelas semi-aleatórias, que integra informações de recomendação, shapefile dos talhões e parcelas históricas. Essa aplicação permite aos usuários realizar o lançamento de parcelas de maneira automática e depois exportar o shapefile das parcelas."),
                html.Br(),
                html.B("O aplicativo foi meticulosamente desenvolvido para atuar como um instrumento de otimização do processo de lançamento, atuando como um facilitador. No entanto, é importante ressaltar que sua utilização não elimina a necessidade de análises e verificações criteriosas!", style={'color': 'red'})
            ], className='sobre-texto')
        ]),
        dcc.Tab(label='Dados', value='dados', children=[
            dbc.Row([
                dbc.Col([
                    html.H3("Upload do Shapefile dos talhões"),
                    dcc.Upload(
                        id='upload-shape',
                        children=html.Div(['Arraste ou clique para selecionar um arquivo .zip']),
                        multiple=False,
                        accept='.zip'
                    ),
                    html.Br(),
                    html.H3("Formato do shape de entrada"),
                    dcc.RadioItems(
                        id='shape-format',
                        options=[
                            {'label': 'ARUDEK.VW_GIS_POL_USO_SOLO', 'value': 'arudek'},
                            {'label': 'Outro', 'value': 'outro'}
                        ],
                        value='arudek'
                    ),
                    html.Div(id='custom-shape-fields', children=[
                        html.H3("Insira os nomes presentes no seu arquivo:"),
                        html.P("O nome deve ser exatamente igual à tabela de atributos."),
                        dbc.Input(id='proj-field', placeholder='Projeto (ex: ID_PROJETO)', value='ID_PROJETO', type='text'),
                        dbc.Input(id='talhao-field', placeholder='Talhão (ex: CD_TALHAO)', value='CD_TALHAO', type='text'),
                        dbc.Input(id='ciclo-field', placeholder='Ciclo (ex: NUM_CICLO)', value='NUM_CICLO', type='text'),
                        dbc.Input(id='rotacao-field', placeholder='Rotação (ex: NUM_ROTAC)', value='NUM_ROTAC', type='text')
                    ], style={'display': 'none'}),
                    html.Br(),
                    html.H3("Deseja realizar o upload do arquivo de recomendação?"),
                    dcc.RadioItems(
                        id='upload-recomend',
                        options=[
                            {'label': 'Sim', 'value': 'sim'},
                            {'label': 'Não', 'value': 'nao'}
                        ],
                        value='sim'
                    ),
                    html.Div(id='recomend-upload-div', children=[
                        dcc.Upload(
                            id='upload-recomend-file',
                            children=html.Div(['Arraste ou clique para selecionar um arquivo .csv']),
                            multiple=False,
                            accept='.csv'
                        )
                    ]),
                    html.Div(id='recomend-intensidade-div', children=[
                        html.H3("Informe a intensidade desejada para as parcelas"),
                        html.P("Nota: Informar a quantos hectares será necessária cada parcela alocada."),
                        dbc.Input(id='recomend-intensidade', type='number', value=3)
                    ], style={'display': 'none'}),
                    html.Br(),
                    html.H3("Deseja informar as parcelas já existentes?"),
                    dcc.RadioItems(
                        id='parcelas-existentes',
                        options=[
                            {'label': 'Sim', 'value': 'sim'},
                            {'label': 'Não', 'value': 'nao'}
                        ],
                        value='nao'
                    ),
                    html.Div(id='upload-parc-exist-div', children=[
                        dcc.Upload(
                            id='upload-parc-exist',
                            children=html.Div(['Arraste ou clique para selecionar um arquivo .zip']),
                            multiple=False,
                            accept='.zip'
                        )
                    ], style={'display': 'none'}),
                    html.Br(),
                    html.H3("Forma Parcela:"),
                    dcc.Dropdown(
                        id='forma-parcela',
                        options=[
                            {'label': 'CIRCULAR', 'value': 'CIRCULAR'},
                            {'label': 'RETANGULAR', 'value': 'RETANGULAR'}
                        ],
                        value='CIRCULAR'
                    ),
                    html.Br(),
                    html.H3("Tipo da Parcela:"),
                    dcc.Dropdown(
                        id='tipo-parcela',
                        options=[
                            {'label': 'S30', 'value': 'S30'},
                            {'label': 'S90', 'value': 'S90'},
                            {'label': 'IFQ6', 'value': 'IFQ6'},
                            {'label': 'IFQ12', 'value': 'IFQ12'},
                            {'label': 'IFC', 'value': 'IFC'},
                            {'label': 'IPC', 'value': 'IPC'}
                        ],
                        value='S30'
                    ),
                    html.Div(id='lancar-sobrevivencia-div', children=[
                        html.H3("Deseja lançar as parcelas de sobrevivência?"),
                        dcc.RadioItems(
                            id='lancar-sobrevivencia',
                            options=[
                                {'label': 'Sim', 'value': 'sim'},
                                {'label': 'Não', 'value': 'nao'}
                            ],
                            value='nao'
                        )
                    ], style={'display': 'none'}),
                    html.Br(),
                    html.H3("Distância Mínima"),
                    dcc.Slider(
                        id='distancia-minima',
                        min=5,
                        max=25,
                        step=0.5,
                        value=20,
                        marks={i: str(i) for i in range(5, 26, 5)}
                    ),
                    html.Br(),
                    dbc.Button("Confirmar", id='confirmar', color='primary')
                ], md=4),
                dbc.Col([
                    html.Div(id='shape-text'),
                    html.Br(),
                    html.Div(id='recomend-text'),
                    html.Br(),
                    html.Div(id='parc-exist-text'),
                    html.Br(),
                    html.Div(id='confirmation-text'),
                    html.Br(),
                    html.Div(id='download-recomend-div', children=[
                        dbc.Input(id='download-recomend-name', placeholder='Nome do arquivo de recomendação', value='Recomendação-'),
                        html.Br(),
                        dbc.Button("Download da Recomendação criada*", id='download-recomend', color='success')
                    ], style={'display': 'none'})
                ], md=8)
            ])
        ]),
        dcc.Tab(label='Resultados', value='resultados', children=[
            dcc.Tabs(id='result-tabs', value='status', children=[
                dcc.Tab(label='Status', value='status', children=[
                    dbc.Row([
                        dbc.Col([
                            html.H2("Gerar parcelas"),
                            html.P("Pressione o botão para gerar as parcelas. Dependendo da quantidade de talhões e parcelas recomendadas, o processo pode levar alguns minutos."),
                            dbc.Button("Gerar Parcelas", id='gerar-parcelas', color='primary')
                        ], md=4),
                        dbc.Col([
                            dbc.Progress(id='progress-bar', value=0, striped=True, animated=True),
                            html.Div(id='completed-message', children="Concluído", style={'display': 'none', 'fontWeight': 'bold', 'color': 'green'})
                        ], md=8)
                    ])
                ]),
                dcc.Tab(label='Parcelas Plotadas', value='plot', children=[
                    dbc.Row([
                        dbc.Col([
                            dcc.Dropdown(id='index-filter', placeholder="Select Index"),
                            html.Br(),
                            dbc.Button("Anterior", id='anterior', color='secondary'),
                            dbc.Button("Próximo", id='proximo', color='secondary'),
                            html.Br(), html.P("Para recalcular a distribuição do talhão:"),
                            dbc.Button("Gerar novamente as parcelas", id='gerar-novamente', color='warning')
                        ], md=4),
                        dbc.Col([
                            dcc.Graph(id='plot'),
                            html.Br(),
                            html.B("O número de parcelas alocadas pode diferir do número recomendado, em virtude das premissas adotadas. Nesses casos, avalie a plotagem e checagem manuais dentro do ArcGis Pro!", style={'color': 'red'})
                        ], md=8)
                    ])
                ]),
                dcc.Tab(label='Download', value='download', children=[
                    dbc.Row([
                        dbc.Col([
                            html.H2("Download"),
                            html.P("Arquivo gerado com base nas especificações."),
                            dbc.Input(id='download-name', placeholder='Nome do arquivo para download', value='Parcelas_2023-04-20'),
                            html.P("Nota: é necessário alterar o nome para cada arquivo a ser salvo.")
                        ], md=4),
                        dbc.Col([
                            dbc.Button("Download Parcelas", id='download-result', color='success')
                        ], md=8)
                    ])
                ])
            ])
        ])
    ])
], fluid=True)

# CALLBACKS PARA INTERATIVIDADE

# Exibe ou oculta os campos customizados para shape quando o formato é "Outro"
@app.callback(
    Output('custom-shape-fields', 'style'),
    Input('shape-format', 'value')
)
def toggle_custom_shape_fields(value):
    if value == 'outro':
        return {'display': 'block'}
    return {'display': 'none'}

# Exibe ou oculta os campos de upload ou intensidade da recomendação
@app.callback(
    Output('recomend-upload-div', 'style'),
    Output('recomend-intensidade-div', 'style'),
    Input('upload-recomend', 'value')
)
def toggle_recomend_fields(value):
    if value == 'sim':
        return {'display': 'block'}, {'display': 'none'}
    else:
        return {'display': 'none'}, {'display': 'block'}

# Exibe ou oculta o upload das parcelas existentes
@app.callback(
    Output('upload-parc-exist-div', 'style'),
    Input('parcelas-existentes', 'value')
)
def toggle_parc_exist_fields(value):
    if value == 'sim':
        return {'display': 'block'}
    return {'display': 'none'}

# Exibe ou oculta a opção de lançar sobrevivência quando o tipo de parcela é IPC
@app.callback(
    Output('lancar-sobrevivencia-div', 'style'),
    Input('tipo-parcela', 'value')
)
def toggle_sobrevivencia(value):
    if value == 'IPC':
        return {'display': 'block'}
    return {'display': 'none'}

# Processa os uploads e atualiza os textos de confirmação quando o botão "Confirmar" é clicado
@app.callback(
    Output('shape-text', 'children'),
    Output('recomend-text', 'children'),
    Output('parc-exist-text', 'children'),
    Output('confirmation-text', 'children'),
    Output('download-recomend-div', 'style'),
    Input('confirmar', 'n_clicks'),
    State('upload-shape', 'contents'),
    State('upload-shape', 'filename'),
    State('upload-recomend-file', 'contents'),
    State('upload-recomend-file', 'filename'),
    State('parcelas-existentes', 'value'),
    State('upload-parc-exist', 'contents'),
    State('upload-parc-exist', 'filename'),
    State('forma-parcela', 'value'),
    State('tipo-parcela', 'value'),
    State('distancia-minima', 'value')
)
def process_confirm(n_clicks, shape_contents, shape_filename, recomend_contents, recomend_filename,
                    parcelas_exist, parc_exist_contents, parc_exist_filename, forma_parcela, tipo_parcela, distancia_minima):
    if not n_clicks:
        return "", "", "", "", {'display': 'none'}
    
    shape_msg = f"Upload realizado referente aos talhões: {shape_filename}" if shape_filename else ""
    recomend_msg = f"Upload realizado referente à recomendação de parcelas: {recomend_filename}" if recomend_filename else ""
    parc_exist_msg = f"Upload realizado referente às parcelas já existentes: {parc_exist_filename}" if parcelas_exist == 'sim' and parc_exist_filename else "Upload de parcelas existentes não realizado."
    confirmation_msg = f"Forma Parcela: {forma_parcela}, Tipo Parcela: {tipo_parcela}, Distância Mínima: {distancia_minima}"
    
    # Exibe o botão de download de recomendação apenas se nenhum arquivo de recomendação foi enviado
    download_style = {'display': 'block'} if recomend_filename is None else {'display': 'none'}
    
    return shape_msg, recomend_msg, parc_exist_msg, confirmation_msg, download_style

# CALLBACK SIMULADO PARA GERAR PARCELAS (chama a função process_data do utils.py)
@app.callback(
    Output('progress-bar', 'value'),
    Output('completed-message', 'style'),
    Input('gerar-parcelas', 'n_clicks'),
    State('upload-shape', 'contents'),
    State('upload-recomend-file', 'contents'),
    State('upload-parc-exist', 'contents'),
    State('forma-parcela', 'value'),
    State('tipo-parcela', 'value'),
    State('distancia-minima', 'value')
)
def gerar_parcelas(n_clicks, shape_contents, recomend_contents, parc_exist_contents, forma_parcela, tipo_parcela, distancia_minima):
    if not n_clicks:
        return 0, {'display': 'none'}
    # Aqui você faria a extração dos arquivos (zip/csv), chamaria utils.process_data e atualizaria o progresso.
    # Nesta implementação de exemplo, simulamos o processo.
    progress = 100  # Simula que o processo chegou a 100%
    completed_style = {'display': 'block', 'fontWeight': 'bold', 'color': 'green'}
    return progress, completed_style

# CALLBACK PARA ATUALIZAR O GRÁFICO (exemplo simplificado)
@app.callback(
    Output('plot', 'figure'),
    Input('index-filter', 'value'),
    State('upload-shape', 'contents'),
    State('upload-recomend-file', 'contents')
)
def update_plot(selected_index, shape_contents, recomend_contents):
    # Nesta função, você extrairia os dados relevantes (por exemplo, do shapefile e recomendação) e filtraria pelo índice selecionado.
    # Aqui, usamos um exemplo dummy.
    df = pd.DataFrame({
        'x': [1, 2, 3],
        'y': [4, 5, 6]
    })
    fig = px.scatter(df, x='x', y='y', title="Parcelas Plotadas")
    return fig

# CALLBACK PARA ATUALIZAR O DROPDOWN DOS ÍNDICES (exemplo dummy)
@app.callback(
    Output('index-filter', 'options'),
    Input('upload-recomend-file', 'contents')
)
def update_index_filter(recomend_contents):
    # Em uma implementação real, extraia os índices do arquivo de recomendação.
    options = [{'label': f"Index {i}", 'value': f"Index{i}"} for i in range(1, 4)]
    return options

if __name__ == '__main__':
    app.run_server(debug=True)

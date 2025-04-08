# utils.py
import geopandas as gpd
import pandas as pd
import numpy as np
from shapely.geometry import Point, Polygon

def split_subgeometries(gdf):
    """
    Recebe um GeoDataFrame e separa as subgeometrias (explodindo geometrias multi-partes em partes individuais).
    """
    return gdf.explode(index_parts=False)

def process_data(shape_gdf, recomend_df, parc_exist_path, forma_parcela, tipo_parcela, distancia_minima, update_progress_callback=None):
    """
    Processa os dados: aplica recomendações, integra shapefile dos talhões e parcelas existentes,
    e gera os pontos das parcelas.
    
    Parâmetros:
      - shape_gdf: GeoDataFrame dos talhões.
      - recomend_df: DataFrame com as recomendações.
      - parc_exist_path: Caminho do shapefile das parcelas existentes (ou um caminho padrão).
      - forma_parcela, tipo_parcela, distancia_minima: parâmetros para processamento.
      - update_progress_callback: função callback para atualizar o progresso (em %).
    
    Retorna:
      - GeoDataFrame com os pontos resultantes (exemplo dummy neste caso).
    """
    # Exemplo dummy: cria um GeoDataFrame com três pontos
    data = {
        'Area': [1000, 1200, 800],
        'Index': ['Index1', 'Index1', 'Index2'],
        'PROJETO': ['0001', '0001', '0002'],
        'TALHAO': ['001', '001', '002'],
        'CICLO': [1, 1, 1],
        'ROTACAO': [1, 1, 1],
        'STATUS': ['ATIVA', 'ATIVA', 'ATIVA'],
        'FORMA': [forma_parcela]*3,
        'TIPO_INSTA': [tipo_parcela]*3,
        'TIPO_ATUAL': [tipo_parcela]*3,
        'DATA': ['2023-04-20']*3,
        'DATA_ATUAL': ['2023-04-20']*3,
        'COORD_X': [10, 20, 30],
        'COORD_Y': [10, 20, 30],
        'geometry': [Point(10,10), Point(20,20), Point(30,30)]
    }
    result_gdf = gpd.GeoDataFrame(data, crs="EPSG:4326")
    if update_progress_callback:
        update_progress_callback(100)
    return result_gdf

def create_points2(points_list, num_parc, min_dist):
    """
    Seleciona e retorna um conjunto de pontos válidos a partir de uma lista de GeoDataFrames de pontos.
    A função tenta atender a restrições de distância mínima e área mínima (exemplo adaptado da lógica R).
    
    Parâmetros:
      - points_list: lista de GeoDataFrames (cada um contendo pontos com coluna 'Area' e 'geometry').
      - num_parc: número de parcelas desejadas.
      - min_dist: distância mínima requerida entre pontos.
    
    Retorna:
      - GeoDataFrame com os pontos selecionados.
    """
    # Remove elementos nulos
    points_list = [pf for pf in points_list if pf is not None]
    if not points_list:
        return None
    # Combina todos os GeoDataFrames
    points2 = pd.concat(points_list, ignore_index=True)
    
    # Exemplo de verificação: se a área total for suficiente e existir pelo menos um ponto com área > 800
    enough_area = (points2['Area'].sum() >= 800) and (points2['Area'] > 800).any()
    
    # Se houver pontos com área suficiente e a distância entre eles for menor que min_dist, seleciona uma amostra
    if enough_area and len(points2) >= num_parc:
        # Neste exemplo, usamos uma ordenação simples pela área e selecionamos os primeiros num_parc pontos
        points2 = points2.sort_values(by='Area', ascending=False).head(num_parc)
    
    # Seleciona apenas as colunas desejadas
    columns = ["Area", "Index", "PROJETO", "TALHAO", "CICLO", "ROTACAO", "STATUS", 
               "FORMA", "TIPO_INSTA", "TIPO_ATUAL", "DATA", "DATA_ATUAL", "COORD_X",
               "COORD_Y", "geometry"]
    return points2[columns]

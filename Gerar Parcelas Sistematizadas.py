from qgis.core import (
    QgsProcessingAlgorithm,
    QgsProcessingParameterFeatureSource,
    QgsProcessingParameterField,
    QgsProcessingParameterNumber,
    QgsProcessingParameterFeatureSink,
    QgsFeature,
    QgsPointXY,
    QgsGeometry,
    QgsProcessing,
    QgsWkbTypes,
    QgsFeatureSink,
    QgsFields,
    QgsField,
    QgsCoordinateReferenceSystem,
    QgsCoordinateTransform,
    QgsProject,
    QgsRectangle
)
from PyQt5.QtCore import QVariant
import math

class GeneratePointsAlgorithm(QgsProcessingAlgorithm):
    INPUT = 'INPUT'
    NUM_POINTS_FIELD = 'NUM_POINTS_FIELD'
    TALHAO_FIELD = 'TALHAO_FIELD'  # Novo campo para Talhao
    BUFFER_INITIAL = 'BUFFER_INITIAL'
    BUFFER_FINAL = 'BUFFER_FINAL'
    AREA = 'AREA'
    MIN_GRID_DISTANCE = 'MIN_GRID_DISTANCE'
    OUTPUT_POINTS = 'OUTPUT_POINTS'
    OUTPUT_POLYGONS = 'OUTPUT_POLYGONS'
    OUTPUT_GRID1 = 'OUTPUT_GRID1'
    OUTPUT_GRID2 = 'OUTPUT_GRID2'

    def initAlgorithm(self, config=None):
        self.addParameter(
            QgsProcessingParameterFeatureSource(
                self.INPUT,
                'Input talhões',
                [QgsProcessing.TypeVectorPolygon]
            )
        )

        self.addParameter(
            QgsProcessingParameterField(
                self.NUM_POINTS_FIELD,
                'Número de parcelas',
                parentLayerParameterName=self.INPUT,
                type=QgsProcessingParameterField.Numeric
            )
        )

        # Adiciona o novo parâmetro opcional "Talhao"
        self.addParameter(
            QgsProcessingParameterField(
                self.TALHAO_FIELD,
                'Nome do talhão',
                parentLayerParameterName=self.INPUT,
                type=QgsProcessingParameterField.String,
                optional=True  # Torna o campo opcional
            )
        )

        self.addParameter(
            QgsProcessingParameterNumber(
                self.BUFFER_INITIAL,
                'Bordadura inicial (m)',
                type=QgsProcessingParameterNumber.Double,
                defaultValue=25.0
            )
        )

        self.addParameter(
            QgsProcessingParameterNumber(
                self.BUFFER_FINAL,
                'Bordadura final (m)',
                type=QgsProcessingParameterNumber.Double,
                defaultValue=25.0
            )
        )

        self.addParameter(
            QgsProcessingParameterNumber(
                self.AREA,
                'Área da parcela (m²)',
                type=QgsProcessingParameterNumber.Double,
                defaultValue=400.0
            )
        )

        self.addParameter(
            QgsProcessingParameterNumber(
                self.MIN_GRID_DISTANCE,
                'Distância mínima da grade (m)',
                type=QgsProcessingParameterNumber.Double,
                defaultValue=150.0
            )
        )

        self.addParameter(
            QgsProcessingParameterFeatureSink(
                self.OUTPUT_POINTS,
                'Output centro da parcela'
            )
        )

        self.addParameter(
            QgsProcessingParameterFeatureSink(
                self.OUTPUT_POLYGONS,
                'Output parcelas'
            )
        )

        self.addParameter(
            QgsProcessingParameterFeatureSink(
                self.OUTPUT_GRID1,
                'Output Grade 1 (Original)'
            )
        )

        self.addParameter(
            QgsProcessingParameterFeatureSink(
                self.OUTPUT_GRID2,
                'Output Grade 2 (Original + Paralela)'
            )
        )

    def generate_grid(self, geom, spacing, angle):
        bbox = geom.boundingBox()
        center = bbox.center()
        width = bbox.width()
        height = bbox.height()

        enlarged_bbox = QgsRectangle(
            center.x() - 2.5 * width,
            center.y() - 2.5 * height,
            center.x() + 2.5 * width,
            center.y() + 2.5 * height
        )

        xmin, ymin, xmax, ymax = (
            enlarged_bbox.xMinimum(),
            enlarged_bbox.yMinimum(),
            enlarged_bbox.xMaximum(),
            enlarged_bbox.yMaximum()
        )

        angle_rad = math.radians(angle)
        cos_angle = math.cos(angle_rad)
        sin_angle = math.sin(angle_rad)

        def rotate_point(x, y, cx, cy):
            x_new = cx + cos_angle * (x - cx) - sin_angle * (y - cy)
            y_new = cy + sin_angle * (x - cx) + cos_angle * (y - cy)
            return x_new, y_new

        cx, cy = (xmin + xmax) / 2, (ymin + ymax) / 2

        grid_lines = []
        intersections = []

        # Linhas horizontais
        y = ymin
        while y <= ymax:
            start_x, start_y = rotate_point(xmin, y, cx, cy)
            end_x, end_y = rotate_point(xmax, y, cx, cy)
            line = QgsGeometry.fromPolylineXY([
                QgsPointXY(start_x, start_y),
                QgsPointXY(end_x, end_y)
            ])
            grid_lines.append(line)
            y += spacing

        # Linhas verticais
        x = xmin
        while x <= xmax:
            start_x, start_y = rotate_point(x, ymin, cx, cy)
            end_x, end_y = rotate_point(x, ymax, cx, cy)
            vertical_line = QgsGeometry.fromPolylineXY([
                QgsPointXY(start_x, start_y),
                QgsPointXY(end_x, end_y)
            ])
            grid_lines.append(vertical_line)

            # Calcula interseções com as linhas horizontais já adicionadas
            for horizontal_line in grid_lines[:-1]:
                intersection = vertical_line.intersection(horizontal_line)
                if intersection.type() == QgsWkbTypes.PointGeometry:
                    point = intersection.asPoint()
                    if geom.contains(intersection):
                        intersections.append(point)

            x += spacing

        return grid_lines, intersections

    def generate_parallel_grid(self, grid_lines, spacing):
        new_grid_lines = []
        for line in grid_lines:
            line_geom = line.asPolyline()
            if len(line_geom) >= 2:
                start_point = line_geom[0]
                end_point = line_geom[-1]
                dx = end_point.x() - start_point.x()
                dy = end_point.y() - start_point.y()
                length = math.sqrt(dx**2 + dy**2)
                if length > 0:
                    unit_perpendicular = QgsPointXY(-dy / length, dx / length)
                    offset = spacing / 2

                    new_start = QgsPointXY(
                        start_point.x() + offset * unit_perpendicular.x(),
                        start_point.y() + offset * unit_perpendicular.y()
                    )
                    new_end = QgsPointXY(
                        end_point.x() + offset * unit_perpendicular.x(),
                        end_point.y() + offset * unit_perpendicular.y()
                    )
                    new_line = QgsGeometry.fromPolylineXY([new_start, new_end])
                    new_grid_lines.append(new_line)

                    opposite_start = QgsPointXY(
                        start_point.x() - offset * unit_perpendicular.x(),
                        start_point.y() - offset * unit_perpendicular.y()
                    )
                    opposite_end = QgsPointXY(
                        end_point.x() - offset * unit_perpendicular.x(),
                        end_point.y() - offset * unit_perpendicular.y()
                    )
                    opposite_line = QgsGeometry.fromPolylineXY([opposite_start, opposite_end])
                    new_grid_lines.append(opposite_line)

        return new_grid_lines

    def get_boundary_line(self, geom):
        if geom.isMultipart():
            boundary_lines = []
            for part in geom.asMultiPolygon():
                exterior_ring = part[0]
                boundary_lines.append(QgsGeometry.fromPolylineXY(exterior_ring))
            return QgsGeometry.unaryUnion(boundary_lines)
        else:
            exterior_ring = geom.asPolygon()[0]
            return QgsGeometry.fromPolylineXY(exterior_ring)

    def processAlgorithm(self, parameters, context, feedback):
        # Obtenção das camadas de entrada e parâmetros
        source = self.parameterAsSource(parameters, self.INPUT, context)
        num_points_field = self.parameterAsFields(parameters, self.NUM_POINTS_FIELD, context)[0]

        # Obtenção do campo opcional "Talhao"
        talhao_field_list = self.parameterAsFields(parameters, self.TALHAO_FIELD, context)
        talhao_field = talhao_field_list[0] if talhao_field_list else None

        initial_buffer_distance = self.parameterAsDouble(parameters, self.BUFFER_INITIAL, context)
        final_buffer_distance = self.parameterAsDouble(parameters, self.BUFFER_FINAL, context)
        area = self.parameterAsDouble(parameters, self.AREA, context)
        min_grid_distance = self.parameterAsDouble(parameters, self.MIN_GRID_DISTANCE, context)

        # Cálculo do raio e diâmetro de cada parcela (circular)
        radius = math.sqrt(area / math.pi)
        diameter = 2 * radius

        # Distância mínima para evitar sobreposição das parcelas
        adjusted_min_distance = diameter

        # Transformações de coordenadas
        crs_src = source.sourceCrs()
        crs_dest = QgsCoordinateReferenceSystem("EPSG:4674")
        xform = QgsCoordinateTransform(crs_src, crs_dest, QgsProject.instance())

        # Campos para pontos e polígonos
        fields = QgsFields()
        fields.append(QgsField("ID", QVariant.Int))
        fields.append(QgsField("Nome", QVariant.String))  # "Nome" antes de "Talhao"
        # Adiciona o campo "Talhao" imediatamente após "Nome" se selecionado
        if talhao_field:
            fields.append(QgsField("Talhao", QVariant.String))
        fields.append(QgsField("X_UTM_LON", QVariant.Double, len=14, prec=3))
        fields.append(QgsField("Y_UTM_LAT", QVariant.Double, len=14, prec=3))
        fields.append(QgsField("X_GEO_LON", QVariant.String))
        fields.append(QgsField("Y_GEO_LAT", QVariant.String))
        fields.append(QgsField("X_DGEO_LON", QVariant.Double, len=10, prec=8))
        fields.append(QgsField("Y_DGEO_LAT", QVariant.Double, len=10, prec=8))
        fields.append(QgsField("Distancia", QVariant.Double, len=14, prec=2))  # Mover "Distancia" antes de "Borda"
        fields.append(QgsField("Borda", QVariant.Double, len=14, prec=2))
        fields.append(QgsField("Google_Map", QVariant.String, len=255))  # Mover "Google_Map" para o final

        (sink_points, points_dest_id) = self.parameterAsSink(
            parameters,
            self.OUTPUT_POINTS,
            context,
            fields,
            QgsWkbTypes.Point,
            source.sourceCrs()
        )

        (sink_polygons, polygons_dest_id) = self.parameterAsSink(
            parameters,
            self.OUTPUT_POLYGONS,
            context,
            fields,
            QgsWkbTypes.Polygon,
            source.sourceCrs()
        )

        # Campos para grade, com 2 colunas de espaçamento: inicial e usado
        grid_fields = QgsFields()
        grid_fields.append(QgsField("ID", QVariant.Int))
        # Adiciona o campo "Talhao" imediatamente após "ID" se selecionado
        if talhao_field:
            grid_fields.append(QgsField("Talhao", QVariant.String))
        grid_fields.append(QgsField("Espac_ini", QVariant.Double))
        grid_fields.append(QgsField("Espac_usado", QVariant.Double))
        grid_fields.append(QgsField("Angle", QVariant.Double))
        grid_fields.append(QgsField("Grade", QVariant.String))

        (sink_grid1, grid1_dest_id) = self.parameterAsSink(
            parameters,
            self.OUTPUT_GRID1,
            context,
            grid_fields,
            QgsWkbTypes.MultiLineString,
            source.sourceCrs()
        )

        (sink_grid2, grid2_dest_id) = self.parameterAsSink(
            parameters,
            self.OUTPUT_GRID2,
            context,
            grid_fields,
            QgsWkbTypes.MultiLineString,
            source.sourceCrs()
        )

        total = 100.0 / source.featureCount() if source.featureCount() else 0
        point_count = 0
        global_id = 1

        # Ordena para ir processando
        polygons_sorted = sorted(source.getFeatures(), key=lambda f: f.geometry().boundingBox().yMinimum())

        for current, feature in enumerate(polygons_sorted):
            if feedback.isCanceled():
                break

            geom = feature.geometry()
            num_points = max(1, round(feature[num_points_field]))

            if num_points <= 0:
                continue

            # Obtém o valor do "Talhao" se disponível
            talhao_value = feature[talhao_field] if talhao_field else None

            boundary_line = self.get_boundary_line(geom)
            success = False

            # Se bordadura inicial e final forem iguais, tenta apenas uma vez
            if initial_buffer_distance == final_buffer_distance:
                buffer_distance = initial_buffer_distance
                success = self.try_buffer_distance(
                    buffer_distance,
                    radius,
                    geom,
                    min_grid_distance,
                    adjusted_min_distance,
                    num_points,
                    boundary_line,
                    sink_points,
                    sink_polygons,
                    xform,
                    global_id,
                    diameter,
                    feedback,
                    talhao_value  # Passa o valor do talhão
                )
                if success:
                    global_id += num_points
                    point_count += num_points
            else:
                # Caso contrário, vai diminuindo de 1 em 1
                buffer_distance = initial_buffer_distance
                while not success and buffer_distance >= final_buffer_distance:
                    success = self.try_buffer_distance(
                        buffer_distance,
                        radius,
                        geom,
                        min_grid_distance,
                        adjusted_min_distance,
                        num_points,
                        boundary_line,
                        sink_points,
                        sink_polygons,
                        xform,
                        global_id,
                        diameter,
                        feedback,
                        talhao_value  # Passa o valor do talhão
                    )
                    if success:
                        global_id += num_points
                        point_count += num_points
                    else:
                        buffer_distance -= 1

            # Se não conseguiu gerar os pontos
            if not success:
                error_message = (
                    f"Não foi possível gerar o número necessário de pontos para o talhão '{talhao_value}' (polígono {current})."
                    if talhao_value
                    else f"Não foi possível gerar o número necessário de pontos para o polígono {current}."
                )
                feedback.reportError(error_message)
                feedback.setProgress(int((current + 1) * total))
                continue

            # Se deu certo, recuperamos as variáveis "best" para gerar a grade
            best_grid_lines = self._best_grid_lines
            best_spacing = self._best_spacing
            best_angle = self._best_angle

            # Aqui, "initial_spacing" é o valor exato calculado por sqrt(area / num_points)
            # e "best_spacing" é o valor efetivamente usado (podendo ser >= min_grid_distance).
            initial_spacing = self._initial_spacing  

            # Arredondar para 2 casas decimais
            initial_spacing_rounded = round(initial_spacing, 2)
            best_spacing_rounded = round(best_spacing, 2)

            # Grade 1 (original)
            clipped_lines_original = [line.intersection(geom) for line in best_grid_lines]
            clipped_lines_original = [line for line in clipped_lines_original if not line.isNull()]

            if clipped_lines_original:
                grid_feature_original = QgsFeature()
                grid_feature_original.setGeometry(QgsGeometry.collectGeometry(clipped_lines_original))
                # (ID, Talhao, Espac_ini, Espac_usado, Angle, Grade)
                attrs_original = [
                    current,
                ]
                if talhao_value is not None:
                    attrs_original.append(talhao_value)
                attrs_original.extend([
                    initial_spacing_rounded,
                    best_spacing_rounded,
                    best_angle,
                    "Grade 1"
                ])
                grid_feature_original.setAttributes(attrs_original)
                sink_grid1.addFeature(grid_feature_original, QgsFeatureSink.FastInsert)

            # Grade 2 (original + paralela)
            parallel_grid_lines = self.generate_parallel_grid(best_grid_lines, best_spacing)
            all_lines = best_grid_lines + parallel_grid_lines
            clipped_lines_all = [line.intersection(geom) for line in all_lines]
            clipped_lines_all = [line for line in clipped_lines_all if not line.isNull()]

            if clipped_lines_all:
                grid_feature_parallel = QgsFeature()
                grid_feature_parallel.setGeometry(QgsGeometry.collectGeometry(clipped_lines_all))
                # (ID, Talhao, Espac_ini, Espac_usado, Angle, Grade)
                attrs_parallel = [
                    current,
                ]
                if talhao_value is not None:
                    attrs_parallel.append(talhao_value)
                attrs_parallel.extend([
                    initial_spacing_rounded,
                    best_spacing_rounded,
                    best_angle,
                    "Grade 2"
                ])
                grid_feature_parallel.setAttributes(attrs_parallel)
                sink_grid2.addFeature(grid_feature_parallel, QgsFeatureSink.FastInsert)

            feedback.setProgress(int((current + 1) * total))

        feedback.pushInfo(f'Total de pontos gerados: {point_count}')
        return {
            self.OUTPUT_POINTS: points_dest_id,
            self.OUTPUT_POLYGONS: polygons_dest_id,
            self.OUTPUT_GRID1: grid1_dest_id,
            self.OUTPUT_GRID2: grid2_dest_id
        }

    def try_buffer_distance(
        self,
        buffer_distance,
        radius,
        geom,
        min_grid_distance,
        adjusted_min_distance,
        num_points,
        boundary_line,
        sink_points,
        sink_polygons,
        xform,
        global_id,
        diameter,
        feedback,
        talhao_value  # Novo parâmetro para Talhao
    ):
        """
        Tenta gerar pontos com uma bordadura específica (buffer_distance).
        1) Aplica buffer negativo na geometria (geom.buffer(-adjusted_buffer, 5)).
        2) Calcula o espaçamento inicial como sqrt(Área do buffer / Número de parcelas).
        3) Define o espaçamento final como max(espaçamento_inicial, Distância mínima da grade).
        4) Gera a grade e verifica se há interseções suficientes.
        5) Se conseguir criar num_points pontos que atendem ao distanciamento,
           salva as variáveis de grade e cria as feições de ponto/polígono.
        6) Retorna True se bem-sucedido, False caso contrário.
        """
        adjusted_buffer = buffer_distance + radius
        buffered_geom = geom.buffer(-adjusted_buffer, 5)

        # Se a geometria bufferizada sumiu, não há espaço
        if buffered_geom.isEmpty():
            return False

        # Área do buffer para cálculo do espaçamento
        buffered_area = buffered_geom.area()

        # Espaçamento inicial calculado pela raiz
        space_calculated = math.sqrt(buffered_area / num_points)
        self._initial_spacing = space_calculated  # guardamos para sair no atributo

        # Espaçamento final aplicado
        if min_grid_distance > 0:
            final_spacing = max(space_calculated, min_grid_distance)
        else:
            final_spacing = space_calculated

        best_grid_lines = []
        best_intersections = []
        best_spacing = final_spacing
        best_angle = 0

        # Testa ângulos de 0 a 179, procurando a melhor situação
        for angle in range(0, 180, 1):
            grid_lines, intersections = self.generate_grid(buffered_geom, best_spacing, angle)

            if len(intersections) >= num_points:
                best_grid_lines = grid_lines
                best_intersections = intersections
                best_angle = angle
                break  # já achou uma grade que comporta
            elif len(intersections) > len(best_intersections):
                best_grid_lines = grid_lines
                best_intersections = intersections
                best_angle = angle

        # Se a melhor grade não tem interseções suficientes
        if len(best_intersections) < num_points:
            return False

        # Seleciona pontos de forma a respeitar a distância mínima ajustada
        selected_points = []
        for point in sorted(best_intersections, key=lambda p: (p.y(), p.x())):
            if not selected_points or all(point.distance(p) >= adjusted_min_distance for p in selected_points):
                selected_points.append(point)
                if len(selected_points) == num_points:
                    break

        if len(selected_points) < num_points:
            return False

        # Guardamos as variáveis de grade
        self._best_grid_lines = best_grid_lines
        self._best_spacing = best_spacing
        self._best_angle = best_angle

        # -- NOVO: Calcular Distância (entre centros) e Borda (à fronteira) --
        # Monta uma matriz de distâncias entre todos os centros selecionados
        n = len(selected_points)
        dist_matrix = [[9999999]*n for _ in range(n)]
        for i in range(n):
            for j in range(i+1, n):
                d = selected_points[i].distance(selected_points[j])
                dist_matrix[i][j] = d
                dist_matrix[j][i] = d

        # Para cada ponto, definimos:
        #  Distância = min(distância entre centros) - 2*radius (ou zero se der negativo)
        #  Borda = distância à fronteira - radius (ou zero se der negativo)
        for i, point in enumerate(selected_points):
            # Distância ao centro mais próximo
            if n == 1:  # Se só há uma parcela, distância será NULL
                dist_val = None
            else:
                min_center_dist = min([d for d in dist_matrix[i] if d > 0]) if n > 1 else 9999999
                dist_val = min_center_dist - (2 * radius)
                if dist_val < 0:
                    dist_val = 0.0

            # Distância à borda
            point_geom = QgsGeometry.fromPointXY(point)
            borda_val = boundary_line.distance(point_geom) - radius
            if borda_val < 0:
                borda_val = 0.0

            # Geometrias e atributos
            utm_x = point.x()
            utm_y = point.y()
            point_transformed = xform.transform(point)

            geo_long = self.convert_to_dms(point_transformed.x(), is_latitude=False)
            geo_lat = self.convert_to_dms(point_transformed.y(), is_latitude=True)

            # Mantemos 8 casas decimais sem truncar
            dgeo_x = round(point_transformed.x(), 8)
            dgeo_y = round(point_transformed.y(), 8)

            # Link Google Maps
            google_maps_link = f"https://www.google.com/maps?q={point_transformed.y()},{point_transformed.x()}"

            # Cria feição de ponto
            new_point_feature = QgsFeature()
            new_point_feature.setGeometry(point_geom)
            # Prepara os atributos
            point_attrs = [
                global_id,
                f"P{global_id:02d}",
                round(utm_x, 3),
                round(utm_y, 3),
                geo_long,
                geo_lat,
                dgeo_x,          # X_DGEO_LON (8 casas decimais)
                dgeo_y,          # Y_DGEO_LAT (8 casas decimais)
                dist_val,         # Distância (NULL se apenas 1 parcela)
                round(borda_val, 2),
                google_maps_link  # "Google_Map" no final
            ]

            if talhao_value is not None:
                point_attrs.insert(2, talhao_value)  # Adiciona o Talhao após "Nome"

            new_point_feature.setAttributes(point_attrs)
            sink_points.addFeature(new_point_feature, QgsFeatureSink.FastInsert)

            # Cria feição de polígono (buffer)
            buffer_geom = point_geom.buffer(radius, 30)
            new_polygon_feature = QgsFeature()
            new_polygon_feature.setGeometry(buffer_geom)
            # Prepara os atributos
            polygon_attrs = [
                global_id,
                f"P{global_id:02d}",
                round(utm_x, 3),
                round(utm_y, 3),
                geo_long,
                geo_lat,
                dgeo_x,
                dgeo_y,
                dist_val,         # Distância (NULL se apenas 1 parcela)
                round(borda_val, 2),
                google_maps_link  # "Google_Map" no final
            ]

            if talhao_value is not None:
                polygon_attrs.insert(2, talhao_value)  # Adiciona o Talhao após "Nome"

            new_polygon_feature.setAttributes(polygon_attrs)
            sink_polygons.addFeature(new_polygon_feature, QgsFeatureSink.FastInsert)

            global_id += 1

        return True

    def convert_to_dms(self, decimal_degree, is_latitude=True):
        direction = 'N' if is_latitude else 'E'
        if decimal_degree < 0:
            direction = 'S' if is_latitude else 'W'
            decimal_degree = -decimal_degree
        degrees = int(decimal_degree)
        minutes = int((decimal_degree - degrees) * 60)
        seconds = (decimal_degree - degrees - minutes / 60) * 3600
        return f"{degrees}°{minutes}'{seconds:.3f}\" {direction}".replace('.', ',')

    def shortHelpString(self):
        return """
<p><strong>Descrição:</strong>
Esta ferramenta automatiza a geração de pontos e polígonos de amostragem sistemática dentro de talhões de florestas plantadas, facilitando a realização de inventários florestais. Utilizando parâmetros configuráveis, assegura uma distribuição uniforme das parcelas, respeitando bordaduras e distâncias mínimas estabelecidas.</p>

<hr>

<h3>Parâmetros de Entrada:</h3>
<ol>
    <li><strong>Input talhões:</strong>
        - <strong>Descrição:</strong> Camada vetorial de polígonos que representam os talhões florestais onde as parcelas serão geradas.
    </li>
    <li><strong>Número de parcelas:</strong>
        - <strong>Descrição:</strong> Campo da camada de entrada que indica o número de parcelas a serem geradas em cada talhão.
    </li>
    <li><strong>Nome do talhão (Opcional):</strong>
        - <strong>Descrição:</strong> Campo da camada de entrada que contém o nome ou identificador de cada talhão.
        - <strong>Observação:</strong> Opcional para identificar parcelas conforme o talhão correspondente.
    </li>
    <li><strong>Bordadura inicial (m):</strong>
        - <strong>Descrição:</strong> Distância inicial a partir da borda externa do talhão onde as parcelas não serão geradas. Tenta alocar parcelas respeitando esta distância. Se não for possível, reduz progressivamente em 1 metro até atingir a <strong>Bordadura final</strong>, podendo resultar em menos parcelas que não respeitam totalmente a bordadura inicial.
        - <strong>Valor Padrão:</strong> 25.0 metros.
    </li>
    <li><strong>Bordadura final (m):</strong>
        - <strong>Descrição:</strong> Distância mínima a partir da borda externa do talhão considerada ao reduzir a <strong>Bordadura inicial</strong>. Define o limite inferior para a redução da bordadura durante a alocação das parcelas.
        - <strong>Valor Padrão:</strong> 25.0 metros.
    </li>
    <li><strong>Área da parcela (m²):</strong>
        - <strong>Descrição:</strong> Área de cada parcela de amostragem.
        - <strong>Valor Padrão:</strong> 400.0 m².
    </li>
    <li><strong>Distância mínima da grade (m):</strong>
        - <strong>Descrição:</strong> Valor mínimo para o espaçamento entre parcelas na grade gerada. A ferramenta calcula o espaçamento inicial como <em>√(Área do buffer / Número de parcelas)</em>. Se o espaçamento inicial for menor que este valor, utiliza a <strong>Distância mínima da grade</strong> como espaçamento final.
        Se definido como <strong>0</strong>, utiliza exclusivamente o espaçamento inicial calculado.
        - <strong>Valor Padrão:</strong> 150.0 metros.
    </li>
</ol>

<hr>

<h3>Saídas Geradas:</h3>
<ol>
    <li><strong>Output centro da parcela:</strong>
        - <strong>Descrição:</strong> Camada de pontos representando o centro de cada parcela gerada.
    </li>
    <li><strong>Output parcelas:</strong>
        - <strong>Descrição:</strong> Camada de polígonos representando as áreas de cada parcela de amostragem.
    </li>
    <li><strong>Output Grade 1 (Original):</strong>
        - <strong>Descrição:</strong> Camada de linhas que representam a grade original utilizada para gerar as parcelas.
    </li>
    <li><strong>Output Grade 2 (Original + Paralela):</strong>
        - <strong>Descrição:</strong> Camada de linhas combinando a grade original com linhas paralelas adicionais. Essas grades facilitam a intensificação futura do inventário, já disponibilizando mais locais para alocação de novas parcelas.
    </li>
</ol>

<hr>

<h3>Funcionamento:</h3>
<ul>
    <li><strong>Geração de Grade:</strong> A Geração de Grade cria uma disposição sistemática de pontos no talhão, ajustando o espaçamento conforme a área e o número de parcelas. A grade pode ser rotacionada em ângulos de 0 a 180 graus para otimizar a distribuição dos pontos e evitar sobreposições, garantindo um alinhamento eficiente das parcelas.</li>
    <li><strong>Aplicação de Buffers:</strong> Aplica bordaduras inicialmente e ajusta progressivamente se necessário. A <strong>Bordadura inicial</strong> define a margem onde as parcelas não serão colocadas. Se a alocação das parcelas com essa bordadura não for possível, a ferramenta reduz a bordadura em incrementos de 1 metro até atingir a <strong>Bordadura final</strong>, podendo resultar em menos parcelas que não respeitam totalmente a bordadura inicial.</li>
    <li><strong>Seleção de Pontos:</strong> Seleciona pontos nas interseções da grade que servem como centros das parcelas, garantindo a distância mínima entre eles.</li>
    <li><strong>Criação de Polígonos:</strong> Gera polígonos circulares a partir dos pontos selecionados, com raio calculado com base na área especificada.</li>
    <li><strong>Geração de Grades Adicionais:</strong> Cria uma grade paralela para fornecer mais locais potenciais para futuras alocações de parcelas, facilitando a expansão e flexibilidade do inventário.</li>
</ul>

<hr>

<h3>Benefícios:</h3>
<ul>
    <li><strong>Automatização:</strong> Reduz o tempo e esforço necessários para gerar amostragens sistemáticas manualmente.</li>
    <li><strong>Precisão:</strong> Garante uma distribuição uniforme e evita sobreposições indesejadas.</li>
    <li><strong>Flexibilidade:</strong> Permite ajustes nos parâmetros conforme as necessidades específicas do inventário.</li>
    <li><strong>Expansibilidade:</strong> Facilita a intensificação futura do inventário ao já possuir uma grade com locais adicionais para alocação de novas parcelas.</li>
    <li><strong>Integração:</strong> Fácil integração com outras ferramentas e fluxos de trabalho no QGIS.</li>
</ul>
"""

    def name(self):
        return 'generate_points'

    def displayName(self):
        return 'Gerar Amostragem Sistemática (Inventário Florestal)'

    def group(self):
        return 'Custom Scripts'

    def groupId(self):
        return 'customscripts'

    def createInstance(self):
        return GeneratePointsAlgorithm()

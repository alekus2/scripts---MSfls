
import logging
import os
import openpyxl
from pptx import Presentation
from pptx.chart.data import CategoryChartData
from pptx.enum.chart import XL_CHART_TYPE
from pptx.util import Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

class Shape:
    def __init__(self, config):
        self.name = config['shape_name']
        self.object_name = config['object_name']
        self.data_sheet = config['data_sheet']
        self.cell = config['cell']
        self.font_size = config['font_size']
        self.font_type = config['font_type']
        self.bold = config['bold']
        self.color = config['color'].lstrip('#')
        self.alignment = config['alignment']
        self.text_case = config['text_case'].lower()
        self.add_percentage = config['add_percentage']
        self.decimal_places = config['decimal_places']

    def update(self, shape, value):
        try:
            float_value = float(value)
            is_numeric = True
        except ValueError:
            float_value = value
            is_numeric = False

        if is_numeric:
            text = f"{float_value:.{self.decimal_places}f}" if self.decimal_places is not None else str(value)
        else:
            text = str(value)

        if self.text_case == 'uppercase':
            text = text.upper()
        elif self.text_case == 'lowercase':
            text = text.lower()
        elif self.text_case == 'titlecase':
            text = text.title()

        if self.add_percentage and is_numeric:
            text = f"{text}%"

        shape.text_frame.text = text
        paragraph = shape.text_frame.paragraphs[0]
        paragraph.font.size = Pt(self.font_size)
        paragraph.font.name = self.font_type
        paragraph.font.bold = self.bold
        paragraph.font.color.rgb = RGBColor.from_string(self.color)
        paragraph.alignment = getattr(PP_ALIGN, self.alignment.upper())

class Chart:
    def __init__(self, config):
        self.name = config['chart_name']
        self.object_name = config['object_name']
        self.data_sheet = config['data_sheet']
        self.data_range = config['data_range']
        self.columns = [config[f'column_{i}'] for i in range(1, 3) if config[f'column_{i}']]
        self.chart_type = config['chart_type']
        self.colors = [config[f'color_{i}'] for i in range(1, 3) if config[f'color_{i}']]

    def update(self, chart, data):
        chart_data = CategoryChartData()
        categories = [row[0] for row in data[1:]]
        chart_data.categories = categories

        for i, col_name in enumerate(self.columns):
            col_index = data[0].index(col_name)
            series_values = [row[col_index] for row in data[1:]]
            chart_data.add_series(col_name, series_values)

        chart.replace_data(chart_data)

        if self.chart_type.lower() == 'line' and self.colors:
            for i, series in enumerate(chart.series):
                if i < len(self.colors):
                    color = RGBColor.from_string(self.colors[i].lstrip('#'))
                    series.format.line.color.rgb = color

class ReportingSystem:
    def __init__(self, ppt_template, excel_file):
        self.ppt_template = ppt_template
        self.excel_file = excel_file
        self.charts = []
        self.shapes = []

    def load_configuration(self):
		wb = openpyxl.load_workbook(self.excel_file, data_only=True)

    # Alterar os nomes das planilhas aqui
		charts_sheet = wb['Grafico']  # Novo nome da planilha de gráficos
		for row in charts_sheet.iter_rows(min_row=2, values_only=True):
			if row[0]:
				chart_config = {
					'chart_name': row[0],
					'object_name': row[1],
					'data_sheet': row[2],
					'data_range': row[3],
					'column_1': row[4],
					'column_2': row[5],
					'chart_type': row[6],
					'color_1': row[7] if len(row) > 7 else None,
					'color_2': row[8] if len(row) > 8 else None,
				}
				self.charts.append(Chart(chart_config))

		shapes_sheet = wb['Formas']  # Novo nome da planilha de formas
		for row in shapes_sheet.iter_rows(min_row=2, values_only=True):
			if row[0]:
				shape_config = {
					'shape_name': row[0],
					'object_name': row[1],
					'data_sheet': row[2],
					'cell': row[3],
					'font_size': int(row[4]),
					'font_type': row[5],
					'bold': row[6],
					'color': row[7],
					'alignment': row[8],
					'text_case': row[9] if len(row) > 9 else 'default',
					'add_percentage': row[10] if len(row) > 10 else False,
					'decimal_places': int(row[11]) if len(row) > 11 and row[11] is not None else None 
				}
				self.shapes.append(Shape(shape_config))

		wb.close()
		logging.info(f"Loaded {len(self.charts)} charts and {len(self.shapes)} shapes from configuration")

    def generate_report(self, output_file):
        # Load the presentation template
        prs = Presentation(self.ppt_template)

        for shape in self.shapes:
            data = self.load_data(shape.data_sheet, shape.cell)
            if data:
                shape_name = shape.object_name
                ppt_shape = self.find_shape(prs, shape_name)
                if ppt_shape:
                    shape.update(ppt_shape, data)

        for chart in self.charts:
            data = self.load_data(chart.data_sheet, chart.data_range)
            if data:
                chart_name = chart.object_name
                ppt_chart = self.find_chart(prs, chart_name)
                if ppt_chart:
                    chart.update(ppt_chart, data)

        prs.save(output_file)
        logging.info(f"Report generated and saved to {output_file}")

    def load_data(self, sheet_name, cell_range):
        wb = openpyxl.load_workbook(self.excel_file, data_only=True)
        sheet = wb[sheet_name]
        data = sheet[cell_range]
        return [[cell.value for cell in row] for row in data]

    def find_shape(self, prs, shape_name):
        for slide in prs.slides:
            for shape in slide.shapes:
                if shape.name == shape_name:
                    return shape
        return None

    def find_chart(self, prs, chart_name):
        for slide in prs.slides:
            for shape in slide.shapes:
                if shape.name == chart_name and shape.has_chart:
                    return shape.chart
        return None

# Path definitions
template_path = r"/report_template.pptx"
data_path = r"/reporting_data.xlsx"
output_path = r"/output.pptx"

logging.info("Started report generation")

# Check for the files
if not os.path.exists(template_path):
    raise FileNotFoundError(f"Template file is missing: {template_path}")

if not os.path.exists(data_path):
    raise FileNotFoundError(f"Data file is missing: {data_path}")

try:
    reporting_system = ReportingSystem(template_path, data_path)
    reporting_system.load_configuration()
    reporting_system.generate_report(output_path)
except Exception as e:
    logging.error(f"An error occurred while generating the report: {str(e)}")
    raise 

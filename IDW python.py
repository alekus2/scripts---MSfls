def decimal_to_percentage(decimal_number, decimal_places=2):
    percentage = decimal_number * 100
    return f"{percentage:.{decimal_places}f}%"

# Exemplo de uso
print(decimal_to_percentage(0.25))  # Saída: 25.00%
print(decimal_to_percentage(0.2567, 1))  # Saída: 25.7%
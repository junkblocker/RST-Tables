if has('python3')
    let s:py_env = 'python3 << EOF'
elseif has('python')
    let s:py_env = 'python << EOF'
else
    finish
endif

exe s:py_env
# -*- encoding: utf-8 -*-
import vim
import re

def rst_tables_create_separarator(widths, char):
    """Genera una linea para separar filas de una tabla.

    El parametro `widths` es un lista indicando el ancho de cada
    columna. En cambio el argumento `char` es el caracter que se
    tiene que utilizar para imprimir.

    El valor retornado es un string.

    Por ejemplo::

        >>> rst_tables_create_separarator([2, 4], '-')
        '+----+------+'
    """

    line = []

    for w in widths:
        line.append("+" + char * (w + 2))

    line.append("+")
    return ''.join(line)


def rst_tables_create_line(columns, widths):
    """Crea una fila de la tabla separando los campos con un '|'.

    El argumento `columns` es una lista con las celdas que se
    quieren imprimir y el argumento `widths` tiene el ancho
    de cada columna. Si la columna es mas ancha que el texto
    a imprimir se agregan espacios vacíos.

    Por ejemplo::

        >>> rst_tables_create_line(['nombre', 'apellido'], [7, 10])
        '| nombre  | apellido   |'
    """

    line = zip(columns, widths)
    result = []

    for text, width in line:
        result.append("| " + text.ljust(width) + " ")

    result.append("|")
    return ''.join(result)

def rst_tables_create_table(content):
    """Imprime una tabla en formato restructuredText.

    El argumento `content` tiene que ser una lista
    de celdas.

    Por ejemplo::

        >>> print rst_tables_create_table([['software', 'vesion'], ['python', '2.6'], ['vim', '7.2']])
        +----------+--------+
        | software | vesion |
        +==========+========+
        | python   | 2.6    |
        +----------+--------+
        | vim      | 7.2    |
        +----------+--------+
    """

    # obtiene las columnas de toda la tabla.
    columns = zip(*content)
    # calcula el tamano maximo que debe tener cada columna.
    widths = [max([len(x) for x in i]) for i in columns]

    result = []

    result.append(rst_tables_create_separarator(widths, '-'))
    result.append(rst_tables_create_line(content[0], widths))
    result.append(rst_tables_create_separarator(widths, '='))

    for line in content[1:]:
        result.append(rst_tables_create_line(line, widths))
        result.append(rst_tables_create_separarator(widths, '-'))

    return '\n'.join(result)



def rst_tables_are_in_a_table(current_line):
    "Indica si el cursor se encuentra dentro de una tabla."
    return "|" in current_line or "+" in current_line

def rst_tables_are_in_a_paragraph(current_line):
    "Indica si la linea actual es parte de algun parrafo"
    return len(current_line.strip()) >= 1

def rst_tables_get_table_bounds(current_row_index, are_in_callback):
    """Obtiene el numero de fila donde comienza y termina la tabla.

    el argumento `are_in_callback` tiene que ser una función
    que indique si una determinada linea pertenece o no
    a la tabla que se quiere medir (o crear).

    Retorna ambos valores como una tupla.
    """

    top = 0
    buffer = vim.current.buffer
    max = len(buffer)
    bottom = max - 1

    for a in range(current_row_index, top, -1):
        if not are_in_callback(buffer[a]):
            top = a + 1
            break

    for b in range(current_row_index, max):
        if not are_in_callback(buffer[b]):
            bottom = b - 1
            break

    return top, bottom

def rst_tables_remove_spaces(string):
    "Elimina los espacios innecesarios de una fila de tabla."
    return re.sub("\s\s+", " ", string)

def rst_tables_create_separators_removing_spaces(string):
    return re.sub("\s\s+", "|", string)


def rst_tables_extract_cells_as_list(string):
    "Extrae el texto de una fila de tabla y lo retorna como una lista."
    string = rst_tables_remove_spaces(string)
    return [item.strip() for item in string.split('|') if item]

def rst_tables_extract_table(buffer, top, bottom):
    content = []
    full_table_text = buffer[top:bottom]
    # selecciona solamente las lineas que tienen celdas con texto.
    only_text_lines = [x for x in full_table_text if '|' in x]
    # extrae las celdas y descarta los separadores innecesarios.
    return [rst_tables_extract_cells_as_list(x) for x in only_text_lines]

def rst_tables_extract_words_as_lists(buffer, top, bottom):
    "Genera una lista de palabras para crear una lista."

    lines = buffer[top:bottom+1]
    return [rst_tables_create_separators_removing_spaces(line).split('|') for line in lines]


def rst_tables_copy_to_buffer(buffer, string, index):
    lines = string.split('\n')
    for line in lines:
        buffer[index] = line
        index += 1

def rst_tables_fix_table(current_row_index):
    """Arregla una tabla para que todas las columnas tengan el mismo ancho.

    `initial_row` es un numero entero que indica en que
    linea se encuenta el cursor."""

    # obtiene el indice donde comienza y termina la tabla.
    r1, r2 = rst_tables_get_table_bounds(current_row_index, rst_tables_are_in_a_table)

    # extrae de la tabla solo las celdas de texto
    table_as_list = rst_tables_extract_table(vim.current.buffer, r1, r2)

    # genera una nueva tabla tipo restructured text y la dibuja en el buffer.
    table_content = rst_tables_create_table(table_as_list)
    rst_tables_copy_to_buffer(vim.current.buffer, table_content, r1)


def RstTablesFixTable():
    (row, col) = vim.current.window.cursor
    line = vim.current.buffer[row-1]

    if rst_tables_are_in_a_table(line):
        rst_tables_fix_table(row-1)
    else:
        print("No estoy en una tabla. Terminando...")


def RstTablesCreateTable():
    (row, col) = vim.current.window.cursor
    line = vim.current.buffer[row-1]

    top, bottom = rst_tables_get_table_bounds(row - 1, rst_tables_are_in_a_paragraph)
    lines = rst_tables_extract_words_as_lists(vim.current.buffer, top, bottom)
    table_content = rst_tables_create_table(lines)
    vim.current.buffer[top:bottom+1] = table_content.split('\n')


EOF

if has('python3')
    map ,,c :python3 RstTablesCreateTable()<CR>
    map ,,f :python3 RstTablesFixTable()<CR>
elseif has('python')
    map ,,c :python RstTablesCreateTable()<CR>
    map ,,f :python RstTablesFixTable()<CR>
endif

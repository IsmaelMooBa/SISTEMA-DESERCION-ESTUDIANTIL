from flask import Flask, request, jsonify
import pandas as pd
import os

app = Flask(__name__)
UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    filepath = os.path.join(app.config['UPLOAD_FOLDER'], file.filename)
    file.save(filepath)

    df = pd.read_csv(filepath)

    if df.shape[1] < 3:
        return jsonify({'error': 'El archivo no tiene suficientes columnas'}), 400

    # Calcular el promedio de cada estudiante
    columns_to_average = df.columns[2:]  # Ignorar las primeras dos columnas (ID y Nombre)
    df['PROMEDIO'] = df[columns_to_average].mean(axis=1)

    # Identificar alumnos con promedio menor o igual a 7
    filtered_students = df[df['PROMEDIO'] <= 7]

    # Convertir DataFrame a JSON
    response_data = {
        "all_students": df.to_dict(orient="records"),
        "filtered_students": filtered_students.to_dict(orient="records")
    }

    return jsonify(response_data)

if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0", port=5000)

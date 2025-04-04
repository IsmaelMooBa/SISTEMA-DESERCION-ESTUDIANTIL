import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFFFA726),
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
          headlineMedium: TextStyle(color: Color(0xFFFFA726)),
        ),
      ),
      home: const CSVUploader(),
    );
  }
}

class CSVUploader extends StatefulWidget {
  const CSVUploader({Key? key}) : super(key: key);

  @override
  CSVUploaderState createState() => CSVUploaderState();
}

class CSVUploaderState extends State<CSVUploader> {
  File? _selectedFile;
  List<List<dynamic>> _csvData = [];
  bool _tableProjected = false;
  bool _isLoading = false;
  List<String> _aiRecommendations = [];
  List<Map<String, dynamic>> _studentAverages = [];

  Future<void> pickFile() async {
    setState(() {
      _isLoading = true;
      _aiRecommendations.clear();
      _studentAverages.clear();
    });

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _tableProjected = false;
      });

      final input = _selectedFile!.openRead();
      final fields = await input
          .transform(utf8.decoder)
          .transform(CsvToListConverter())
          .toList();

      setState(() {
        _csvData = fields;
        _tableProjected = true;
        _isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se seleccionó un archivo CSV.')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void calculateAverages() {
    List<Map<String, dynamic>> averages = [];
    List<String> recomendaciones = [];

    if (_csvData.length < 2) return;

    for (int i = 1; i < _csvData.length; i++) {
      final fila = _csvData[i];
      String nombre = fila[0].toString();

      bool tieneReprobado = false;
      double sum = 0;
      int count = 0;
      List<double> calificaciones = [];

      for (int j = 1; j < fila.length; j++) {
        double? valor;

        if (fila[j] is num) {
          valor = (fila[j] as num).toDouble();
        } else if (fila[j] is String) {
          valor = double.tryParse(fila[j]);
        }

        if (valor != null) {
          count++;
          sum += valor;
          calificaciones.add(valor);
          if (valor < 7) tieneReprobado = true;
        }
      }

      double promedio = count > 0 ? sum / count : 0;

      averages.add({
        'nombre': nombre,
        'promedio': promedio,
        'tieneReprobado': tieneReprobado,
        'calificaciones': calificaciones,
      });

      if (tieneReprobado) {
        recomendaciones.add(
          "$nombre: Se recomienda atención personalizada y apoyo en materias clave.");
      } else if (promedio >= 9) {
        recomendaciones.add(
          "$nombre: Excelente rendimiento, mantener constancia. Considerar retos adicionales.");
      } else if (promedio >= 7) {
        recomendaciones.add(
          "$nombre: Desempeño aceptable, revisar asistencia o hábitos de estudio.");
      } else {
        recomendaciones.add(
          "$nombre: Bajo rendimiento general. Evaluar posibles factores externos.");
      }
    }

    setState(() {
      _studentAverages = averages;
      _aiRecommendations = recomendaciones;
    });
  }

  Widget _buildAverageCard(Map<String, dynamic> student) {
    Color cardColor = student['tieneReprobado']
        ? Colors.orange[100]!
        : student['promedio'] >= 7
            ? Colors.green[100]!
            : Colors.red[100]!;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  student['nombre'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  backgroundColor: student['tieneReprobado']
                      ? Colors.orange
                      : student['promedio'] >= 7
                          ? Colors.green
                          : Colors.red,
                  label: Text(
                    'Promedio: ${student['promedio'].toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (student['calificaciones'].isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: student['calificaciones'].map<Widget>((calif) {
                  return Chip(
                    label: Text(calif.toStringAsFixed(1)),
                    backgroundColor: calif < 7
                        ? Colors.red[100]
                        : Colors.green[100],
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildDataTable(List<List<dynamic>> data) {
    if (data.isEmpty) return Container();

    final headers = data[0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Center(
          child: Text(
            "Tabla de calificación",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: DataTable(
                columnSpacing: 20,
                columns: headers.map((header) {
                  return DataColumn(
                    label: Text(
                      header.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                rows: data.sublist(1).map((row) {
                  return DataRow(
                    cells: List.generate(row.length, (index) {
                      final cell = row[index];
                      Color cellColor = Colors.black;

                      if (index != 0 && cell is num) {
                        cellColor = cell < 7 ? Colors.red : Colors.green;
                      }

                      return DataCell(
                        Text(
                          cell.toString(),
                          style: TextStyle(color: cellColor),
                        ),
                      );
                    }),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sistema de Predicción de Deserción Estudiantil"),
        backgroundColor: const Color(0xFFFFA726),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Center(
                child: Text(
                  'Bienvenido al Sistema de Predicción de Deserción Estudiantil',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFA726),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Instrucciones: Ingresa un archivo de Excel guardado con extensión CSV (separado por comas), procura seleccionar archivos que contengan nombre de los alumnos como primera columna y materias en las primeras filas.',
                style: TextStyle(fontSize: 16, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: pickFile,
                icon: const Icon(Icons.upload_file, color: Colors.white),
                label: const Text("Seleccionar archivo"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA726),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "CSV (separado por comas)",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              if (_selectedFile != null)
                Text(
                  "Archivo seleccionado: ${_selectedFile!.path}",
                  style: const TextStyle(color: Colors.black),
                ),
              const SizedBox(height: 20),
              if (_tableProjected)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 28),
                        SizedBox(width: 10),
                        Text(
                          "Selección exitosa",
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                buildDataTable(_csvData),
              const SizedBox(height: 30),
              if (_tableProjected)
                ElevatedButton.icon(
                  onPressed: calculateAverages,
                  icon: const Icon(Icons.calculate, color: Colors.white),
                  label: const Text("Calcular Promedios"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 234, 165, 6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              if (_studentAverages.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Promedios Estudiantiles",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 240, 158, 7),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._studentAverages.map((student) => _buildAverageCard(student)).toList(),
                  ],
                ),
              const SizedBox(height: 20),
              if (_aiRecommendations.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Recomendaciones:",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 240, 158, 7),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._aiRecommendations.map((e) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb_outline, color: Colors.amber),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

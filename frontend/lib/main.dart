// ============================
//  Importación de paquetes
// ============================

import 'dart:convert'; // Para convertir CSV a JSON
import 'dart:io'; // Para manejar archivos locales
import 'package:flutter/material.dart'; // Para crear la interfaz
import 'package:file_picker/file_picker.dart'; // Para seleccionar archivos
import 'package:csv/csv.dart'; // Para leer contenido CSV

// ============================
//  Punto de entrada principal
// ============================

void main() {
  runApp(const MyApp());
}

// ============================
//  Widget principal de la app
// ============================

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

// ============================
//  Pantalla para subir y mostrar CSV
// ============================

class CSVUploader extends StatefulWidget {
  const CSVUploader({Key? key}) : super(key: key);

  @override
  CSVUploaderState createState() => CSVUploaderState();
}

// ============================
//  Estado del widget CSVUploader
// ============================

class CSVUploaderState extends State<CSVUploader> {
  File? _selectedFile; // Archivo CSV seleccionado
  List<List<dynamic>> _csvData = []; // Datos cargados desde el CSV
  bool _tableProjected = false; // Indica si se proyectó la tabla
  bool _isLoading = false; // Indica si se esta cargando el archivo

  // ============================
  //  Función para seleccionar el archivo CSV
  // ============================

  Future<void> pickFile() async {
    setState(() {
      _isLoading = true; // Empieza la carga
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

      // Lee el contenido del archivo CSV
      final input = _selectedFile!.openRead();
      final fields =
          await input
              .transform(utf8.decoder)
              .transform(CsvToListConverter())
              .toList();

      setState(() {
        _csvData = fields;
        _tableProjected = true;
        _isLoading = false; // Termina la carga
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se seleccionó un archivo CSV.')),
      );
      setState(() {
        _isLoading = false; // Termina la carga
      });
    }
  }

  // ============================
  //  Función para filtrar estudiantes reprobados
  // ============================

  List<List<dynamic>> getReprobados(List<List<dynamic>> data) {
    if (data.isEmpty) return [];

    List<List<dynamic>> reprobados = [data[0]]; // Incluye los encabezados
    for (int i = 1; i < data.length; i++) {
      for (int j = 0; j < data[i].length; j++) {
        if (data[i][j] is num && data[i][j] < 7) {
          reprobados.add(data[i]);
          break; // Agrega la fila solo una vez
        }
      }
    }
    return reprobados;
  }

  // ============================
  //  Función para construir la tabla de forma dinámica
  // ============================

  Widget buildDataTable(List<List<dynamic>> data) {
    if (data.isEmpty) return Container();

    final headers = data[0]; // Primera fila = encabezados

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            "Datos CSV",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal, // Soporta muchas columnas
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
              color: Colors.white,
            ),
            child: DataTable(
              columnSpacing: 20,
              columns:
                  headers.map((header) {
                    return DataColumn(
                      label: Text(
                        header.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
              rows:
                  data.sublist(1).map((row) {
                    return DataRow(
                      cells:
                          row.map((cell) {
                            Color cellColor = Colors.black; // Color por defecto
                            if (cell is num) {
                              if (cell < 7) {
                                cellColor =
                                    Colors.red; // Calificación baja en rojo
                              } else {
                                cellColor =
                                    Colors.green; // Calificación buena en verde
                              }
                            }
                            return DataCell(
                              Text(
                                cell.toString(),
                                style: TextStyle(color: cellColor),
                              ),
                            );
                          }).toList(),
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ============================
  //  Interfaz principal
  // ============================

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

              // Título principal
              Center(
                child: Text(
                  'Bienvenido al Sistema de Predicción de Deserción Estudiantil',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFA726),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Descripción del sistema
              Text(
                'Este sistema permite predecir la deserción estudiantil basado en datos históricos. Puedes cargar un archivo CSV con información de los estudiantes para analizar su desempeño.',
                style: const TextStyle(fontSize: 16, color: Colors.black),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Botón para subir CSV
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: pickFile,
                        icon: const Icon(
                          Icons.upload_file,
                          color: Colors.white,
                        ),
                        label: const Text("Seleccionar CSV"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA726),
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
                        "Selecciona el archivo CSV a subir.",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Ruta del archivo
              if (_selectedFile != null)
                Text(
                  "Archivo seleccionado: ${_selectedFile!.path}",
                  style: const TextStyle(color: Colors.black),
                ),

              const SizedBox(height: 20),

              // Confirmación de carga
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
                          "Se ha proyectado tu tabla correctamente.",
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Indicador de carga
              if (_isLoading)
                const CircularProgressIndicator()
              else
                buildDataTable(_csvData), // Tabla de datos CSV

              const SizedBox(height: 20),

              // Tabla de estudiantes reprobados
              if (_tableProjected)
                if (getReprobados(_csvData).length > 1)
                  Column(
                    children: [
                      const Text(
                        "Estudiantes Reprobados",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      buildDataTable(getReprobados(_csvData)),
                    ],
                  )
                else
                  const Text("No se encontraron estudiantes reprobados."),
            ],
          ),
        ),
      ),
    );
  }
}

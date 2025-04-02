import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
        primaryColor: Colors.orange, // Color principal en naranja (UPT)
        scaffoldBackgroundColor: Colors.white,
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
          headlineMedium: TextStyle(
            color: Colors.orange,
          ), // Títulos en color naranja
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
  List<dynamic> allStudents = [];
  List<dynamic> filteredStudents = [];

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> uploadCSV() async {
    if (_selectedFile == null) return;

    var request = http.MultipartRequest(
      'POST',
      Uri.parse(
        'http://localhost:5000/upload',
      ), // Cambia la URL si es necesario
    );

    request.files.add(
      await http.MultipartFile.fromPath('file', _selectedFile!.path),
    );

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);

      setState(() {
        allStudents = jsonData['all_students'];
        filteredStudents = jsonData['filtered_students'];
      });
    }
  }

  Widget buildDataTable(List<dynamic> data, String title, Color color) {
    return data.isEmpty
        ? Container()
        : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 10),
            DataTable(
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text("ID")),
                DataColumn(label: Text("Nombre")),
                DataColumn(label: Text("Promedio")),
              ],
              rows:
                  data.map((row) {
                    return DataRow(
                      color: MaterialStateProperty.resolveWith<Color?>((
                        states,
                      ) {
                        return data.indexOf(row) % 2 == 0
                            ? Colors.grey.shade100
                            : Colors.white; // Color alterno en filas
                      }),
                      cells: [
                        DataCell(Text(row["ID"].toString())),
                        DataCell(Text(row["Nombre"])),
                        DataCell(
                          Text(
                            row["PROMEDIO"].toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  (row["PROMEDIO"] > 7)
                                      ? Colors.green
                                      : Colors
                                          .red, // Color dependiendo del promedio
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ],
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sistema de Predicción de Deserción Estudiantil"),
        backgroundColor: Colors.orange, // Color de la barra en naranja
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Text(
                  'Bienvenido al Sistema de Predicción de Deserción Estudiantil',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange, // Título principal en naranja
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Este sistema permite predecir la deserción estudiantil basado en datos históricos. Puedes cargar un archivo CSV con información de los estudiantes para analizar su desempeño y pronóstico de continuidad.',
                style: TextStyle(fontSize: 16, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: pickFile,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text("Seleccionar CSV"),
              ),
              const SizedBox(height: 10),
              if (_selectedFile != null)
                Text(
                  "Archivo seleccionado: ${_selectedFile!.path}",
                  style: TextStyle(color: Colors.black),
                ),
              ElevatedButton(
                onPressed: uploadCSV,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text("Subir CSV"),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: buildDataTable(
                  allStudents,
                  "Datos del Archivo",
                  Colors.orange,
                ),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: buildDataTable(
                  filteredStudents,
                  "Alumnos con Promedio ≤ 7",
                  Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

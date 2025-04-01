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
      Uri.parse('http://localhost:5000/upload'), // Cambia la URL si es necesario
    );

    request.files.add(await http.MultipartFile.fromPath('file', _selectedFile!.path));

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
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              DataTable(
                columns: const [
                  DataColumn(label: Text("ID")),
                  DataColumn(label: Text("Nombre")),
                  DataColumn(label: Text("Promedio")),
                ],
                rows: data.map((row) {
                  return DataRow(cells: [
                    DataCell(Text(row["ID"].toString())),
                    DataCell(Text(row["Nombre"])),
                    DataCell(
                      Text(
                        row["PROMEDIO"].toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (row["PROMEDIO"] > 7) ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ],
          );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text("Subir CSV y Filtrar Datos")),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: pickFile,
              child: const Text("Seleccionar CSV"),
            ),
            const SizedBox(height: 10),
            if (_selectedFile != null) Text("Archivo seleccionado: ${_selectedFile!.path}"),
            ElevatedButton(
              onPressed: uploadCSV,
              child: const Text("Subir CSV"),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: buildDataTable(allStudents, "Datos del Archivo", Colors.black),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: buildDataTable(filteredStudents, "Alumnos con Promedio ≤ 7", Colors.red),
            ),
          ],
        ),
      ),
    ),
  );
}
}

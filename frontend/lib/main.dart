// Importa las librerías necesarias
import 'dart:io'; // Para manejar archivos
import 'package:flutter/material.dart'; // Para el framework de Flutter
import 'package:file_picker/file_picker.dart'; // Para seleccionar archivos
import 'package:http/http.dart' as http; // Para hacer peticiones HTTP
import 'dart:convert'; // Para trabajar con datos JSON

void main() {
  runApp(const MyApp());
}

// Clase principal que define la estructura de la aplicación
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Desactiva el banner de depuración
      theme: ThemeData(
        primaryColor: Color(0xFFFFA726), // Color primario de la app
        scaffoldBackgroundColor: Colors.white, // Color de fondo del scaffold
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black), // Color del texto
          headlineMedium: TextStyle(
            color: Color(0xFFFFA726),
          ), // Color de los encabezados
        ),
      ),
      home:
          const CSVUploader(), // Pantalla principal que carga un widget para subir CSV
    );
  }
}

// Widget Stateful para manejar la selección y carga de un archivo CSV
class CSVUploader extends StatefulWidget {
  const CSVUploader({Key? key}) : super(key: key);

  @override
  CSVUploaderState createState() => CSVUploaderState();
}

class CSVUploaderState extends State<CSVUploader> {
  File? _selectedFile; // Archivo seleccionado
  List<dynamic> allStudents =
      []; // Lista para almacenar los datos de todos los estudiantes
  List<dynamic> filteredStudents =
      []; // Lista para almacenar los estudiantes con promedio ≤ 7
  bool _tableProjected =
      false; // Bandera para saber si la tabla ha sido proyectada

  // Función para seleccionar un archivo CSV
  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'], // Solo permite archivos CSV
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(
          result.files.single.path!,
        ); // Asigna el archivo seleccionado
      });
    }
  }

  // Función para cargar el archivo CSV al servidor
  Future<void> uploadCSV() async {
    if (_selectedFile == null)
      return; // Verifica si hay un archivo seleccionado

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://localhost:5000/upload'), // URL del servidor
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        _selectedFile!.path,
      ), // Añade el archivo a la petición
    );

    var response = await request.send(); // Envía la solicitud HTTP

    if (response.statusCode == 200) {
      var responseData =
          await response.stream.bytesToString(); // Recibe la respuesta
      var jsonData = json.decode(responseData); // Decodifica el JSON

      setState(() {
        allStudents =
            jsonData['all_students']; // Asigna los datos de todos los estudiantes
        filteredStudents =
            jsonData['filtered_students']; // Asigna los estudiantes filtrados
        _tableProjected = true; // Establece que la tabla ha sido proyectada
      });
    }
  }

  // Función para construir la tabla de datos
  Widget buildDataTable(List<dynamic> data, String title, Color color) {
    return data.isEmpty
        ? Container() // Si no hay datos, no muestra nada
        : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                title, // Título de la tabla
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color, // Color del título
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ), // Estilo de la tabla
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
                columns: const [
                  DataColumn(
                    label: Text(
                      "ID",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Nombre",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Promedio",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows:
                    data.map((row) {
                      // Muestra las filas de la tabla
                      return DataRow(
                        color: MaterialStateProperty.resolveWith<Color?>((
                          states,
                        ) {
                          return data.indexOf(row) % 2 == 0
                              ? Colors.grey.shade100
                              : Colors.white; // Alterna el color de las filas
                        }),
                        cells: [
                          DataCell(Text(row["ID"].toString())), // Muestra el ID
                          DataCell(Text(row["Nombre"])), // Muestra el nombre
                          DataCell(
                            Text(
                              row["PROMEDIO"].toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    (row["PROMEDIO"] > 7)
                                        ? Colors.green
                                        : Colors
                                            .red, // Cambia el color según el promedio
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ],
        );
  }

  // Construcción de la interfaz de usuario
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sistema de Predicción de Deserción Estudiantil"),
        backgroundColor: Color(0xFFFFA726),
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
                    color: Color(0xFFFFA726),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Este sistema permite predecir la deserción estudiantil basado en datos históricos. Puedes cargar un archivo CSV con información de los estudiantes para analizar su desempeño.',
                style: TextStyle(fontSize: 16, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed:
                            pickFile, // Llama a la función para seleccionar archivo
                        icon: const Icon(
                          Icons.upload_file,
                          color: Colors.white,
                        ),
                        label: const Text("Seleccionar CSV"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFFA726),
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
                  const SizedBox(width: 20),
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed:
                            uploadCSV, // Llama a la función para subir archivo
                        icon: const Icon(
                          Icons.cloud_upload,
                          color: Colors.white,
                        ),
                        label: const Text("Subir CSV"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFFA726),
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
                        "Sube el archivo CSV seleccionado.",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 28),
                        const SizedBox(width: 10),
                        const Text(
                          "Se ha proyectado tu tabla correctamente.",
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: buildDataTable(
                  allStudents,
                  "Datos del Archivo",
                  Color(0xFFFFA726),
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

// Importa las librerías necesarias
import 'dart:io'; // Para manejar archivos
import 'package:flutter/material.dart'; // Para el framework de Flutter
import 'package:file_picker/file_picker.dart'; // Para seleccionar archivos
import 'package:http/http.dart' as http; // Para hacer peticiones HTTP
import 'dart:convert'; // Para trabajar con datos JSON

// Punto de entrada de la aplicación
void main() {
  runApp(const MyApp());
}

// Widget principal de la aplicación
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Oculta la etiqueta de depuración
      theme: ThemeData(
        primaryColor: const Color(
          0xFFFFA726,
        ), // Color primario de la aplicación
        scaffoldBackgroundColor: Colors.white, // Color de fondo de la pantalla
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            color: Colors.black,
          ), // Estilo de texto para el cuerpo
          headlineMedium: TextStyle(
            color: Color(0xFFFFA726),
          ), // Estilo de texto para los encabezados
        ),
      ),
      home:
          const CSVUploader(), // Establece CSVUploader como la pantalla principal
    );
  }
}

// Widget Stateful para la carga de archivos CSV
class CSVUploader extends StatefulWidget {
  const CSVUploader({Key? key}) : super(key: key);

  @override
  CSVUploaderState createState() => CSVUploaderState();
}

// Estado del widget CSVUploader
class CSVUploaderState extends State<CSVUploader> {
  File? _selectedFile; // Archivo CSV seleccionado
  List<dynamic> allStudents = []; // Lista de todos los estudiantes
  List<dynamic> filteredStudents = []; // Lista de estudiantes filtrados
  bool _tableProjected = false; // Indica si la tabla se ha proyectado
  final TextEditingController _chatController =
      TextEditingController(); // Controlador del campo de chat
  String _chatResponse = ""; // Respuesta del chat

  // Función para seleccionar un archivo CSV
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

  // Función para subir el archivo CSV al servidor
  Future<void> uploadCSV() async {
    if (_selectedFile == null) return;

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://localhost:5000/upload'),
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
        _tableProjected = true;
      });
    }
  }

  // Función para construir la tabla de datos
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
            Container(
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
                  DataColumn(
                    label: Text(
                      "Análisis",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows:
                    data.map((row) {
                      String analysis =
                          row["PROMEDIO"] <= 7
                              ? "⚠️ Riesgo de deserción"
                              : "✅ Buen rendimiento";
                      return DataRow(
                        color: MaterialStateProperty.resolveWith<Color?>((
                          states,
                        ) {
                          return data.indexOf(row) % 2 == 0
                              ? Colors.grey.shade100
                              : Colors.white;
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
                                        : Colors.red,
                              ),
                            ),
                          ),
                          DataCell(Text(analysis)),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ],
        );
  }

  // Función para procesar las consultas del chat
  void handleChatQuery() {
    setState(() {
      String query = _chatController.text.toLowerCase();
      if (query.contains("promedio menor a 7")) {
        _chatResponse =
            "Hay ${filteredStudents.length} alumnos con promedio ≤ 7.";
      } else if (query.contains("riesgo de deserción")) {
        _chatResponse =
            "Hay ${filteredStudents.length} alumnos en riesgo de deserción.";
      } else if (query.contains("promedio mayor a 7")) {
        _chatResponse =
            "Hay ${allStudents.length - filteredStudents.length} alumnos con promedio > 7.";
      } else {
        _chatResponse =
            "No entiendo la consulta. Por favor, intenta con otra pregunta.";
      }
    });
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
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
              Text(
                'Este sistema permite predecir la deserción estudiantil basado en datos históricos. Puedes cargar un archivo CSV con información de los estudiantes para analizar su desempeño.',
                style: const TextStyle(fontSize: 16, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Sección de explicación de los botones
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Funcionalidad de los botones:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Seleccionar CSV: Permite elegir un archivo CSV desde tu dispositivo.',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Subir CSV: Sube el archivo CSV seleccionado al servidor para procesar los datos.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
                  const SizedBox(width: 20), // Espacio entre los botones
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: uploadCSV,
                        icon: const Icon(
                          Icons.cloud_upload,
                          color: Colors.white,
                        ),
                        label: const Text("Subir CSV"),
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: buildDataTable(
                  allStudents,
                  "Alumnos en General",
                  Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: buildDataTable(
                  filteredStudents,
                  "Alumnos en Riesgo",
                  Colors.red,
                ),
              ),
              const SizedBox(height: 40),
              Column(
                children: [
                  TextField(
                    controller: _chatController,
                    decoration: const InputDecoration(
                      hintText: "Haz una pregunta...",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.question_answer),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: handleChatQuery,
                    icon: const Icon(Icons.chat),
                    label: const Text("Enviar Pregunta"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA726),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _chatResponse,
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

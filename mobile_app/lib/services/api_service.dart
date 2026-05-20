import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:insights_ai_agent/services/app_config.dart';

class ApiService {
  final String baseUrl = AppConfig.baseUrl;

  /// Web-compatible upload using bytes from PlatformFile
  Future<Map<String, dynamic>> uploadPlatformFiles(
    List<PlatformFile> files,
    Function(double) onProgress,
  ) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/ingest'));

    for (var file in files) {
      if (file.bytes != null) {
        // Web: use bytes directly
        request.files.add(http.MultipartFile.fromBytes(
          'files',
          file.bytes!,
          filename: file.name,
        ));
      }
    }

    // Send and track progress via streamed response
    onProgress(0.1); // Show 10% immediately so UI reacts
    var streamedResponse = await request.send();
    onProgress(0.9); // Upload complete, waiting for analysis

    var response = await http.Response.fromStream(streamedResponse);
    onProgress(1.0);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Server Error ${response.statusCode}: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> analyzeUrl(String url) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ingest-url?url=${Uri.encodeComponent(url)}'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to analyze URL: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getCurrentState() async {
    final response = await http.get(Uri.parse('$baseUrl/state'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch state');
    }
  }

  Future<Map<String, dynamic>> simulateAction(String actionId, String details) async {
    final response = await http.post(
      Uri.parse('$baseUrl/simulate-action'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'action_id': actionId, 'action_details': details}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to execute action');
    }
  }

  Future<List<dynamic>> getCurrentTraces() async {
    final response = await http.get(Uri.parse('$baseUrl/traces'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch traces');
    }
  }

  Future<List<dynamic>> getFiles() async {
    final response = await http.get(Uri.parse('$baseUrl/files'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch files');
    }
  }

  Future<void> deleteFile(String name) async {
    final response = await http.delete(Uri.parse('$baseUrl/files/$name'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete file');
    }
  }
}

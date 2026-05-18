import 'package:flutter/material.dart';
import 'package:insights_ai_agent/services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AgentProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isUploadingFiles = false;
  bool _isProcessingUrl = false;
  double _uploadProgress = 0.0;
  
  Map<String, dynamic>? _lastResult;
  Map<String, dynamic>? _systemState;
  String _currentStatus = "Idle";
  
  String _pexelsApiKey = "";

  bool get isUploadingFiles => _isUploadingFiles;
  bool get isProcessingUrl => _isProcessingUrl;
  bool get isLoading => _isUploadingFiles || _isProcessingUrl;
  
  double get uploadProgress => _uploadProgress;
  Map<String, dynamic>? get lastResult => _lastResult;
  Map<String, dynamic>? get systemState => _systemState;
  String get pexelsApiKey => _pexelsApiKey;
  String get currentStatus => _currentStatus;

  void setPexelsApiKey(String key) {
    _pexelsApiKey = key;
    notifyListeners();
  }

  /// Upload files using PlatformFile (web-compatible — uses bytes, not paths)
  Future<void> processFiles(List<PlatformFile> files) async {
    _isUploadingFiles = true;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      _lastResult = await _apiService.uploadPlatformFiles(
        files,
        (progress) {
          _uploadProgress = progress;
          notifyListeners();
        },
      );
      await fetchState();
    } catch (e) {
      debugPrint("Error processing files: $e");
      _lastResult = {
        "report": {
          "main_feeds": [{"title": "Upload Error", "content": "Could not connect to the backend. Ensure it is running at http://localhost:8000"}],
          "risks": [],
          "actions": []
        }
      };
      notifyListeners();
    } finally {
      _isUploadingFiles = false;
      _uploadProgress = 1.0;
      notifyListeners();
    }
  }

  Future<void> processUrl(String url) async {
    _isProcessingUrl = true;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      _lastResult = await _apiService.analyzeUrl(url);
      await fetchState();
    } catch (e) {
      debugPrint("Error processing URL: $e");
      _lastResult = {
        "report": {
          "main_feeds": [{"title": "URL Error", "content": "Could not fetch data from the URL. Ensure the backend is running."}],
          "risks": [],
          "actions": []
        }
      };
      notifyListeners();
    } finally {
      _isProcessingUrl = false;
      notifyListeners();
    }
  }

  Future<void> fetchState() async {
    try {
      _systemState = await _apiService.getCurrentState();
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching state: $e");
    }
  }

  Future<Map<String, dynamic>?> runSimulation(String actionId, String details) async {
    _isProcessingUrl = true; // Use URL spinner or generic for simulation
    notifyListeners();

    try {
      final result = await _apiService.simulateAction(actionId, details);
      await fetchState();
      return result;
    } catch (e) {
      debugPrint("Error running simulation: $e");
      return null;
    } finally {
      _isProcessingUrl = false;
      notifyListeners();
    }
  }
  
  Future<String> fetchAdImage(String query) async {
    // Clean prompt to extract keywords
    final cleanPrompt = query.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
    final keywords = cleanPrompt.split(' ').take(3).join(' ');

    if (_pexelsApiKey.isEmpty) {
      // Fallback to loremflickr
      final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
      final urlKw = cleanPrompt.split(' ').take(2).join(',');
      return "https://loremflickr.com/800/500/business,marketing,$urlKw?lock=$uniqueId";
    }

    try {
      final response = await http.get(
        Uri.parse('https://api.pexels.com/v1/search?query=${Uri.encodeComponent(keywords)}&per_page=1'),
        headers: {'Authorization': _pexelsApiKey},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['photos'] != null && data['photos'].isNotEmpty) {
          return data['photos'][0]['src']['large'];
        }
      }
    } catch (e) {
      debugPrint("Pexels error: $e");
    }
    
    // Fallback if API fails or returns no photos
    final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
    return "https://loremflickr.com/800/500/business?lock=$uniqueId";
  }
}

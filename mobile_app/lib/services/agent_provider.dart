import 'package:flutter/material.dart';
import 'package:insights_ai_agent/services/api_service.dart';
import 'package:file_picker/file_picker.dart';

class AgentProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  double _uploadProgress = 0.0;
  Map<String, dynamic>? _lastResult;
  Map<String, dynamic>? _systemState;

  bool get isLoading => _isLoading;
  double get uploadProgress => _uploadProgress;
  Map<String, dynamic>? get lastResult => _lastResult;
  Map<String, dynamic>? get systemState => _systemState;

  /// Upload files using PlatformFile (web-compatible — uses bytes, not paths)
  Future<void> processFiles(List<PlatformFile> files) async {
    _isLoading = true;
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
      _isLoading = false;
      _uploadProgress = 1.0;
      notifyListeners();
    }
  }

  Future<void> processUrl(String url) async {
    _isLoading = true;
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
      _isLoading = false;
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
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.simulateAction(actionId, details);
      await fetchState();
      return result;
    } catch (e) {
      debugPrint("Error running simulation: $e");
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

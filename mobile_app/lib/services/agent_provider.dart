import 'package:flutter/material.dart';
import 'package:insights_ai_agent/services/api_service.dart';
import 'package:insights_ai_agent/services/app_config.dart';
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
  bool _autoMode = false;

  bool get isUploadingFiles => _isUploadingFiles;
  bool get isProcessingUrl => _isProcessingUrl;
  bool get isLoading => _isUploadingFiles || _isProcessingUrl;
  
  double get uploadProgress => _uploadProgress;
  Map<String, dynamic>? get lastResult => _lastResult;
  Map<String, dynamic>? get systemState => _systemState;
  String get pexelsApiKey => _pexelsApiKey;
  String get currentStatus => _currentStatus;
  bool get autoMode => _autoMode;

  Future<void> fetchConfig() async {
    try {
      final response = await http.get(Uri.parse('${AppConfig.baseUrl}/settings/config'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _pexelsApiKey = data['pexels_api_key'] ?? '';
        notifyListeners();
      }
    } catch (e) {
      debugPrint("fetchConfig error: $e");
    }
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
    final keywords = query.toLowerCase();
    
    // Curated high-fidelity business/finance images from Unsplash (100% reliable)
    final Map<String, String> curatedImages = {
      'tax': 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?auto=format&fit=crop&w=800&q=80',
      'audit': 'https://images.unsplash.com/photo-1526304640581-d334cdbbf45e?auto=format&fit=crop&w=800&q=80',
      'revenue': 'https://images.unsplash.com/photo-1591696205602-2f950c417cb9?auto=format&fit=crop&w=800&q=80',
      'cost': 'https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?auto=format&fit=crop&w=800&q=80',
      'finance': 'https://images.unsplash.com/photo-1559526324-4b87b5e36e44?auto=format&fit=crop&w=800&q=80',
      'marketing': 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?auto=format&fit=crop&w=800&q=80',
      'campaign': 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?auto=format&fit=crop&w=800&q=80',
    };

    if (_pexelsApiKey.isNotEmpty) {
      try {
        final cleanKw = query.replaceAll(RegExp(r'[^a-zA-Z0-9,\s]'), '').trim();
        final response = await http.get(
          Uri.parse('https://api.pexels.com/v1/search?query=${Uri.encodeComponent(cleanKw)}&per_page=1'),
          headers: {'Authorization': _pexelsApiKey},
        ).timeout(const Duration(seconds: 4));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['photos'] != null && data['photos'].isNotEmpty) {
            return data['photos'][0]['src']['large'];
          }
        }
      } catch (e) {
        debugPrint("Pexels error: $e");
      }
    }
    
    // Fallback matching logic: look for matching keys
    for (var entry in curatedImages.entries) {
      if (keywords.contains(entry.key)) {
        return entry.value;
      }
    }
    // Final default beautiful finance/business image
    return 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?auto=format&fit=crop&w=800&q=80';
  }

  // --- Settings & Auto Mode Methods ---

  Future<void> fetchAutoMode() async {
    try {
      final response = await http.get(Uri.parse('${AppConfig.baseUrl}/settings/automode'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _autoMode = data['auto_mode'] ?? false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("fetchAutoMode error: $e");
    }
  }

  Future<void> toggleAutoMode(bool active) async {
    try {
      await http.post(
        Uri.parse('${AppConfig.baseUrl}/settings/automode'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"active": active}),
      );
      _autoMode = active;
      notifyListeners();
    } catch (e) {
      debugPrint("toggleAutoMode error: $e");
    }
  }

  Future<void> updateSmtp(String host, int port, String user, String pass) async {
    try {
      await http.post(
        Uri.parse('${AppConfig.baseUrl}/settings/smtp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"host": host, "port": port, "username": user, "password": pass}),
      );
      await fetchState();
    } catch (e) {
      debugPrint("updateSmtp error: $e");
    }
  }

  Future<void> updateRecipients(List<String> emails) async {
    try {
      await http.post(
        Uri.parse('${AppConfig.baseUrl}/settings/recipients'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"items": emails}),
      );
      await fetchState();
    } catch (e) {
      debugPrint("updateRecipients error: $e");
    }
  }

  Future<void> updateWebSources(List<String> sources) async {
    try {
      await http.post(
        Uri.parse('${AppConfig.baseUrl}/settings/sources'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"items": sources}),
      );
      await fetchState();
    } catch (e) {
      debugPrint("updateWebSources error: $e");
    }
  }
}

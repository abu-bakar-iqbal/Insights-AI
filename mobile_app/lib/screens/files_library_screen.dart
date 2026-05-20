import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:insights_ai_agent/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class FilesLibraryScreen extends StatefulWidget {
  const FilesLibraryScreen({super.key});

  @override
  State<FilesLibraryScreen> createState() => _FilesLibraryScreenState();
}

class _FilesLibraryScreenState extends State<FilesLibraryScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    try {
      final files = await _api.getFiles();
      setState(() {
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load files: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _deleteFile(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Delete File", style: TextStyle(color: Colors.white)),
        content: Text("Are you sure you want to delete \"$name\"?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _api.deleteFile(name);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$name deleted"), backgroundColor: const Color(0xFF00A67E)),
        );
        _loadFiles(); // Refresh list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _openFile(String name) {
    final url = '${_api.baseUrl}/files/$name/download';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  IconData _fileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'docx':
      case 'doc':
        return Icons.article;
      case 'txt':
        return Icons.text_snippet;
      case 'xlsx':
      case 'csv':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _fileColor(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Colors.redAccent;
      case 'docx':
      case 'doc':
        return Colors.blueAccent;
      case 'txt':
        return Colors.white70;
      default:
        return const Color(0xFF00A67E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Files Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A67E)))
          : _files.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      const Text("No documents uploaded yet.", style: TextStyle(color: Colors.white38)),
                      const SizedBox(height: 8),
                      const Text("Upload files from the Dashboard to see them here.", style: TextStyle(color: Colors.white24, fontSize: 12)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFiles,
                  color: const Color(0xFF00A67E),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _files.length,
                    itemBuilder: (context, index) {
                      final file = _files[index];
                      final name = file['name'] ?? 'Unknown';
                      final sizeKb = file['size_kb'] ?? 0;
                      final dateMs = file['date'] ?? 0;
                      final date = DateTime.fromMillisecondsSinceEpoch((dateMs * 1000).toInt());
                      final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);

                      return FadeInUp(
                        delay: Duration(milliseconds: index * 80),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: _fileColor(name).withOpacity(0.15),
                              child: Icon(_fileIcon(name), color: _fileColor(name), size: 22),
                            ),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text("$sizeKb KB  •  $formattedDate", style: const TextStyle(fontSize: 11, color: Colors.white38)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.open_in_new, size: 18, color: Color(0xFF00A67E)),
                                  onPressed: () => _openFile(name),
                                  tooltip: "Open",
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                  onPressed: () => _deleteFile(name),
                                  tooltip: "Delete",
                                ),
                              ],
                            ),
                            onTap: () => _openFile(name),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

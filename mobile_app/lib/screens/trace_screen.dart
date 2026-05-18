import 'package:flutter/material.dart';
import 'package:insights_ai_agent/services/api_service.dart';
import 'package:insights_ai_agent/widgets/app_drawer.dart';

class TraceScreen extends StatefulWidget {
  const TraceScreen({super.key});

  @override
  State<TraceScreen> createState() => _TraceScreenState();
}

class _TraceScreenState extends State<TraceScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _traces = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTraces();
  }

  Future<void> _loadTraces() async {
    try {
      final traces = await _apiService.getCurrentTraces(); // Need to add to ApiService
      setState(() {
        _traces = traces;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agent Reasoning Traces')),
      drawer: const AppDrawer(),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _traces.length,
            itemBuilder: (context, index) {
              final trace = _traces[index];
              return _buildTraceTile(trace);
            },
          ),
    );
  }

  Widget _buildTraceTile(Map<String, dynamic> trace) {
    return ExpansionTile(
      title: Text("Trace: ${trace['trace_id']}"),
      subtitle: Text("${trace['total_steps']} steps recorded"),
      children: [
        for (var step in trace['steps'])
          ListTile(
            title: Text("${step['agent']} -> ${step['step']}"),
            subtitle: Text(step['timestamp'], style: const TextStyle(fontSize: 10)),
            trailing: const Icon(Icons.code, size: 16),
            onTap: () => _showStepDetails(context, step),
          )
      ],
    );
  }

  void _showStepDetails(BuildContext context, Map<String, dynamic> step) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.7,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${step['agent']}: ${step['step']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              const Text("INPUT", style: TextStyle(color: Colors.white38, fontSize: 12)),
              _codeSnippet(step['input']),
              const SizedBox(height: 20),
              const Text("OUTPUT / REASONING", style: TextStyle(color: Colors.white38, fontSize: 12)),
              _codeSnippet(step['output']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _codeSnippet(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'Courier', fontSize: 12, color: Colors.greenAccent),
      ),
    );
  }
}

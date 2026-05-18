import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:async';

class SimulationScreen extends StatefulWidget {
  final Map<String, dynamic> actionData;

  const SimulationScreen({super.key, required this.actionData});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  List<String> _visibleLogs = [];
  int _logIndex = 0;
  Timer? _timer;
  bool _isSimulating = true;

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  void _startSimulation() {
    final logs = widget.actionData['execution_logs'] as List? ?? [];
    if (logs.isEmpty) {
      setState(() => _isSimulating = false);
      return;
    }

    _timer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (_logIndex < logs.length) {
        setState(() {
          _visibleLogs.add(logs[_logIndex].toString());
          _logIndex++;
        });
      } else {
        timer.cancel();
        setState(() {
          _isSimulating = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.actionData;
    final beforeState = data['before_state'] as Map? ?? {};
    final afterState = data['after_state'] as Map? ?? {};
    final visualization = data['visualization'] as Map? ?? {};
    final actionTaken = data['action_taken'] ?? 'Unknown Action';

    return Scaffold(
      appBar: AppBar(title: const Text('Action Simulation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Digital Twin: Impact Simulation',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Action: $actionTaken",
              style: const TextStyle(fontSize: 14, color: Colors.blueAccent),
            ),
            const SizedBox(height: 24),
            
            // Console
            _buildActionConsole(),
            
            const SizedBox(height: 32),
            
            if (!_isSimulating) ...[
              FadeInDown(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A67E).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF00A67E)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF00A67E)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          visualization['message'] ?? 'Action executed successfully.',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Before / After State
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildStateColumn("BEFORE STATE", beforeState, Colors.white60)),
                const SizedBox(width: 16),
                const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 24),
                const SizedBox(width: 16),
                Expanded(child: _buildStateColumn("AFTER (Projected)", afterState, const Color(0xFF00A67E))),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStateColumn(String label, Map stateData, Color color) {
    if (stateData.isEmpty) {
      return Column(
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 16),
          const Text("No data provided.", style: TextStyle(color: Colors.white24)),
        ],
      );
    }

    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 16),
        ...stateData.entries.map((e) => _metricTile(e.key.toString(), e.value.toString(), color)),
      ],
    );
  }

  Widget _metricTile(String key, String value, Color color) {
    // Make key readable (e.g. "monthly_revenue" -> "Monthly Revenue")
    String readableKey = key.replaceAll('_', ' ');
    readableKey = readableKey.split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '').join(' ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(readableKey, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
        ],
      ),
    );
  }

  Widget _buildActionConsole() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal, color: Colors.white38, size: 16),
              const SizedBox(width: 8),
              const Text("SYSTEM SIMULATION TERMINAL", style: TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'Courier')),
              const Spacer(),
              if (_isSimulating)
                const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent))
              else
                const Text("DONE", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontFamily: 'Courier')),
            ],
          ),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          if (_visibleLogs.isEmpty && _isSimulating)
            const Text("> Initializing agent workflow...", style: TextStyle(fontFamily: 'Courier', color: Colors.white54, fontSize: 12)),
          ..._visibleLogs.map((log) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text("> $log", style: const TextStyle(fontFamily: 'Courier', color: Colors.greenAccent, fontSize: 12)),
              )),
        ],
      ),
    );
  }
}

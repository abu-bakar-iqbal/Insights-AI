import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:insights_ai_agent/services/agent_provider.dart';
import 'package:insights_ai_agent/screens/simulation_screen.dart';
import 'package:insights_ai_agent/widgets/app_drawer.dart';

class SimulationHistoryScreen extends StatelessWidget {
  const SimulationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final agent = Provider.of<AgentProvider>(context);
    final history = agent.systemState?['recent_actions'] as List? ?? [];
    
    // Filter history to only show ones that have 'before_state' (simulations)
    final simHistory = history.where((action) {
      final result = action['result'];
      return result is Map && result.containsKey('before_state');
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Simulation History')),
      drawer: const AppDrawer(),
      body: simHistory.isEmpty
          ? const Center(child: Text("No simulation history found.", style: TextStyle(color: Colors.white38)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: simHistory.length,
              itemBuilder: (context, index) {
                // Reverse list to show newest first
                final action = simHistory[simHistory.length - 1 - index];
                final result = action['result'] as Map<String, dynamic>;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: const Color(0xFF1E293B),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF00A67E),
                      child: Icon(Icons.hub, color: Colors.white, size: 20),
                    ),
                    title: Text(result['action_taken'] ?? action['action'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(action['timestamp']?.split('.')[0] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SimulationScreen(actionData: result)),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

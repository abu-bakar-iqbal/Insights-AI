import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:insights_ai_agent/services/agent_provider.dart';
import 'package:insights_ai_agent/screens/result_screen.dart';
import 'package:insights_ai_agent/screens/trace_screen.dart';
import 'package:insights_ai_agent/screens/files_library_screen.dart';
import 'package:insights_ai_agent/screens/simulation_history_screen.dart';
import 'package:insights_ai_agent/widgets/app_drawer.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Use PlatformFile (web-safe — carries bytes, not just path)
  final List<PlatformFile> _stagedFiles = [];
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AgentProvider>(context, listen: false).fetchState();
    });
  }

  @override
  Widget build(BuildContext context) {
    final agent = Provider.of<AgentProvider>(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Insights AI Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            FadeInDown(child: _buildMetricOverview(agent)),
            const SizedBox(height: 24),
            FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: _buildImpactChart(agent)),
            const SizedBox(height: 30),

            // SECTION 1: DOCUMENT UPLOAD
            const Text('Document Analysis',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildUploadCard(),
            if (_stagedFiles.isNotEmpty) _buildStagingArea(agent),

            const SizedBox(height: 30),

            // SECTION 2: WEB ANALYSIS
            const Text('Web Intelligence',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildUrlInput(agent),

            const SizedBox(height: 30),
            const Text('Recent History',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildRecentHistory(agent),
            const SizedBox(height: 40),
            const Divider(color: Colors.white10),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Insights AI Platform v2.0", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      const Text("•", style: TextStyle(color: Colors.white24)),
                      const SizedBox(width: 16),
                      TextButton(onPressed: (){}, child: const Text("Privacy", style: TextStyle(color: Colors.blueAccent, fontSize: 12))),
                      TextButton(onPressed: (){}, child: const Text("Terms", style: TextStyle(color: Colors.blueAccent, fontSize: 12))),
                      TextButton(onPressed: (){}, child: const Text("Support", style: TextStyle(color: Colors.blueAccent, fontSize: 12))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text("© 2026 Executive Intelligence Systems. All rights reserved.", style: TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─── Metric Overview ────────────────────────────────────────────────────────
  Widget _buildMetricOverview(AgentProvider agent) {
    final metrics = agent.systemState?['metrics'] ?? {};
    final actions = agent.systemState?['recent_actions'] as List? ?? [];
    final lastSource = actions.isNotEmpty ? (actions.last['action'] ?? '') : 'No data analyzed yet';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _metricItem('Revenue', '${metrics['monthly_revenue_pkr'] ?? '0'}',
                Colors.greenAccent),
            const SizedBox(width: 12),
            _metricItem('Costs', '${metrics['operating_costs_pkr'] ?? '0'}',
                Colors.orangeAccent),
            const SizedBox(width: 12),
            _metricItem('Compliance', '${metrics['compliance_score'] ?? '0'}%',
                Colors.blueAccent),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.source, size: 14, color: Color(0xFF00A67E)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Source: $lastSource',
                  style: const TextStyle(fontSize: 11, color: Colors.white38),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 4),
            FittedBox(
                child: Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  // ─── Trend Chart ─────────────────────────────────────────────────────────────
  Widget _buildImpactChart(AgentProvider agent) {
    final metrics = agent.systemState?['metrics'] ?? {};
    final List<dynamic> rawTrend = metrics['efficiency_trend'] ?? [3, 4, 3.5, 5, 4.5, 6];
    
    // Convert to double list and ensure 6 spots
    List<double> trend = rawTrend.map((e) => double.tryParse(e.toString()) ?? 0.0).toList();
    if (trend.isEmpty) trend = [3, 4, 3.5, 5, 4.5, 6];

    final spots = List.generate(
      trend.length,
      (index) => FlSpot(index.toDouble(), trend[index]),
    );

    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Efficiency Trend',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF00A67E),
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF00A67E).withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Upload Card ──────────────────────────────────────────────────────────────
  Widget _buildUploadCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.custom,
          allowedExtensions: ['pdf', 'txt', 'docx'],
          withData: true, // ← KEY: loads bytes for web
        );
        if (result != null) {
          setState(() {
            // Only add files that have bytes (web uploads always do)
            final valid = result.files.where((f) => f.bytes != null).toList();
            _stagedFiles.addAll(valid);
          });
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: const Color(0xFF00A67E).withOpacity(0.5),
              style: BorderStyle.solid),
        ),
        child: const Column(
          children: [
            Icon(Icons.cloud_upload_outlined,
                size: 40, color: Color(0xFF00A67E)),
            SizedBox(height: 8),
            Text('Select Data Files',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('PDFs, Word or Text documents',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ─── Staging Area (files selected but not yet sent) ──────────────────────────
  Widget _buildStagingArea(AgentProvider agent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        ..._stagedFiles.map(
          (file) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              dense: true,
              leading:
                  const Icon(Icons.insert_drive_file, color: Colors.white70),
              title: Text(file.name,
                  style: const TextStyle(fontSize: 13)),
              subtitle: Text(
                  '${((file.size) / 1024).toStringAsFixed(1)} KB',
                  style: const TextStyle(fontSize: 11, color: Colors.white38)),
              trailing: IconButton(
                icon:
                    const Icon(Icons.close, size: 18, color: Colors.redAccent),
                onPressed: () => setState(() => _stagedFiles.remove(file)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (agent.isUploadingFiles)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Uploading & Analyzing...',
                  style: TextStyle(fontSize: 12, color: Colors.white70)),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: agent.uploadProgress,
                backgroundColor: Colors.white10,
                color: const Color(0xFF00A67E),
              ),
              const SizedBox(height: 4),
              Text('${(agent.uploadProgress * 100).toInt()}% transmitted',
                  style:
                      const TextStyle(fontSize: 10, color: Colors.white38)),
              const SizedBox(height: 12),
            ],
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: agent.isUploadingFiles
                ? null
                : () async {
                    await agent.processFiles(_stagedFiles);
                    setState(() => _stagedFiles.clear());
                    if (mounted) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ResultScreen()));
                    }
                  },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A67E),
                padding: const EdgeInsets.symmetric(vertical: 14)),
            icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            label: const Text('Analyze All Files',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // ─── URL Input ────────────────────────────────────────────────────────────────
  Widget _buildUrlInput(AgentProvider agent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _urlController,
            enabled: !agent.isProcessingUrl,
            decoration: InputDecoration(
              hintText: agent.isProcessingUrl ? 'Analyzing...' : 'Paste any website or news link...',
              prefixIcon: Icon(Icons.link, color: agent.isProcessingUrl ? Colors.white24 : const Color(0xFF00A67E)),
              border: InputBorder.none,
            ),
          ),
          if (agent.isProcessingUrl) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(
              backgroundColor: Colors.white10,
              color: Color(0xFF00A67E),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00A67E))),
                SizedBox(width: 10),
                Text('Scraping & analyzing link...', style: TextStyle(fontSize: 12, color: Colors.white54)),
              ],
            ),
          ],
          if (!agent.isProcessingUrl) ...[
            const Divider(color: Colors.white10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  final url = _urlController.text.trim();
                  if (url.isNotEmpty) {
                    await agent.processUrl(url);
                    _urlController.clear();
                    if (mounted) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ResultScreen()));
                    }
                  }
                },
                icon: const Icon(Icons.travel_explore, size: 18),
                label: const Text('Analyze Link'),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF00A67E)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Recent History ──────────────────────────────────────────────────────────
  Widget _buildRecentHistory(AgentProvider agent) {
    final actions = agent.systemState?['recent_actions'] as List? ?? [];
    if (actions.isEmpty) {
      return const Center(
          child: Text('No history yet — analyze a document to begin.',
              style: TextStyle(color: Colors.white38, fontSize: 12)));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length > 5 ? 5 : actions.length,
      itemBuilder: (context, index) {
        final action = actions[actions.length - 1 - index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF00A67E),
              radius: 16,
              child: Icon(Icons.description, size: 16, color: Colors.white),
            ),
            title: Text(action['action'] ?? 'Analysis Run',
                style: const TextStyle(fontSize: 13)),
            subtitle: Text(action['timestamp']?.split('.')[0] ?? '',
                style:
                    const TextStyle(fontSize: 11, color: Colors.white38)),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ResultScreen())),
          ),
        );
      },
    );
  }
}

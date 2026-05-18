import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:insights_ai_agent/services/agent_provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:insights_ai_agent/screens/simulation_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final agent = Provider.of<AgentProvider>(context);
    final report = agent.lastResult?['report'] ?? {};
    final feeds = report['main_feeds'] as List? ?? [];
    final risks = report['risks'] as List? ?? [];
    final actions = report['actions'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Strategic Intelligence Report')),
      body: agent.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF00A67E)),
                  const SizedBox(height: 20),
                  const Text("Generating Strategic Intelligence...", style: TextStyle(color: Colors.white70)),
                  Text("${(agent.uploadProgress * 100).toInt()}% Transmitted", style: const TextStyle(fontSize: 12, color: Colors.white38)),
                ],
              ),
            )
          : report.isEmpty
              ? const Center(child: Text("No analysis results found. Please upload data."))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(child: _buildSectionHeader("Critical Feeds", Icons.rss_feed)),
            const SizedBox(height: 12),
            ...feeds.map((f) => _buildFeedCard(f)),
            
            const SizedBox(height: 30),
            FadeInDown(delay: const Duration(milliseconds: 200), child: _buildSectionHeader("Risk Assessment", Icons.warning_amber_rounded)),
            const SizedBox(height: 12),
            ...risks.map((r) => _buildRiskCard(r)),

            const SizedBox(height: 30),
            FadeInDown(delay: const Duration(milliseconds: 400), child: _buildSectionHeader("Execution Plan", Icons.play_circle_outline)),
            const SizedBox(height: 12),
            ...actions.map((a) => _buildActionCard(context, a, agent)),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00A67E), size: 24),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFeedCard(dynamic feed) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(feed['title'] ?? 'Update', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(feed['content'] ?? ''),
      ),
    );
  }

  Widget _buildRiskCard(dynamic risk) {
    final severity = risk['severity'] ?? 'Medium';
    final Color severityColor = severity.toString().toLowerCase() == 'high' 
        ? Colors.redAccent 
        : (severity.toString().toLowerCase() == 'medium' ? Colors.orangeAccent : Colors.blueAccent);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: severityColor.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: severityColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            risk['title'] ?? 'Strategic Risk',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        _severityBadge(severity, severityColor),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(risk['impact_description'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: severityColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.account_balance_wallet_outlined, size: 14, color: severityColor),
                          const SizedBox(width: 8),
                          Text(
                            "Potential Impact: ${risk['pkr_risk_value'] ?? 'Calculated'}",
                            style: TextStyle(color: severityColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _severityBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, dynamic action, AgentProvider agent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(action['title'] ?? 'Action', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00A67E))),
            const SizedBox(height: 8),
            Text(action['details'] ?? '', style: const TextStyle(fontSize: 14, color: Colors.white70)),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.trending_up, size: 16, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Expanded(child: Text("Projected Impact: ${action['projected_impact'] ?? 'PKR — (Pending)'}", style: const TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.w600))),
                ElevatedButton(
                  onPressed: agent.isLoading ? null : () async {
                    final res = await agent.runSimulation(action['id'] ?? 'A1', action['details'] ?? '');
                    if (context.mounted && res != null && res['result'] != null) {
                      final data = res['result'];
                      if (data['is_advertisement'] == true) {
                        _showAdReviewDialog(context, data);
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => SimulationScreen(actionData: data)));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A67E), minimumSize: const Size(80, 32)),
                  child: const Text('Execute', style: TextStyle(fontSize: 12, color: Colors.white)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showAdReviewDialog(BuildContext context, Map<String, dynamic> data) {
    final adCopy = data['ad_copy'] ?? 'Check out our new offer!';
    final prompt = data['ad_image_prompt'] ?? 'Modern marketing concept';
    
    // Extract a few keywords from the prompt for the stock image
    final cleanPrompt = prompt.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
    final keywords = cleanPrompt.split(' ').take(2).join(',');
    final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
    final imageUrl = "https://loremflickr.com/800/500/business,marketing,$keywords?lock=$uniqueId";

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.network(
                  imageUrl,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    height: 250,
                    color: Colors.white10,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.broken_image, size: 50, color: Colors.white38),
                        const SizedBox(height: 8),
                        Text("Image unavailable", style: TextStyle(color: Colors.white38, fontSize: 12)),
                      ]
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.campaign, color: Color(0xFF00A67E)),
                        const SizedBox(width: 8),
                        const Text("Campaign Generated", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.white54),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: adCopy));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Ad description copied to clipboard!"), backgroundColor: Color(0xFF00A67E)),
                            );
                          },
                          tooltip: "Copy Description",
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                      child: Text(adCopy, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A67E), padding: const EdgeInsets.symmetric(vertical: 16)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showSocialOptions(context, adCopy, imageUrl);
                        },
                        child: const Text("Proceed to Publish", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showSocialOptions(BuildContext context, String text, String imageUrl) {
    void _copyAndLaunch(String url, String platformName) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ad copy copied to clipboard! Paste it in $platformName."),
          backgroundColor: const Color(0xFF00A67E),
          duration: const Duration(seconds: 4),
        ),
      );
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      Navigator.pop(context);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Publish to Socials", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _socialButton(Icons.facebook, "Facebook", Colors.blue, () {
              final url = 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(imageUrl)}';
              _copyAndLaunch(url, "Facebook");
            }),
            const SizedBox(height: 12),
            _socialButton(Icons.camera_alt, "Instagram", Colors.purpleAccent, () {
              _copyAndLaunch('https://instagram.com', "Instagram");
            }),
            const SizedBox(height: 12),
            _socialButton(Icons.alternate_email, "X (Twitter)", Colors.white, () {
              final url = 'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(text)}&url=${Uri.encodeComponent(imageUrl)}';
              _copyAndLaunch(url, "Twitter");
            }, iconColor: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _socialButton(IconData icon, String title, Color bgColor, VoidCallback onTap, {Color iconColor = Colors.white}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: bgColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: bgColor.withOpacity(0.5))),
        child: Row(
          children: [
            Icon(icon, color: bgColor == Colors.white ? Colors.white : bgColor),
            const SizedBox(width: 16),
            Text("Share on $title", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            const Spacer(),
            const Icon(Icons.open_in_new, size: 16, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

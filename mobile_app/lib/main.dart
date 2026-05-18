import 'package:flutter/material.dart';
import 'package:insights_ai_agent/widgets/theme.dart';
import 'package:insights_ai_agent/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:insights_ai_agent/services/agent_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AgentProvider()),
      ],
      child: const InsightsAIApp(),
    ),
  );
}

class InsightsAIApp extends StatelessWidget {
  const InsightsAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Insights AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}

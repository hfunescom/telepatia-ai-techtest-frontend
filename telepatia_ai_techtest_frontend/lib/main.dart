import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/pipeline_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const TelepatiaApp());
}

class TelepatiaApp extends StatelessWidget {
  const TelepatiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Using the local backend for now. For production:
        // ChangeNotifierProvider(create: (_) => PipelineProvider.prod("<your-project-id>")),
        ChangeNotifierProvider(create: (_) => PipelineProvider.local()),
      ],
      child: MaterialApp(
        title: 'Telepatía AI',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'screens/search_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FanucApp());
}

class FanucApp extends StatelessWidget {
  const FanucApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fanuc Alarms',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const SearchScreen(),
    );
  }
}

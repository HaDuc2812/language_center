import 'package:flutter/material.dart';

import '../features/auth/view/auth_gate.dart';

class LanguageCenterApp extends StatelessWidget {
  const LanguageCenterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Language Center',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

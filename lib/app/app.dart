import 'package:flutter/material.dart';

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
      home: Scaffold(
        appBar: AppBar(title: const Text('Language Center')),
        body: const Center(
          child: Text(
            'Ứng dụng đã khởi tạo Firebase.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

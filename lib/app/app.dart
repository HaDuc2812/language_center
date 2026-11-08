import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/preferences_provider.dart';
import '../features/auth/view/auth_gate.dart';

class LanguageCenterApp extends ConsumerWidget {
  const LanguageCenterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(appPreferencesProvider).asData?.value;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Language Center',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: preferences?.darkMode == true
          ? ThemeMode.dark
          : ThemeMode.light,
      home: const AuthGate(),
    );
  }
}

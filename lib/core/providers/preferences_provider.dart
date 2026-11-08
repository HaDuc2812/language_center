import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (_) async => SharedPreferences.getInstance(),
);

const _rememberEmailKey = 'remember_email';
const _savedEmailKey = 'saved_email';
const _darkModeKey = 'dark_mode';

Future<void> setRememberEmailPreference(WidgetRef ref, {required bool remember}) async {
  final prefs = await ref.read(sharedPreferencesProvider.future);
  await prefs.setBool(_rememberEmailKey, remember);
}

Future<bool> getRememberEmailPreference(WidgetRef ref) async {
  final prefs = await ref.read(sharedPreferencesProvider.future);
  return prefs.getBool(_rememberEmailKey) ?? false;
}

Future<void> saveLastSignedInEmail(WidgetRef ref, String email) async {
  final prefs = await ref.read(sharedPreferencesProvider.future);
  await prefs.setString(_savedEmailKey, email.trim());
}

Future<String> getLastSignedInEmail(WidgetRef ref) async {
  final prefs = await ref.read(sharedPreferencesProvider.future);
  return prefs.getString(_savedEmailKey) ?? '';
}

Future<void> clearSavedEmail(WidgetRef ref) async {
  final prefs = await ref.read(sharedPreferencesProvider.future);
  await prefs.remove(_savedEmailKey);
}

Future<void> setDarkModePreference(WidgetRef ref, {required bool enabled}) async {
  final prefs = await ref.read(sharedPreferencesProvider.future);
  await prefs.setBool(_darkModeKey, enabled);
}

Future<bool> getDarkModePreference(WidgetRef ref) async {
  final prefs = await ref.read(sharedPreferencesProvider.future);
  return prefs.getBool(_darkModeKey) ?? false;
}

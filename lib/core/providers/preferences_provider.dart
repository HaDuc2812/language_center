import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (_) async => SharedPreferences.getInstance(),
);

const _rememberEmailKey = 'remember_email';
const _savedEmailKey = 'saved_email';
const _darkModeKey = 'dark_mode';
const _authNotificationsKey = 'auth_notifications_enabled';

class AppPreferences {
  const AppPreferences({
    required this.rememberEmail,
    required this.savedEmail,
    required this.darkMode,
    required this.authNotificationsEnabled,
  });

  final bool rememberEmail;
  final String savedEmail;
  final bool darkMode;
  final bool authNotificationsEnabled;
}

final appPreferencesProvider = FutureProvider<AppPreferences>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return AppPreferences(
    rememberEmail: prefs.getBool(_rememberEmailKey) ?? false,
    savedEmail: prefs.getString(_savedEmailKey) ?? '',
    darkMode: prefs.getBool(_darkModeKey) ?? false,
    authNotificationsEnabled: prefs.getBool(_authNotificationsKey) ?? true,
  );
});

Future<void> setRememberEmailPreference(
  WidgetRef ref, {
  required bool remember,
}) async {
  final prefs = await ref.read(sharedPreferencesProvider.future);
  await prefs.setBool(_rememberEmailKey, remember);
  ref.invalidate(appPreferencesProvider);
}

Future<bool> getRememberEmailPreference(WidgetRef ref) async {
  final prefs = await ref.read(sharedPreferencesProvider.future);
  return prefs.getBool(_rememberEmailKey) ?? false;
}

Future<void> saveLastSignedInEmail(WidgetRef ref, String email) async {
  final prefs = await ref.read(sharedPreferencesProvider.future);
  await prefs.setString(_savedEmailKey, email.trim());
  ref.invalidate(appPreferencesProvider);
}

Future<String> getLastSignedInEmail(WidgetRef ref) async {
  final prefs = await ref.read(sharedPreferencesProvider.future);
  return prefs.getString(_savedEmailKey) ?? '';
}

Future<void> clearSavedEmail(WidgetRef ref) async {
  final prefs = await ref.read(sharedPreferencesProvider.future);
  await prefs.remove(_savedEmailKey);
  ref.invalidate(appPreferencesProvider);
}

Future<void> setDarkModePreference(
  WidgetRef ref, {
  required bool enabled,
}) async {
  final prefs = await ref.read(sharedPreferencesProvider.future);
  await prefs.setBool(_darkModeKey, enabled);
  ref.invalidate(appPreferencesProvider);
}

Future<bool> getDarkModePreference(WidgetRef ref) async {
  final prefs = await ref.read(sharedPreferencesProvider.future);
  return prefs.getBool(_darkModeKey) ?? false;
}

Future<void> setAuthNotificationsPreference(
  WidgetRef ref, {
  required bool enabled,
}) async {
  final prefs = await ref.read(sharedPreferencesProvider.future);
  await prefs.setBool(_authNotificationsKey, enabled);
  ref.invalidate(appPreferencesProvider);
}

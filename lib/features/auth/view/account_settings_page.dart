import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/preferences_provider.dart';

class AccountSettingsPage extends ConsumerWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(appPreferencesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt tài khoản')),
      body: preferences.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Không tải được cài đặt: $error'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(appPreferencesProvider),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (settings) => ListView(
          children: [
            const ListTile(
              title: Text('Cài đặt ứng dụng'),
              subtitle: Text('Các tùy chọn được lưu trên thiết bị này.'),
            ),
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Chế độ tối'),
              subtitle: const Text('Áp dụng giao diện tối cho ứng dụng.'),
              value: settings.darkMode,
              onChanged: (enabled) => _save(
                context,
                () => setDarkModePreference(ref, enabled: enabled),
              ),
            ),
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.alternate_email),
              title: const Text('Ghi nhớ email đăng nhập'),
              subtitle: const Text('Không lưu mật khẩu trên thiết bị.'),
              value: settings.rememberEmail,
              onChanged: (enabled) => _save(context, () async {
                await setRememberEmailPreference(ref, remember: enabled);
                if (!enabled) await clearSavedEmail(ref);
              }),
            ),
            SwitchListTile.adaptive(
              secondary: const Icon(Icons.notifications_outlined),
              title: const Text('Thông báo sự kiện tài khoản'),
              subtitle: const Text(
                'Hiện thông báo trong ứng dụng khi đặt lại hoặc đổi mật khẩu.',
              ),
              value: settings.authNotificationsEnabled,
              onChanged: (enabled) => _save(
                context,
                () => setAuthNotificationsPreference(ref, enabled: enabled),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context, Future<void> Function() save) async {
    try {
      await save();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể lưu cài đặt: $error')));
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/preferences_provider.dart';

void showAuthEventNotification(
  BuildContext context,
  WidgetRef ref,
  String message,
) {
  final enabled =
      ref.read(appPreferencesProvider).asData?.value.authNotificationsEnabled ??
      true;
  if (!enabled || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

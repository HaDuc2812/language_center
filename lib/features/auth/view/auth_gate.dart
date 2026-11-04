import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../learning_process/view/learning_process_home.dart';
import '../view_model/auth_view_model.dart';
import 'login_page.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    return session.when(
      loading: () => const _LoadingPage(),
      error: (error, stackTrace) => _ErrorPage(
        message: 'Không thể kiểm tra phiên đăng nhập.',
        onRetry: () => ref.invalidate(authSessionProvider),
      ),
      data: (user) {
        if (user == null) return const LoginPage();
        ref.listen(authorizedProfileProvider(user.uid), (previous, next) {
          final previouslyAuthorized = previous?.asData?.value != null;
          final accessRevoked =
              next.hasError || (next.hasValue && next.value == null);
          if (previouslyAuthorized && accessRevoked) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).popUntil((route) => route.isFirst);
              }
            });
          }
        });
        final profile = ref.watch(authorizedProfileProvider(user.uid));
        return profile.when(
          loading: () => const _LoadingPage(),
          error: (error, stackTrace) => _ErrorPage(
            message:
                'Không thể xác minh quyền truy cập. Kiểm tra mạng và quyền đọc hồ sơ.',
            onRetry: () => ref.invalidate(authorizedProfileProvider(user.uid)),
            onSignOut: () => ref.read(firebaseAuthProvider).signOut(),
          ),
          data: (authorized) {
            if (authorized == null) {
              return _ErrorPage(
                message:
                    'Tài khoản không có quyền truy cập. Cần hồ sơ admin/staff đang hoạt động.',
                onRetry: () =>
                    ref.invalidate(authorizedProfileProvider(user.uid)),
                onSignOut: () => ref.read(firebaseAuthProvider).signOut(),
              );
            }
            return LearningProcessHome(profile: authorized);
          },
        );
      },
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _ErrorPage extends StatelessWidget {
  const _ErrorPage({
    required this.message,
    required this.onRetry,
    this.onSignOut,
  });

  final String message;
  final VoidCallback onRetry;
  final Future<void> Function()? onSignOut;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
            if (onSignOut != null)
              TextButton(
                onPressed: () => onSignOut!(),
                child: const Text('Đăng xuất'),
              ),
          ],
        ),
      ),
    ),
  );
}

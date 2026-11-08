import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_model/auth_view_model.dart';
import 'auth_event_notification.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({this.initialEmail = '', super.key});

  final String initialEmail;

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _sending = false;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quên mật khẩu')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.mark_email_unread_outlined, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          _emailSent
                              ? 'Kiểm tra email của bạn'
                              : 'Đặt lại mật khẩu',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _emailSent
                              ? 'Nếu email được đăng ký, Firebase sẽ gửi hướng dẫn đặt lại mật khẩu đến ${_emailController.text.trim()}.'
                              : 'Nhập email tài khoản. Chúng tôi sẽ gửi liên kết đặt lại mật khẩu.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          enabled: !_sending && !_emailSent,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateEmail,
                          onFieldSubmitted: (_) => _sendResetEmail(),
                        ),
                        const SizedBox(height: 16),
                        if (!_emailSent)
                          FilledButton(
                            onPressed: _sending ? null : _sendResetEmail,
                            child: _sending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Gửi liên kết đặt lại'),
                          ),
                        if (_emailSent)
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Quay lại đăng nhập'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(authViewModelProvider.notifier)
          .sendPasswordResetEmail(_emailController.text.trim());
      if (!mounted) return;
      setState(() => _emailSent = true);
      showAuthEventNotification(
        context,
        ref,
        'Đã gửi hướng dẫn đặt lại mật khẩu đến email của bạn.',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Vui lòng nhập email.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Email không hợp lệ.';
    }
    return null;
  }

  String _errorMessage(Object error) {
    if (error is AuthAccessException) return error.message;
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-email' => 'Email không hợp lệ.',
        'user-not-found' => 'Không tìm thấy tài khoản với email đã nhập.',
        'too-many-requests' => 'Bạn thử quá nhiều lần. Vui lòng thử lại sau.',
        'network-request-failed' => 'Không thể kết nối mạng. Hãy thử lại.',
        _ =>
          'Không gửi được email đặt lại mật khẩu: ${error.message ?? error.code}',
      };
    }
    return 'Không gửi được email đặt lại mật khẩu: $error';
  }
}

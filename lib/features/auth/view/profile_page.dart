import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/preferences_provider.dart';
import '../view_model/auth_view_model.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _savingProfile = false;
  bool _changingPassword = false;
  bool _rememberEmail = false;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final remember = await getRememberEmailPreference(ref);
    final darkMode = await getDarkModePreference(ref);
    if (!mounted) return;
    setState(() {
      _rememberEmail = remember;
      _darkMode = darkMode;
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authSessionProvider).asData?.value;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Bạn chưa đăng nhập.')),
      );
    }

    final profile = ref.watch(authorizedProfileProvider(user.uid));

    return profile.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Không tải được hồ sơ: $error'),
          ),
        ),
      ),
      data: (account) {
        if (account == null) {
          return const Scaffold(
            body: Center(
              child: Text('Không tìm thấy hồ sơ tài khoản được phép truy cập.'),
            ),
          );
        }

        if (_fullNameController.text.isEmpty && account.fullName.isNotEmpty) {
          _fullNameController.text = account.fullName;
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Tài khoản của tôi')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thông tin cá nhân',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(label: 'Họ tên', value: account.fullName),
                        _InfoRow(label: 'Email', value: account.email),
                        _InfoRow(label: 'Vai trò', value: account.role),
                        _InfoRow(label: 'Trạng thái', value: account.status),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cập nhật hồ sơ',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _fullNameController,
                            decoration: const InputDecoration(
                              labelText: 'Họ và tên',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Họ tên không được để trống.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _savingProfile ? null : _saveProfile,
                              icon: const Icon(Icons.save_outlined),
                              label: _savingProfile
                                  ? const Text('Đang lưu...')
                                  : const Text('Lưu thông tin'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          title: const Text('Ghi nhớ email đăng nhập'),
                          subtitle: const Text('Lưu email ở thiết bị này'),
                          value: _rememberEmail,
                          onChanged: (value) async {
                            setState(() => _rememberEmail = value);
                            await setRememberEmailPreference(ref, remember: value);
                            if (value == false) {
                              await clearSavedEmail(ref);
                            }
                          },
                        ),
                        SwitchListTile.adaptive(
                          title: const Text('Chế độ tối'),
                          subtitle: const Text('Lưu tùy chọn hiển thị'),
                          value: _darkMode,
                          onChanged: (value) async {
                            setState(() => _darkMode = value);
                            await setDarkModePreference(ref, enabled: value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đổi mật khẩu',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: _obscureCurrent,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu hiện tại',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscureCurrent = !_obscureCurrent,
                              ),
                              icon: Icon(
                                _obscureCurrent
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscureNew,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu mới',
                            prefixIcon: const Icon(Icons.lock_reset_outlined),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscureNew = !_obscureNew,
                              ),
                              icon: Icon(
                                _obscureNew
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Xác nhận mật khẩu mới',
                            prefixIcon: const Icon(Icons.lock_reset_outlined),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _changingPassword ? null : _changePassword,
                            icon: const Icon(Icons.key_outlined),
                            label: _changingPassword
                                ? const Text('Đang đổi...')
                                : const Text('Đổi mật khẩu'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _savingProfile = true);
    try {
      await ref
          .read(authViewModelProvider.notifier)
          .updateProfile(fullName: _fullNameController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật hồ sơ thành công.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${error.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showMessage('Vui lòng điền đầy đủ thông tin mật khẩu.');
      return;
    }
    if (newPassword != confirmPassword) {
      _showMessage('Mật khẩu mới và xác nhận không khớp.');
      return;
    }

    setState(() => _changingPassword = true);
    try {
      await ref.read(authViewModelProvider.notifier).changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (!mounted) return;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _showMessage('Đổi mật khẩu thành công.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Không thể đổi mật khẩu: ${error.toString()}');
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value.isEmpty ? '—' : value)),
        ],
      ),
    );
  }
}

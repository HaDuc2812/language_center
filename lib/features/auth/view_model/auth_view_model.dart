import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/firebase_providers.dart';

part 'auth_view_model.g.dart';

class AuthAccessException implements Exception {
  const AuthAccessException(this.message);

  final String message;

  @override
  String toString() => message;
}

@Riverpod(keepAlive: true)
class AuthViewModel extends _$AuthViewModel {
  @override
  FutureOr<void> build() {}

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(firebaseAuthProvider)
          .signInWithEmailAndPassword(email: email.trim(), password: password);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(firebaseAuthProvider)
          .sendPasswordResetEmail(email: email.trim());
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateProfile({required String fullName}) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      throw const AuthAccessException('Vui lòng đăng nhập để cập nhật hồ sơ.');
    }

    final trimmedName = fullName.trim();
    if (trimmedName.isEmpty) {
      throw const AuthAccessException('Tên hiển thị không được để trống.');
    }

    state = const AsyncLoading();
    try {
      await user.updateDisplayName(trimmedName);
      await ref.read(firestoreProvider).collection('users').doc(user.uid).set({
        'fullName': trimmedName,
        'email': user.email ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null || user.email == null) {
      throw const AuthAccessException('Vui lòng đăng nhập để đổi mật khẩu.');
    }
    if (newPassword.length < 6) {
      throw const AuthAccessException('Mật khẩu mới phải có ít nhất 6 ký tự.');
    }

    state = const AsyncLoading();
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

class AuthorizedProfile {
  const AuthorizedProfile({
    required this.uid,
    required this.role,
    required this.status,
    required this.email,
    required this.fullName,
  });

  final String uid;
  final String role;
  final String status;
  final String email;
  final String fullName;
}

@riverpod
Stream<User?> authSession(Ref ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
}

@riverpod
Stream<AuthorizedProfile?> authorizedProfile(Ref ref, String uid) {
  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((document) {
        final data = document.data();
        final role = data?['role'];
        final status = data?['status'];
        final email = data?['email'] as String? ?? '';
        final fullName = data?['fullName'] as String? ?? '';
        if (!document.exists ||
            status != 'active' ||
            (role != 'admin' && role != 'staff')) {
          return null;
        }
        return AuthorizedProfile(
          uid: uid,
          role: role as String,
          status: status as String,
          email: email,
          fullName: fullName,
        );
      });
}

@riverpod
Future<String?> currentUserRole(Ref ref) async {
  final user = await ref.watch(authSessionProvider.future);
  if (user == null) return null;
  final profile = await ref.watch(authorizedProfileProvider(user.uid).future);
  return profile?.role;
}

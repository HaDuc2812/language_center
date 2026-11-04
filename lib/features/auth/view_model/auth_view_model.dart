import 'dart:async';

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

@riverpod
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
}

class AuthorizedProfile {
  const AuthorizedProfile({required this.uid, required this.role});

  final String uid;
  final String role;
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
        if (!document.exists ||
            data?['status'] != 'active' ||
            (role != 'admin' && role != 'staff')) {
          return null;
        }
        return AuthorizedProfile(uid: uid, role: role as String);
      });
}

@riverpod
Future<String?> currentUserRole(Ref ref) async {
  final user = await ref.watch(authSessionProvider.future);
  if (user == null) return null;
  final profile = await ref.watch(authorizedProfileProvider(user.uid).future);
  return profile?.role;
}

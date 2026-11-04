// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AuthViewModel)
final authViewModelProvider = AuthViewModelProvider._();

final class AuthViewModelProvider
    extends $AsyncNotifierProvider<AuthViewModel, void> {
  AuthViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authViewModelHash();

  @$internal
  @override
  AuthViewModel create() => AuthViewModel();
}

String _$authViewModelHash() => r'bc1173b575baef4a35972a4c28c82b282b4854f7';

abstract class _$AuthViewModel extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(authSession)
final authSessionProvider = AuthSessionProvider._();

final class AuthSessionProvider
    extends $FunctionalProvider<AsyncValue<User?>, User?, Stream<User?>>
    with $FutureModifier<User?>, $StreamProvider<User?> {
  AuthSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authSessionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authSessionHash();

  @$internal
  @override
  $StreamProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<User?> create(Ref ref) {
    return authSession(ref);
  }
}

String _$authSessionHash() => r'26d8d4fa31e0f201443c590862da9d4a37c23574';

@ProviderFor(authorizedProfile)
final authorizedProfileProvider = AuthorizedProfileFamily._();

final class AuthorizedProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<AuthorizedProfile?>,
          AuthorizedProfile?,
          Stream<AuthorizedProfile?>
        >
    with
        $FutureModifier<AuthorizedProfile?>,
        $StreamProvider<AuthorizedProfile?> {
  AuthorizedProfileProvider._({
    required AuthorizedProfileFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'authorizedProfileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$authorizedProfileHash();

  @override
  String toString() {
    return r'authorizedProfileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<AuthorizedProfile?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<AuthorizedProfile?> create(Ref ref) {
    final argument = this.argument as String;
    return authorizedProfile(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AuthorizedProfileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$authorizedProfileHash() => r'110526964836092a8e1839f56b6dbe28e5a9c922';

final class AuthorizedProfileFamily extends $Family
    with $FunctionalFamilyOverride<Stream<AuthorizedProfile?>, String> {
  AuthorizedProfileFamily._()
    : super(
        retry: null,
        name: r'authorizedProfileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AuthorizedProfileProvider call(String uid) =>
      AuthorizedProfileProvider._(argument: uid, from: this);

  @override
  String toString() => r'authorizedProfileProvider';
}

@ProviderFor(currentUserRole)
final currentUserRoleProvider = CurrentUserRoleProvider._();

final class CurrentUserRoleProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  CurrentUserRoleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserRoleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserRoleHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return currentUserRole(ref);
  }
}

String _$currentUserRoleHash() => r'7041f742292afeb73663cd36e3cd947c8b9d7d12';

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(studentRepository)
final studentRepositoryProvider = StudentRepositoryProvider._();

final class StudentRepositoryProvider
    extends
        $FunctionalProvider<
          StudentRepository,
          StudentRepository,
          StudentRepository
        >
    with $Provider<StudentRepository> {
  StudentRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'studentRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$studentRepositoryHash();

  @$internal
  @override
  $ProviderElement<StudentRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StudentRepository create(Ref ref) {
    return studentRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StudentRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StudentRepository>(value),
    );
  }
}

String _$studentRepositoryHash() =>
    r'a3c1d2e4f5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0';

// ── studentList ──────────────────────────────────────────────────────────────

@ProviderFor(studentList)
final studentListProvider = StudentListProvider._();

final class StudentListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Student>>,
          List<Student>,
          FutureOr<List<Student>>
        >
    with
        $FutureModifier<List<Student>>,
        $FutureProvider<List<Student>> {
  StudentListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'studentListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$studentListHash();

  @$internal
  @override
  $FutureProviderElement<List<Student>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Student>> create(Ref ref) {
    return studentList(ref);
  }
}

String _$studentListHash() => r'b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0';

// ── filteredStudentList ───────────────────────────────────────────────────────

@ProviderFor(filteredStudentList)
final filteredStudentListProvider = FilteredStudentListFamily._();

final class FilteredStudentListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Student>>,
          List<Student>,
          FutureOr<List<Student>>
        >
    with
        $FutureModifier<List<Student>>,
        $FutureProvider<List<Student>> {
  FilteredStudentListProvider._({
    required FilteredStudentListFamily super.from,
    required ({String query, String statusFilter}) super.argument,
  }) : super(
         retry: null,
         name: r'filteredStudentListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filteredStudentListHash();

  @override
  String toString() {
    return r'filteredStudentListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Student>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Student>> create(Ref ref) {
    final argument = this.argument as ({String query, String statusFilter});
    return filteredStudentList(
      ref,
      query: argument.query,
      statusFilter: argument.statusFilter,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredStudentListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filteredStudentListHash() =>
    r'c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1';

final class FilteredStudentListFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Student>>,
          ({String query, String statusFilter})
        > {
  FilteredStudentListFamily._()
    : super(
        retry: null,
        name: r'filteredStudentListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FilteredStudentListProvider call({
    String query = '',
    String statusFilter = 'all',
  }) => FilteredStudentListProvider._(
    argument: (query: query, statusFilter: statusFilter),
    from: this,
  );

  @override
  String toString() => r'filteredStudentListProvider';
}

// ── studentDetail ─────────────────────────────────────────────────────────────

@ProviderFor(studentDetail)
final studentDetailProvider = StudentDetailFamily._();

final class StudentDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<Student?>,
          Student?,
          FutureOr<Student?>
        >
    with
        $FutureModifier<Student?>,
        $FutureProvider<Student?> {
  StudentDetailProvider._({
    required StudentDetailFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'studentDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$studentDetailHash();

  @override
  String toString() {
    return r'studentDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Student?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Student?> create(Ref ref) {
    final argument = this.argument as int;
    return studentDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$studentDetailHash() => r'd3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2';

final class StudentDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Student?>, int> {
  StudentDetailFamily._()
    : super(
        retry: null,
        name: r'studentDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  StudentDetailProvider call(int studentId) =>
      StudentDetailProvider._(argument: studentId, from: this);

  @override
  String toString() => r'studentDetailProvider';
}

// ── nextStudentCode ───────────────────────────────────────────────────────────

@ProviderFor(nextStudentCode)
final nextStudentCodeProvider = NextStudentCodeProvider._();

final class NextStudentCodeProvider
    extends
        $FunctionalProvider<
          AsyncValue<String>,
          String,
          FutureOr<String>
        >
    with
        $FutureModifier<String>,
        $FutureProvider<String> {
  NextStudentCodeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nextStudentCodeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nextStudentCodeHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return nextStudentCode(ref);
  }
}

String _$nextStudentCodeHash() => r'e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3';

// ── studentEnrollments ────────────────────────────────────────────────────────

@ProviderFor(studentEnrollments)
final studentEnrollmentsProvider = StudentEnrollmentsFamily._();

final class StudentEnrollmentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, Object?>>>,
          List<Map<String, Object?>>,
          FutureOr<List<Map<String, Object?>>>
        >
    with
        $FutureModifier<List<Map<String, Object?>>>,
        $FutureProvider<List<Map<String, Object?>>> {
  StudentEnrollmentsProvider._({
    required StudentEnrollmentsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'studentEnrollmentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$studentEnrollmentsHash();

  @override
  String toString() {
    return r'studentEnrollmentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Map<String, Object?>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, Object?>>> create(Ref ref) {
    final argument = this.argument as int;
    return studentEnrollments(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentEnrollmentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$studentEnrollmentsHash() => r'e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4';

final class StudentEnrollmentsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Map<String, Object?>>>, int> {
  StudentEnrollmentsFamily._()
    : super(
        retry: null,
        name: r'studentEnrollmentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  StudentEnrollmentsProvider call(int studentId) =>
      StudentEnrollmentsProvider._(argument: studentId, from: this);

  @override
  String toString() => r'studentEnrollmentsProvider';
}

// ── StudentActions ─────────────────────────────────────────────────────────────

@ProviderFor(StudentActions)
final studentActionsProvider = StudentActionsProvider._();

final class StudentActionsProvider
    extends $AsyncNotifierProvider<StudentActions, void> {
  StudentActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'studentActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$studentActionsHash();

  @$internal
  @override
  StudentActions create() => StudentActions();
}

String _$studentActionsHash() => r'f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4';

abstract class _$StudentActions extends $AsyncNotifier<void> {
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

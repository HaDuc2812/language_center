// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_process_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(learningRepository)
final learningRepositoryProvider = LearningRepositoryProvider._();

final class LearningRepositoryProvider
    extends
        $FunctionalProvider<
          LearningRepository,
          LearningRepository,
          LearningRepository
        >
    with $Provider<LearningRepository> {
  LearningRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'learningRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$learningRepositoryHash();

  @$internal
  @override
  $ProviderElement<LearningRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LearningRepository create(Ref ref) {
    return learningRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LearningRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LearningRepository>(value),
    );
  }
}

String _$learningRepositoryHash() =>
    r'fbda20367ca284fafb3c5f7eceb939e2acc9f580';

@ProviderFor(classList)
final classListProvider = ClassListProvider._();

final class ClassListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ClassRecord>>,
          List<ClassRecord>,
          FutureOr<List<ClassRecord>>
        >
    with
        $FutureModifier<List<ClassRecord>>,
        $FutureProvider<List<ClassRecord>> {
  ClassListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'classListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$classListHash();

  @$internal
  @override
  $FutureProviderElement<List<ClassRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ClassRecord>> create(Ref ref) {
    return classList(ref);
  }
}

String _$classListHash() => r'4fd868f25f537599c6435ff6c43bce2599c1b84f';

@ProviderFor(enrollmentList)
final enrollmentListProvider = EnrollmentListProvider._();

final class EnrollmentListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<EnrollmentRecord>>,
          List<EnrollmentRecord>,
          FutureOr<List<EnrollmentRecord>>
        >
    with
        $FutureModifier<List<EnrollmentRecord>>,
        $FutureProvider<List<EnrollmentRecord>> {
  EnrollmentListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'enrollmentListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$enrollmentListHash();

  @$internal
  @override
  $FutureProviderElement<List<EnrollmentRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<EnrollmentRecord>> create(Ref ref) {
    return enrollmentList(ref);
  }
}

String _$enrollmentListHash() => r'aa70bf89921e34663439dca7ec057538e76f31d2';

@ProviderFor(classEnrollmentList)
final classEnrollmentListProvider = ClassEnrollmentListFamily._();

final class ClassEnrollmentListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<EnrollmentRecord>>,
          List<EnrollmentRecord>,
          FutureOr<List<EnrollmentRecord>>
        >
    with
        $FutureModifier<List<EnrollmentRecord>>,
        $FutureProvider<List<EnrollmentRecord>> {
  ClassEnrollmentListProvider._({
    required ClassEnrollmentListFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'classEnrollmentListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$classEnrollmentListHash();

  @override
  String toString() {
    return r'classEnrollmentListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<EnrollmentRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<EnrollmentRecord>> create(Ref ref) {
    final argument = this.argument as int;
    return classEnrollmentList(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClassEnrollmentListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$classEnrollmentListHash() =>
    r'6ce73a968d49dcec5fb7e4d4952caed265e057af';

final class ClassEnrollmentListFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<EnrollmentRecord>>, int> {
  ClassEnrollmentListFamily._()
    : super(
        retry: null,
        name: r'classEnrollmentListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ClassEnrollmentListProvider call(int classId) =>
      ClassEnrollmentListProvider._(argument: classId, from: this);

  @override
  String toString() => r'classEnrollmentListProvider';
}

@ProviderFor(studentSearch)
final studentSearchProvider = StudentSearchFamily._();

final class StudentSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StudentRecord>>,
          List<StudentRecord>,
          FutureOr<List<StudentRecord>>
        >
    with
        $FutureModifier<List<StudentRecord>>,
        $FutureProvider<List<StudentRecord>> {
  StudentSearchProvider._({
    required StudentSearchFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'studentSearchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$studentSearchHash();

  @override
  String toString() {
    return r'studentSearchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<StudentRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<StudentRecord>> create(Ref ref) {
    final argument = this.argument as String;
    return studentSearch(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentSearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$studentSearchHash() => r'69184d4e3bbd4f7ee6295f2b7f8b6f8f2984f9f4';

final class StudentSearchFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<StudentRecord>>, String> {
  StudentSearchFamily._()
    : super(
        retry: null,
        name: r'studentSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  StudentSearchProvider call(String query) =>
      StudentSearchProvider._(argument: query, from: this);

  @override
  String toString() => r'studentSearchProvider';
}

@ProviderFor(studentHistory)
final studentHistoryProvider = StudentHistoryFamily._();

final class StudentHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StudentHistoryRecord>>,
          List<StudentHistoryRecord>,
          FutureOr<List<StudentHistoryRecord>>
        >
    with
        $FutureModifier<List<StudentHistoryRecord>>,
        $FutureProvider<List<StudentHistoryRecord>> {
  StudentHistoryProvider._({
    required StudentHistoryFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'studentHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$studentHistoryHash();

  @override
  String toString() {
    return r'studentHistoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<StudentHistoryRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<StudentHistoryRecord>> create(Ref ref) {
    final argument = this.argument as int;
    return studentHistory(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$studentHistoryHash() => r'2718d5e6cef7af95c97cad69d46e663c380cd53f';

final class StudentHistoryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<StudentHistoryRecord>>, int> {
  StudentHistoryFamily._()
    : super(
        retry: null,
        name: r'studentHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  StudentHistoryProvider call(int studentId) =>
      StudentHistoryProvider._(argument: studentId, from: this);

  @override
  String toString() => r'studentHistoryProvider';
}

@ProviderFor(classSessions)
final classSessionsProvider = ClassSessionsFamily._();

final class ClassSessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SessionRecord>>,
          List<SessionRecord>,
          FutureOr<List<SessionRecord>>
        >
    with
        $FutureModifier<List<SessionRecord>>,
        $FutureProvider<List<SessionRecord>> {
  ClassSessionsProvider._({
    required ClassSessionsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'classSessionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$classSessionsHash();

  @override
  String toString() {
    return r'classSessionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<SessionRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SessionRecord>> create(Ref ref) {
    final argument = this.argument as int;
    return classSessions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClassSessionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$classSessionsHash() => r'32971b8243946414a12377006c79d62054a8194c';

final class ClassSessionsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<SessionRecord>>, int> {
  ClassSessionsFamily._()
    : super(
        retry: null,
        name: r'classSessionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ClassSessionsProvider call(int classId) =>
      ClassSessionsProvider._(argument: classId, from: this);

  @override
  String toString() => r'classSessionsProvider';
}

@ProviderFor(sessionAttendance)
final sessionAttendanceProvider = SessionAttendanceFamily._();

final class SessionAttendanceProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AttendanceRecord>>,
          List<AttendanceRecord>,
          FutureOr<List<AttendanceRecord>>
        >
    with
        $FutureModifier<List<AttendanceRecord>>,
        $FutureProvider<List<AttendanceRecord>> {
  SessionAttendanceProvider._({
    required SessionAttendanceFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'sessionAttendanceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionAttendanceHash();

  @override
  String toString() {
    return r'sessionAttendanceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<AttendanceRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AttendanceRecord>> create(Ref ref) {
    final argument = this.argument as int;
    return sessionAttendance(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SessionAttendanceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionAttendanceHash() => r'2b868428bfb68963c226203cc9781e50113435cc';

final class SessionAttendanceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<AttendanceRecord>>, int> {
  SessionAttendanceFamily._()
    : super(
        retry: null,
        name: r'sessionAttendanceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SessionAttendanceProvider call(int sessionId) =>
      SessionAttendanceProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'sessionAttendanceProvider';
}

@ProviderFor(classResults)
final classResultsProvider = ClassResultsFamily._();

final class ClassResultsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<EnrollmentRecord>>,
          List<EnrollmentRecord>,
          FutureOr<List<EnrollmentRecord>>
        >
    with
        $FutureModifier<List<EnrollmentRecord>>,
        $FutureProvider<List<EnrollmentRecord>> {
  ClassResultsProvider._({
    required ClassResultsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'classResultsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$classResultsHash();

  @override
  String toString() {
    return r'classResultsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<EnrollmentRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<EnrollmentRecord>> create(Ref ref) {
    final argument = this.argument as int;
    return classResults(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClassResultsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$classResultsHash() => r'd178f578658d4dd730f133849313f93c1db407d0';

final class ClassResultsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<EnrollmentRecord>>, int> {
  ClassResultsFamily._()
    : super(
        retry: null,
        name: r'classResultsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ClassResultsProvider call(int classId) =>
      ClassResultsProvider._(argument: classId, from: this);

  @override
  String toString() => r'classResultsProvider';
}

@ProviderFor(LearningProcessActions)
final learningProcessActionsProvider = LearningProcessActionsProvider._();

final class LearningProcessActionsProvider
    extends $AsyncNotifierProvider<LearningProcessActions, void> {
  LearningProcessActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'learningProcessActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$learningProcessActionsHash();

  @$internal
  @override
  LearningProcessActions create() => LearningProcessActions();
}

String _$learningProcessActionsHash() =>
    r'812da9dd53aab5b10716fba814356fb24231121d';

abstract class _$LearningProcessActions extends $AsyncNotifier<void> {
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

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(courseRepository)
final courseRepositoryProvider = CourseRepositoryProvider._();

final class CourseRepositoryProvider
    extends
        $FunctionalProvider<
          CourseRepository,
          CourseRepository,
          CourseRepository
        >
    with $Provider<CourseRepository> {
  CourseRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'courseRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$courseRepositoryHash();

  @$internal
  @override
  $ProviderElement<CourseRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CourseRepository create(Ref ref) {
    return courseRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CourseRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CourseRepository>(value),
    );
  }
}

String _$courseRepositoryHash() => r'975352e187ea5778ae3529e59a92f4ef2aa0163b';

@ProviderFor(courseList)
final courseListProvider = CourseListProvider._();

final class CourseListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CourseRecord>>,
          List<CourseRecord>,
          FutureOr<List<CourseRecord>>
        >
    with
        $FutureModifier<List<CourseRecord>>,
        $FutureProvider<List<CourseRecord>> {
  CourseListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'courseListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$courseListHash();

  @$internal
  @override
  $FutureProviderElement<List<CourseRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CourseRecord>> create(Ref ref) {
    return courseList(ref);
  }
}

String _$courseListHash() => r'fd2a8162ad0164656a8d3edf5bd505bd84639c96';

@ProviderFor(courseSearch)
final courseSearchProvider = CourseSearchFamily._();

final class CourseSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CourseRecord>>,
          List<CourseRecord>,
          FutureOr<List<CourseRecord>>
        >
    with
        $FutureModifier<List<CourseRecord>>,
        $FutureProvider<List<CourseRecord>> {
  CourseSearchProvider._({
    required CourseSearchFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'courseSearchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$courseSearchHash();

  @override
  String toString() {
    return r'courseSearchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<CourseRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CourseRecord>> create(Ref ref) {
    final argument = this.argument as String;
    return courseSearch(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CourseSearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$courseSearchHash() => r'a3174c597e576c35d3564d7172dbf350d4fb9261';

final class CourseSearchFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<CourseRecord>>, String> {
  CourseSearchFamily._()
    : super(
        retry: null,
        name: r'courseSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CourseSearchProvider call(String query) =>
      CourseSearchProvider._(argument: query, from: this);

  @override
  String toString() => r'courseSearchProvider';
}

@ProviderFor(classroomList)
final classroomListProvider = ClassroomListProvider._();

final class ClassroomListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ClassroomRecord>>,
          List<ClassroomRecord>,
          FutureOr<List<ClassroomRecord>>
        >
    with
        $FutureModifier<List<ClassroomRecord>>,
        $FutureProvider<List<ClassroomRecord>> {
  ClassroomListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'classroomListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$classroomListHash();

  @$internal
  @override
  $FutureProviderElement<List<ClassroomRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ClassroomRecord>> create(Ref ref) {
    return classroomList(ref);
  }
}

String _$classroomListHash() => r'10701dbb9044a9103e3ecb254125433da7728275';

@ProviderFor(activeTeacherList)
final activeTeacherListProvider = ActiveTeacherListProvider._();

final class ActiveTeacherListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, Object?>>>,
          List<Map<String, Object?>>,
          FutureOr<List<Map<String, Object?>>>
        >
    with
        $FutureModifier<List<Map<String, Object?>>>,
        $FutureProvider<List<Map<String, Object?>>> {
  ActiveTeacherListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeTeacherListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeTeacherListHash();

  @$internal
  @override
  $FutureProviderElement<List<Map<String, Object?>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, Object?>>> create(Ref ref) {
    return activeTeacherList(ref);
  }
}

String _$activeTeacherListHash() => r'6064ec3e5a589f37a6b9409e3f723ba1b928fea9';

@ProviderFor(CourseActions)
final courseActionsProvider = CourseActionsProvider._();

final class CourseActionsProvider
    extends $AsyncNotifierProvider<CourseActions, void> {
  CourseActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'courseActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$courseActionsHash();

  @$internal
  @override
  CourseActions create() => CourseActions();
}

String _$courseActionsHash() => r'46e320eb18c96b7920d03bed5150863f4718c4c6';

abstract class _$CourseActions extends $AsyncNotifier<void> {
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

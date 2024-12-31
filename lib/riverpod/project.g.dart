// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$projectListHash() => r'07ff15195b70ee23cb19872b307e2b948cfa417b';

/// See also [ProjectList].
@ProviderFor(ProjectList)
final projectListProvider =
    AutoDisposeNotifierProvider<ProjectList, List<FileInfo>>.internal(
  ProjectList.new,
  name: r'projectListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$projectListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProjectList = AutoDisposeNotifier<List<FileInfo>>;
String _$projectStateHash() => r'cbbfa4598a4962de1dedf6c34fb6d5d48fc31c60';

/// See also [ProjectState].
@ProviderFor(ProjectState)
final projectStateProvider =
    AutoDisposeNotifierProvider<ProjectState, ProjectStateType>.internal(
  ProjectState.new,
  name: r'projectStateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$projectStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProjectState = AutoDisposeNotifier<ProjectStateType>;
String _$projectScanProgressHash() =>
    r'e29b20eb3078c3f2abd3a4edf9d9a66fdb03e02f';

/// See also [ProjectScanProgress].
@ProviderFor(ProjectScanProgress)
final projectScanProgressProvider =
    AutoDisposeNotifierProvider<ProjectScanProgress, String>.internal(
  ProjectScanProgress.new,
  name: r'projectScanProgressProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$projectScanProgressHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProjectScanProgress = AutoDisposeNotifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member

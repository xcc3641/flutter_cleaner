// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$projectListHash() => r'f29e1015352456f5c2a24194ab34957b77af3b1b';

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
String _$projectStateHash() => r'b746950b50017001b63e0ccf46c768e25e2501f7';

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
    r'b91ba4c305ebe8f71118f69dbbbecafe7a8f3a62';

/// See also [ProjectScanProgress].
@ProviderFor(ProjectScanProgress)
final projectScanProgressProvider =
    NotifierProvider<ProjectScanProgress, String>.internal(
  ProjectScanProgress.new,
  name: r'projectScanProgressProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$projectScanProgressHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProjectScanProgress = Notifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member

import 'package:flutter_cleaner/demo_mode.dart';
import 'package:flutter_cleaner/file_utils.dart';
import 'package:flutter_cleaner/foundation/preferences/prefs.dart';
import 'package:flutter_cleaner/l10n/l10n.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences_riverpod/shared_preferences_riverpod.dart';
part 'project.g.dart';

final projectBackendProvider = Provider<ProjectBackend>(
    (ref) => kDemoMode ? DemoProjectBackend() : LocalProjectBackend());
final operationErrorProvider = StateProvider<String?>((ref) => null);
final cleanupBusyProvider = StateProvider<bool>((ref) => false);
// Safety mode is intentionally reset on each launch, never restored from a preference.
final isDirectlyRemovePrefProvider = StateProvider<bool>((ref) => false);

@riverpod
class ProjectList extends _$ProjectList {
  @override
  List<FileInfo> build() => [];

  Future<bool> cleanBuildFolder(FileInfo project, {bool isDirectlyRemove = false}) async {
    if (ref.read(cleanupBusyProvider)) return false;
    ref.read(cleanupBusyProvider.notifier).state = true;
    ref.read(operationErrorProvider.notifier).state = null;
    final buildPath = path.join(project.path, 'build');
    String? failure;
    try {
      final backend = ref.read(projectBackendProvider);
      if (isDirectlyRemove) {
        await backend.permanentlyDelete(buildPath);
      } else {
        await backend.trash(buildPath);
      }
    } catch (error) {
      failure = '${systemL10n.errorCleanup('$error')}\n$buildPath';
    }
    // Recalculate from disk even after a partial failure. Never assume a deleted
    // folder is gone, or decrement the total by an estimated size.
    final directory = ref.read(sCacheDirProvider);
    await refresh(directory.isEmpty ? project.path : directory);
    if (failure != null) {
      final scanError = ref.read(operationErrorProvider);
      ref.read(operationErrorProvider.notifier).state =
          scanError == null ? failure : '$failure\n$scanError';
    }
    ref.read(cleanupBusyProvider.notifier).state = false;
    return failure == null && ref.read(projectStateProvider) != ProjectStateType.error;
  }

  Future<void> reveal(String directory) async {
    try {
      await ref.read(projectBackendProvider).reveal(directory);
    } catch (error) {
      ref.read(operationErrorProvider.notifier).state = '${systemL10n.errorReveal('$error')}\n$directory';
    }
  }

  Future<void> refresh(String dir) async {
    ref.read(projectStateProvider.notifier).setState(ProjectStateType.loading);
    ref.read(operationErrorProvider.notifier).state = null;
    ref.read(projectScanProgressProvider.notifier).update(dir);
    try {
      final projects = await ref.read(projectBackendProvider).scan(dir, (currentPath) {
        ref.read(projectScanProgressProvider.notifier).update(currentPath);
      });
      state = projects;
      ref.read(projectStateProvider.notifier).setState(
          projects.isEmpty ? ProjectStateType.empty : ProjectStateType.finished);
    } catch (error) {
      // Stale sizes must not be presented as a successful calculation.
      state = [];
      ref.read(operationErrorProvider.notifier).state =
          '${systemL10n.scanFailed}\n$error\n$dir';
      ref.read(projectStateProvider.notifier).setState(ProjectStateType.error);
    }
  }
}

enum ProjectStateType { loading, empty, error, finished }

@riverpod
class ProjectState extends _$ProjectState {
  @override
  ProjectStateType build() => ProjectStateType.empty;
  void setState(ProjectStateType newState) => state = newState;
}

@Riverpod(keepAlive: true)
class ProjectScanProgress extends _$ProjectScanProgress {
  @override
  String build() => '';
  void update(String value) => state = value;
}

final sCacheDirProvider = createPrefProvider<String>(
  prefs: (_) => Pref.instance, prefKey: 'cache_dir', defaultValue: '',
);
final sCacheBookmark = Pref.nonNull('cache_bookmark', '');

import 'package:flutter_cleaner/file_utils.dart';
import 'package:flutter_cleaner/foundation/preferences/prefs.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences_riverpod/shared_preferences_riverpod.dart';
part 'project.g.dart';

@riverpod
class ProjectList extends _$ProjectList {
  @override
  List<FileInfo> build() {
    return [];
  }

  void cleanBuildFolder(FileInfo project, {bool isDirectlyRemove = false}) async {
    final buildPath = path.join(project.path, 'build');
    if (isDirectlyRemove) {
      await FileUtils.remove(buildPath);
    } else {
      await FileUtils.moveToTrash(buildPath);
    }
    state = state.where((p) => p.path != project.path).toList();
  }

  Future<void> refresh(String dir) async {
    ref.read(projectStateProvider.notifier).setState(ProjectStateType.loading);
    final projects = await FileUtils.scanForFlutterProjects(dir, (scanned, total) {
      ref.read(projectScanProgressProvider.notifier).update("$scanned/$total");
    });
    state = projects;
    ref
        .read(projectStateProvider.notifier)
        .setState(projects.isEmpty ? ProjectStateType.empty : ProjectStateType.finished);
  }
}

enum ProjectStateType {
  loading,
  empty,
  error,
  finished,
}

@riverpod
class ProjectState extends _$ProjectState {
  @override
  ProjectStateType build() {
    return ProjectStateType.empty;
  }

  void setState(ProjectStateType newState) {
    state = newState;
  }
}

@riverpod
class ProjectScanProgress extends _$ProjectScanProgress {
  @override
  String build() {
    return "";
  }

  void update(String value) {
    state = value;
  }
}

final sCacheDirProvider = createPrefProvider<String>(
  prefs: (_) => Pref.instance,
  prefKey: "cache_dir",
  defaultValue: "",
);

final sCacheBookmark = Pref.nonNull('cache_bookmark', "");

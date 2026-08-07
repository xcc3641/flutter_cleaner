import 'package:flutter_cleaner/file_utils.dart';
import 'package:flutter_cleaner/foundation/preferences/prefs.dart';
import 'package:flutter_cleaner/models.dart';
import 'package:path/path.dart' as path;
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Manual Notifier to avoid build_runner entirely
final projectListProvider = AutoDisposeNotifierProvider<ProjectList, List<FileInfo>>(ProjectList.new);

class ProjectList extends AutoDisposeNotifier<List<FileInfo>> {
  @override
  List<FileInfo> build() {
    return [];
  }

  Future<void> cleanProject(FileInfo project, {bool isDirectlyRemove = false}) async {
    for (final folder in project.foldersToClean) {
      final folderPath = path.join(project.path, folder);
      if (isDirectlyRemove) {
        await FileUtils.remove(folderPath);
      } else {
        await FileUtils.moveToTrash(folderPath);
      }
    }
    state = state.where((p) => p.path != project.path).toList();
  }

  Future<void> refresh(List<String> dirs) async {
    if (dirs.isEmpty) {
      state = [];
      ref.read(projectStateProvider.notifier).state = ProjectStateType.empty;
      return;
    }

    ref.read(projectStateProvider.notifier).state = ProjectStateType.loading;
    try {
      final projects = await FileUtils.scanForProjects(dirs, (scanned, total) {
        ref.read(projectScanProgressProvider.notifier).state = "$scanned/$total";
      });
      state = projects;
      ref.read(projectStateProvider.notifier).state =
          projects.isEmpty ? ProjectStateType.empty : ProjectStateType.finished;
    } catch (e) {
      ref.read(projectStateProvider.notifier).state = ProjectStateType.error;
    }
  }
}

enum ProjectStateType {
  loading,
  empty,
  error,
  finished,
}

final projectStateProvider = StateProvider<ProjectStateType>((ref) => ProjectStateType.empty);
final projectScanProgressProvider = StateProvider<String>((ref) => "");

final cacheDirListProvider = StateNotifierProvider<CacheDirListNotifier, List<String>>((ref) {
  return CacheDirListNotifier();
});

class CacheDirListNotifier extends StateNotifier<List<String>> {
  final _pref = Pref.nonNull('cache_dir_list', <String>[]);
  CacheDirListNotifier() : super([]) {
    state = _pref.read();
  }

  void update(List<String> newList) {
    _pref.write(newList);
    state = newList;
  }
}

final cacheDirProvider = StateNotifierProvider<CacheDirNotifier, String>((ref) {
  return CacheDirNotifier();
});

class CacheDirNotifier extends StateNotifier<String> {
  final _pref = Pref.nonNull('cache_dir', '');
  CacheDirNotifier() : super('') {
    state = _pref.read();
  }

  void update(String value) {
    _pref.write(value);
    state = value;
  }
}

final isDirectlyRemoveProvider = StateNotifierProvider<IsDirectlyRemoveNotifier, bool>((ref) {
  return IsDirectlyRemoveNotifier();
});

class IsDirectlyRemoveNotifier extends StateNotifier<bool> {
  final _pref = Pref.nonNull('is_directly_remove', false);
  IsDirectlyRemoveNotifier() : super(false) {
    state = _pref.read();
  }

  void update(bool value) {
    _pref.write(value);
    state = value;
  }
}

import 'package:flutter_cleaner/file_utils.dart';
import 'package:flutter_cleaner/foundation/preferences/prefs.dart';

/// Screenshot-only mode: `--dart-define=DEMO_MODE=true`. Every demo path is
/// guarded by this const so release builds without the flag tree-shake it out.
const bool kDemoMode = bool.fromEnvironment('DEMO_MODE');
/// `--dart-define=DEMO_STATE=empty` shows the directory with nothing to clean.
const String kDemoState = String.fromEnvironment('DEMO_STATE');
const kDemoDirectory = '/Users/demo/Developer/Flutter';

/// Used instead of [Pref.awaitReady], so demo mode never reads or overwrites
/// the user's saved directory and bookmark.
Future<void> prepareDemoPreferences() => Pref.awaitInMemory({'cache_dir': kDemoDirectory});

List<FileInfo> demoProjects({DateTime? now, bool empty = kDemoState == 'empty'}) {
  if (empty) return [];
  final today = now ?? DateTime.now();
  const mb = 1024 * 1024;
  FileInfo demo(String name, int size, Duration age) => FileInfo(name: name,
    path: '$kDemoDirectory/$name', size: size, lastModified: today.subtract(age));
  return [
    demo('weather_now', 1660 * mb, const Duration(hours: 3)),
    demo('habit_tracker', 1340 * mb, const Duration(days: 1, hours: 5)),
    demo('recipe_box', 1105 * mb, const Duration(days: 4)),
    demo('photo_journal', 962 * mb, const Duration(days: 9)),
    demo('budget_buddy', 890 * mb, const Duration(days: 16)),
    demo('travel_planner', 728 * mb, const Duration(days: 27)),
  ];
}

/// Fictional data only. Nothing here touches the filesystem; cleaning simply
/// drops the project from the list until the next launch.
class DemoProjectBackend implements ProjectBackend {
  final List<FileInfo> _projects;
  DemoProjectBackend({List<FileInfo>? projects}) : _projects = projects ?? demoProjects();

  @override
  Future<List<FileInfo>> scan(String directory, void Function(String path) onPath) async {
    for (final project in _projects) {
      onPath(project.path);
    }
    return List.of(_projects);
  }

  @override
  Future<void> trash(String buildPath) async => _remove(buildPath);

  @override
  Future<void> permanentlyDelete(String buildPath) async => _remove(buildPath);

  @override
  Future<void> reveal(String projectPath) async {}

  void _remove(String buildPath) =>
      _projects.removeWhere((project) => '${project.path}/build' == buildPath);
}

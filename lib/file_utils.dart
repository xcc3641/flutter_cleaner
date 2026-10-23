import 'dart:io';
import 'dart:math';
import 'package:flutter_cleaner/l10n/l10n.dart';
import 'package:flutter_cleaner/macos_trash.dart';
import 'package:flutter_cleaner/riverpod/project.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;

class FileInfo {
  final String name;
  final String path;
  final int size;
  final DateTime lastModified;

  FileInfo({required this.name, required this.path, required this.size, required this.lastModified});
}

/// The boundary used by the UI. Tests replace it, never the user's filesystem.
abstract class ProjectBackend {
  Future<List<FileInfo>> scan(String directory, void Function(String path) onPath);
  Future<void> trash(String buildPath);
  Future<void> permanentlyDelete(String buildPath);
  Future<void> reveal(String projectPath);
}

class LocalProjectBackend implements ProjectBackend {
  final bool scopedAccess;
  final bool nativeSafety;
  LocalProjectBackend({this.scopedAccess = true, this.nativeSafety = true});
  final Map<String, _BuildGuard> _guards = {};

  Future<T> _access<T>(Future<T> Function() operation) async {
    if (!scopedAccess) return operation();
    return BookmarkHelper.withAccess(operation);
  }

  @override
  Future<List<FileInfo>> scan(String directory, void Function(String path) onPath) => _access(() async {
    final root = await Directory(directory).resolveSymbolicLinks();
    final projects = await FileUtils.scanForFlutterProjects(root, onPath);
    final guards = <String, _BuildGuard>{};
    for (final project in projects) {
      final build = path.join(project.path, 'build');
      guards[build] = await _BuildGuard.capture(root, project.path, build,
        native: nativeSafety && Platform.isMacOS);
    }
    _guards..clear()..addAll(guards);
    return projects;
  });

  Future<_BuildGuard> _validated(String buildPath) async {
    final guard = _guards[buildPath];
    if (guard == null) throw FileSystemException(systemL10n.errorNotScanned, buildPath);
    await guard.validate();
    return guard;
  }

  @override
  Future<void> trash(String buildPath) => _access(() async {
    final guard = await _validated(buildPath);
    await MacOSTrash.moveToTrash(buildPath, identity: guard.nativeIdentity);
  });

  @override
  Future<void> permanentlyDelete(String buildPath) => _access(() async {
    final guard = await _validated(buildPath);
    if (guard.nativeIdentity != null) {
      await MacOSTrash.permanentlyDelete(buildPath, identity: guard.nativeIdentity!);
    } else {
      // Unscoped backend is used only for isolated filesystem tests.
      await Directory(buildPath).delete(recursive: true);
    }
  });

  @override
  Future<void> reveal(String projectPath) => _access(() => MacOSTrash.reveal(projectPath));
}

/// A scan snapshot. Production additionally records native device/inode IDs.
/// These path-based checks narrow, but do not eliminate, the final TOCTOU gap.
class _BuildGuard {
  final String root;
  final String project;
  final String build;
  final Map<String, FileStat> stats;
  final Map<String, dynamic>? nativeIdentity;
  _BuildGuard(this.root, this.project, this.build, this.stats, this.nativeIdentity);

  static Future<void> checkPaths(String root, String project, String build) async {
    if (!(project == root || path.isWithin(root, project)) ||
        build != path.join(project, 'build')) {
      throw FileSystemException(systemL10n.errorOutsideSelection, build);
    }
    // Check every ancestor, not only the final build component.
    var current = build;
    while (true) {
      if (await FileSystemEntity.type(current, followLinks: false) != FileSystemEntityType.directory ||
          await Directory(current).resolveSymbolicLinks() != current) {
        throw FileSystemException(systemL10n.errorReplacedOrLinked, current);
      }
      final parent = path.dirname(current);
      if (parent == current) break;
      current = parent;
    }
  }

  static Future<_BuildGuard> capture(String root, String project, String build, {required bool native}) async {
    await checkPaths(root, project, build);
    final stats = <String, FileStat>{};
    for (final entry in {root, project, build}) {
      stats[entry] = await FileStat.stat(entry);
    }
    final identity = native ? await MacOSTrash.captureIdentity(root, project, build) : null;
    return _BuildGuard(root, project, build, stats, identity);
  }

  Future<void> validate() async {
    await checkPaths(root, project, build);
    for (final entry in stats.entries) {
      final now = await FileStat.stat(entry.key);
      final before = entry.value;
      if (now.type != before.type || now.mode != before.mode ||
          now.changed != before.changed || now.modified != before.modified) {
        throw FileSystemException(systemL10n.errorChangedSinceScan, entry.key);
      }
    }
  }
}

class FileUtils {
  static Future<int> calculateDirectorySize(String dirPath) async {
    var total = 0;
    final dir = Directory(dirPath);
    final type = await FileSystemEntity.type(dirPath, followLinks: false);
    if (type == FileSystemEntityType.notFound) return 0;
    if (type != FileSystemEntityType.directory) {
      throw FileSystemException(systemL10n.errorBuildNotDirectory, dirPath);
    }
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  static Future<List<FileInfo>> scanForFlutterProjects(
    String directory, void Function(String path)? onPath,
  ) async {
    final found = <FileInfo>[];
    Future<void> visit(Directory dir) async {
      onPath?.call(dir.path);
      try {
        final pubspec = File(path.join(dir.path, 'pubspec.yaml'));
        if (await pubspec.exists()) {
          final yaml = loadYaml(await pubspec.readAsString());
          final dependencies = yaml is YamlMap ? yaml['dependencies'] : null;
          if (dependencies is YamlMap && dependencies.containsKey('flutter')) {
            final build = Directory(path.join(dir.path, 'build'));
            final buildType = await FileSystemEntity.type(build.path, followLinks: false);
            final size = buildType == FileSystemEntityType.directory
                ? await calculateDirectorySize(build.path) : 0;
            if (size > 0) {
              found.add(FileInfo(
                name: yaml['name']?.toString() ?? path.basename(dir.path),
                path: dir.path, size: size,
                lastModified: (await build.stat()).modified,
              ));
            }
          }
        }
        await for (final entity in dir.list(followLinks: false)) {
          if (entity is Directory && !{'build', '.git', '.dart_tool', '.pub-cache', 'Pods', 'node_modules'}.contains(path.basename(entity.path))) {
            await visit(entity);
          }
        }
      } catch (error) {
        // Include the exact directory even when a parser/plugin error omits it.
        throw FileSystemException(systemL10n.errorScan('$error'), dir.path);
      }
    }
    await visit(Directory(directory));
    found.sort((a, b) => b.size.compareTo(a.size));
    return found;
  }

  static String formatFileSize(int size) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    if (size == 0) return '0 B';
    final i = min((log(size) / log(1024)).floor(), suffixes.length - 1);
    return i < 3 ? '${(size / pow(1024, i)).floor()}${suffixes[i]}'
        : '${(size / pow(1024, i)).toStringAsFixed(1)}${suffixes[i]}';
  }
}

class BookmarkHelper {
  static final SecureBookmarks secureBookmarks = SecureBookmarks();

  static Future<T> withAccess<T>(Future<T> Function() operation) async {
    final bookmark = sCacheBookmark.read();
    if (bookmark.isEmpty) throw StateError(systemL10n.errorFolderAccess);
    final file = await secureBookmarks.resolveBookmark(bookmark);
    await secureBookmarks.startAccessingSecurityScopedResource(file);
    try {
      return await operation();
    } finally {
      await secureBookmarks.stopAccessingSecurityScopedResource(file);
    }
  }
}

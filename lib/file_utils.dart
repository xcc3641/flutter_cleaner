import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter_cleaner/foundation/logger.dart';
import 'package:flutter_cleaner/macos_trash.dart';
import 'package:flutter_cleaner/riverpod/project.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;
import 'package:process_run/process_run.dart';

class FileInfo {
  final String name;
  final String path;
  final int size;
  final DateTime lastModified;

  FileInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.lastModified,
  });
}

class FileUtils {
  static Future<int> calculateDirectorySize(String dirPath) async {
    int totalSize = 0;
    var dir = Directory(dirPath);
    if (await dir.exists()) {
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    }
    return totalSize;
  }

  static Future<List<FileInfo>> scanForFlutterProjects(
    String directory,
    void Function(int scanned, int total)? onProgress,
  ) async {
    await BookmarkHelper.startAccessingSecurityScopedResource();
    final dir = Directory(directory);
    final List<FileInfo> foundProjects = [];

    // Calculate total directories first
    int totalDirectories =
        await dir.list(recursive: false, followLinks: false).where((entity) => entity is Directory).length;
    int scannedDirectories = 0;

    await for (final entity in dir.list(recursive: false, followLinks: false)) {
      if (entity is Directory) {
        scannedDirectories++;
        if (onProgress != null) {
          onProgress(scannedDirectories, totalDirectories);
        }

        await for (final file in entity.list(recursive: true, followLinks: false)) {
          if (file is File && file.path.endsWith('pubspec.yaml')) {
            try {
              final content = await file.readAsString();
              final yaml = loadYaml(content);
              final projectPath = file.parent.path;
              final buildPath = path.join(projectPath, 'build');
              final buildSize = await calculateDirectorySize(buildPath);
              final buildLastModified = file.lastModifiedSync();

              if (buildSize > 0) {
                foundProjects.add(FileInfo(
                  name: yaml['name'] ?? 'Unknown',
                  path: projectPath,
                  size: buildSize,
                  lastModified: buildLastModified,
                ));
              }
            } catch (e) {
              logger.e('Error processing ${file.path}: $e');
            }
          }
        }
      }
    }

    await BookmarkHelper.stopAccessingSecurityScopedResource();
    foundProjects.sort((a, b) => b.size.compareTo(a.size));
    return foundProjects;
  }

  static String formatFileSize(int size) {
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    if (size == 0) return '0 ${suffixes[0]}';
    int i = (log(size) / log(1024)).floor();
    if (i < 3) {
      return '${(size / pow(1024, i)).floor()}${suffixes[i]}';
    } else {
      return '${(size / pow(1024, i)).toStringAsFixed(1)}${suffixes[i]}';
    }
  }

  static Future<void> moveToTrash(String filePath) async {
    logger.d('Attempting to move to trash: $filePath');
    if (Platform.isMacOS) {
      await BookmarkHelper.startAccessingSecurityScopedResource();
      try {
        await MacOSTrash.moveToTrash(filePath);
        logger.d('Successfully moved to trash: $filePath');
      } catch (e) {
        logger.e('Error moving file to trash: $e');
        rethrow;
      }
      await BookmarkHelper.stopAccessingSecurityScopedResource();
    } else if (Platform.isLinux) {
      try {
        await Shell().run('gio trash "$filePath"');
      } catch (e) {
        logger.e('Error moving to trash: $e');
        rethrow;
      }
    } else {
      throw UnsupportedError('Moving to trash not supported on this platform');
    }
  }

  static Future<void> remove(String filePath) async {
    logger.d('Attempting to move to trash: $filePath');
    if (Platform.isMacOS) {
      await BookmarkHelper.startAccessingSecurityScopedResource();
      try {
        Directory(filePath).deleteSync(recursive: true);
      } catch (e) {
        logger.e('Error moving file to trash: $e');
        rethrow;
      }
      await BookmarkHelper.stopAccessingSecurityScopedResource();
    }

    return;
  }

  static openInFinder(String filePath) async {
    if (Platform.isMacOS) {
      await BookmarkHelper.startAccessingSecurityScopedResource();
      await Shell().run('open "$filePath"');
      await BookmarkHelper.stopAccessingSecurityScopedResource();
    } else if (Platform.isLinux) {
      Shell().run('xdg-open "$filePath"');
    } else {
      throw UnsupportedError('Opening in finder not supported on this platform');
    }
  }
}

class BookmarkHelper {
  static SecureBookmarks secureBookmarks = SecureBookmarks();

  static Future<void> startAccessingSecurityScopedResource() async {
    final resolvedBookmark = await secureBookmarks.resolveBookmark(sCacheBookmark.read());
    await secureBookmarks.startAccessingSecurityScopedResource(resolvedBookmark);
  }

  static Future<void> stopAccessingSecurityScopedResource() async {
    final resolvedBookmark = await secureBookmarks.resolveBookmark(sCacheBookmark.read());
    await secureBookmarks.stopAccessingSecurityScopedResource(resolvedBookmark);
  }
}

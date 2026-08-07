import 'dart:async';
import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'dart:math';
import 'package:flutter_cleaner/foundation/logger.dart';
import 'package:flutter_cleaner/macos_trash.dart';
import 'package:flutter_cleaner/models.dart';
import 'package:flutter_cleaner/foundation/preferences/keys.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;
import 'package:process_run/process_run.dart';
import 'dart:convert';

class FileUtils {
  static const List<String> _ignoredDirectories = [
    'node_modules',
    '.git',
    '.next',
    'build',
    '.dart_tool',
    'ios',
    'android',
    'windows',
    'linux',
    'macos',
  ];

  static Future<int> calculateDirectorySize(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return 0;
    return await _calculateSizeRecursive(dir);
  }

  static Future<int> _calculateSizeRecursive(Directory directory) async {
    int totalSize = 0;
    try {
      await for (final entity in directory.list(recursive: false, followLinks: false).handleError((e) {
        // Silently skip common Windows path length/access errors
      })) {
        if (entity is File) {
          try {
            totalSize += await entity.length();
          } catch (e) {
            // Ignore access errors
          }
        } else if (entity is Directory) {
          totalSize += await _calculateSizeRecursive(entity);
        }
      }
    } catch (e) {
      // Ignore directory access errors
    }
    return totalSize;
  }

  static Future<List<FileInfo>> scanForProjects(
    List<String> directories,
    void Function(int scanned, int total)? onProgress,
  ) async {
    if (Platform.isMacOS) {
      await BookmarkHelper.startAccessingSecurityScopedResource();
    }

    final List<FileInfo> foundProjects = [];
    int totalTopLevelDirectories = 0;
    int scannedTopLevelDirectories = 0;

    for (final dirPath in directories) {
      if (dirPath.isEmpty) continue;
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        try {
          await for (final entity in dir.list(recursive: false, followLinks: false)) {
            if (entity is Directory) {
              totalTopLevelDirectories++;
            }
          }
        } catch (e) {
          logger.e('Error counting directory $dirPath: $e');
        }
      }
    }

    for (final dirPath in directories) {
      if (dirPath.isEmpty) continue;
      final dir = Directory(dirPath);
      if (!await dir.exists()) continue;

      try {
        await for (final entity in dir.list(recursive: false, followLinks: false)) {
          if (entity is Directory) {
            scannedTopLevelDirectories++;
            if (onProgress != null) {
              onProgress(scannedTopLevelDirectories, totalTopLevelDirectories);
            }
            await _scanSingleProjectCandidate(entity.path, foundProjects);
          }
        }
      } catch (e) {
        logger.e('Error listing directory $dirPath: $e');
      }
    }

    if (Platform.isMacOS) {
      await BookmarkHelper.stopAccessingSecurityScopedResource();
    }
    foundProjects.sort((a, b) => b.size.compareTo(a.size));
    return foundProjects;
  }

  static Future<void> _scanSingleProjectCandidate(String currentPath, List<FileInfo> foundProjects) async {
    final dir = Directory(currentPath);
    if (!await dir.exists()) return;

    bool isProjectFound = false;

    final pubspec = File(path.join(currentPath, 'pubspec.yaml'));
    final packageJson = File(path.join(currentPath, 'package.json'));

    if (await pubspec.exists()) {
      isProjectFound = true;
      try {
        final content = await pubspec.readAsString();
        final yaml = loadYaml(content);
        final buildPath = path.join(currentPath, 'build');
        final buildSize = await calculateDirectorySize(buildPath);

        if (buildSize > 0) {
          foundProjects.add(FileInfo(
            name: yaml['name'] ?? path.basename(currentPath),
            path: currentPath,
            size: buildSize,
            lastModified: pubspec.lastModifiedSync(),
            type: ProjectType.flutter,
            foldersToClean: ['build'],
          ));
        }
      } catch (e) {
        logger.e('Error processing Flutter project at $currentPath: $e');
      }
    } else if (await packageJson.exists()) {
      isProjectFound = true;
      try {
        final content = await packageJson.readAsString();
        final json = jsonDecode(content);

        final foldersToClean = <String>[];
        final nodeModulesPath = path.join(currentPath, 'node_modules');
        final nextPath = path.join(currentPath, '.next');

        int totalSize = 0;
        if (await Directory(nodeModulesPath).exists()) {
          totalSize += await calculateDirectorySize(nodeModulesPath);
          foldersToClean.add('node_modules');
        }
        if (await Directory(nextPath).exists()) {
          totalSize += await calculateDirectorySize(nextPath);
          foldersToClean.add('.next');
        }

        if (totalSize > 0) {
          foundProjects.add(FileInfo(
            name: json['name'] ?? path.basename(currentPath),
            path: currentPath,
            size: totalSize,
            lastModified: packageJson.lastModifiedSync(),
            type: ProjectType.node,
            foldersToClean: foldersToClean,
          ));
        }
      } catch (e) {
        logger.e('Error processing Node project at $currentPath: $e');
      }
    }

    if (!isProjectFound) {
      try {
        await for (final entity in dir.list(recursive: false, followLinks: false).handleError((e) {
          // Silently skip scan errors
        })) {
          if (entity is Directory) {
            final name = path.basename(entity.path);
            if (!_ignoredDirectories.contains(name) && !name.startsWith('.')) {
              await _scanSingleProjectCandidate(entity.path, foundProjects);
            }
          }
        }
      } catch (e) {
        // Ignore listing errors
      }
    }
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
    } else if (Platform.isWindows) {
      try {
        if (!await FileSystemEntity.isFile(filePath) && !await FileSystemEntity.isDirectory(filePath)) {
          return;
        }

        final pathWide = _toWideString('$filePath\x00');
        final fileOp = calloc<SHFILEOPSTRUCT>();
        fileOp.ref.wFunc = FO_DELETE;
        fileOp.ref.pFrom = pathWide;
        fileOp.ref.pTo = nullptr;
        fileOp.ref.fFlags = FOF_ALLOWUNDO | FOF_NOCONFIRMATION | FOF_SILENT;
        fileOp.ref.fAnyOperationsAborted = FALSE;
        fileOp.ref.hNameMappings = nullptr;
        fileOp.ref.lpszProgressTitle = nullptr;

        final result = SHFileOperation(fileOp);
        calloc.free(pathWide);
        calloc.free(fileOp);

        if (result != 0) {
          throw FileSystemException('Failed to move to trash. Error code: $result', filePath);
        }
      } catch (e) {
        throw FileSystemException('Failed to move to trash: $e', filePath);
      }
    } else {
      throw UnsupportedError('Moving to trash not supported on this platform');
    }
  }

  static Pointer<Utf16> _toWideString(String str) {
    final units = str.codeUnits;
    final ptr = calloc<Uint16>(units.length + 1);
    final list = ptr.asTypedList(units.length + 1);
    list.setAll(0, units);
    list[units.length] = 0;
    return ptr.cast<Utf16>();
  }

  static Future<void> remove(String filePath) async {
    logger.d('Attempting to delete: $filePath');
    if (Platform.isMacOS) {
      await BookmarkHelper.startAccessingSecurityScopedResource();
      try {
        if (await Directory(filePath).exists()) {
          Directory(filePath).deleteSync(recursive: true);
        } else if (await File(filePath).exists()) {
          File(filePath).deleteSync();
        }
      } catch (e) {
        logger.e('Error deleting file: $e');
        rethrow;
      }
      await BookmarkHelper.stopAccessingSecurityScopedResource();
    } else if (Platform.isWindows) {
      try {
        final entity = await FileSystemEntity.type(filePath);
        switch (entity) {
          case FileSystemEntityType.file:
            await File(filePath).delete();
            break;
          case FileSystemEntityType.directory:
            await Directory(filePath).delete(recursive: true);
            break;
          case FileSystemEntityType.link:
            await Link(filePath).delete();
            break;
          case FileSystemEntityType.notFound:
            break;
          default:
            throw FileSystemException('Unsupported file system entity type', filePath);
        }
      } catch (e) {
        throw FileSystemException('Failed to remove: $e', filePath);
      }
    } else {
      if (await Directory(filePath).exists()) {
        await Directory(filePath).delete(recursive: true);
      } else if (await File(filePath).exists()) {
        await File(filePath).delete();
      }
    }
  }

  static openInFinder(String filePath) async {
    if (Platform.isMacOS) {
      await BookmarkHelper.startAccessingSecurityScopedResource();
      await Shell().run('open "$filePath"');
      await BookmarkHelper.stopAccessingSecurityScopedResource();
    } else if (Platform.isLinux) {
      Shell().run('xdg-open "$filePath"');
    } else if (Platform.isWindows) {
      Process.run('explorer', [filePath]);
    } else {
      throw UnsupportedError('Opening in finder not supported on this platform');
    }
  }
}

class BookmarkHelper {
  static SecureBookmarks secureBookmarks = SecureBookmarks();

  static Future<void> startAccessingSecurityScopedResource() async {
    final bookmarkStr = sCacheBookmark.read();
    if (bookmarkStr.isEmpty) return;
    try {
      final resolvedBookmark = await secureBookmarks.resolveBookmark(bookmarkStr);
      await secureBookmarks.startAccessingSecurityScopedResource(resolvedBookmark);
    } catch (e) {
      logger.e('Error starting bookmark access: $e');
    }
  }

  static Future<void> stopAccessingSecurityScopedResource() async {
    final bookmarkStr = sCacheBookmark.read();
    if (bookmarkStr.isEmpty) return;
    try {
      final resolvedBookmark = await secureBookmarks.resolveBookmark(bookmarkStr);
      await secureBookmarks.stopAccessingSecurityScopedResource(resolvedBookmark);
    } catch (e) {
      logger.e('Error stopping bookmark access: $e');
    }
  }
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cleaner/demo_mode.dart';
import 'package:flutter_cleaner/file_utils.dart';
import 'package:flutter_cleaner/foundation/preferences/prefs.dart';
import 'package:flutter_cleaner/l10n/l10n.dart';
import 'package:flutter_cleaner/macos_trash.dart';
import 'package:flutter_cleaner/main.dart';
import 'package:flutter_cleaner/riverpod/project.dart';

class FakeBackend implements ProjectBackend {
  List<FileInfo> projects = [];
  String? failure;
  String? scanFailure;
  Completer<void>? gate;
  final calls = <String>[];
  @override
  Future<List<FileInfo>> scan(String directory, void Function(String) onPath) async {
    onPath('$directory/current-project');
    if (gate != null) await gate!.future;
    if (scanFailure != null) throw FileSystemException(scanFailure!, directory);
    return List.of(projects);
  }
  @override
  Future<void> trash(String path) async {
    calls.add('trash:$path');
    if (failure != null) throw FileSystemException(failure!, path);
    projects = [];
  }
  @override
  Future<void> permanentlyDelete(String path) async {
    calls.add('delete:$path');
    if (failure != null) throw FileSystemException(failure!, path);
    projects = [];
  }
  @override
  Future<void> reveal(String path) async {}
}

FileInfo project() => FileInfo(name: 'my_flutter_app', path: '/projects/my_flutter_app', size: 2048,
  lastModified: DateTime(2026, 10, 23));

Future<Directory> createProject(Directory root, String name, int bytes, {bool flutter = true}) async {
  final dir = Directory(p.join(root.path, name));
  await Directory(p.join(dir.path, 'build', 'nested')).create(recursive: true);
  await File(p.join(dir.path, 'pubspec.yaml')).writeAsString(
    'name: $name\ndependencies:\n  ${flutter ? 'flutter:\n    sdk: flutter' : 'path: any'}\n');
  await File(p.join(dir.path, 'build', 'nested', 'cache.bin')).writeAsBytes(List.filled(bytes, 7));
  return dir;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Pref.awaitReady();
    PackageInfo.setMockInitialValues(appName: 'Cleaner for Flutter', packageName: 'com.hugo.cleanflutter',
      version: '1.1.1', buildNumber: '10', buildSignature: '');
  });

  test('formatFileSize uses whole numbers below a gigabyte', () {
    expect(FileUtils.formatFileSize(0), '0 B');
    expect(FileUtils.formatFileSize(1024), '1KB');
    expect(FileUtils.formatFileSize(1024 * 1024), '1MB');
  });

  test('native error codes map to localized messages; system errors keep their text', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final zh = lookupAppLocalizations(const Locale('zh'));
    String msg(String code, AppLocalizations l10n, [String? message]) =>
        MacOSTrash.messageFor(PlatformException(code: code, message: message), l10n);
    expect(msg('REPLACED_OR_LINKED', zh), '目录已被替换或包含符号链接，请重新扫描。');
    expect(msg('OUT_OF_SCOPE', en), en.errorOutsideSelection);
    expect(msg('SYMLINK_OR_NONCANONICAL', zh), '不允许符号链接或非规范目录，请重新扫描。');
    expect(msg('MISSING_IDENTITY', zh), '缺少目录身份。');
    expect(msg('MISSING_SCAN_IDENTITY', zh), '缺少扫描目录身份，请重新扫描。');
    expect(msg('CHANGED_SINCE_SCAN', en), en.errorChangedSinceScan);
    expect(msg('CLEANUP_ERROR', zh, 'Permission denied'), 'Permission denied');
  });

  test('demo data is fictional, totals 6-7 GB, and cleaning only edits the list', () async {
    expect(kDemoMode, isFalse);
    final projects = demoProjects();
    final total = projects.fold<int>(0, (sum, project) => sum + project.size);
    expect(projects, hasLength(6));
    expect(projects.every((project) => project.path == p.join(kDemoDirectory, project.name)), isTrue);
    expect(total, inInclusiveRange(6 * 1024 * 1024 * 1024, 7 * 1024 * 1024 * 1024));
    expect(demoProjects(empty: true), isEmpty);
    final backend = DemoProjectBackend();
    await backend.trash(p.join(kDemoDirectory, 'recipe_box', 'build'));
    final remaining = await backend.scan(kDemoDirectory, (_) {});
    expect(remaining.map((project) => project.name), isNot(contains('recipe_box')));
    expect(remaining, hasLength(5));
  });

  test('scan calculates real bytes, includes selected project and skips non-Flutter projects', () async {
    final root = await Directory.systemTemp.createTemp('cleaner-scan-');
    addTearDown(() => root.delete(recursive: true));
    final first = await createProject(root, 'first', 1234);
    await createProject(root, 'second', 4321);
    await createProject(root, 'not_flutter', 9000, flutter: false);
    final visited = <String>[];
    final backend = LocalProjectBackend(scopedAccess: false, nativeSafety: false);
    final found = await backend.scan(root.path, visited.add);
    expect(found.map((e) => e.size).toList(), [4321, 1234]);
    expect(found.fold<int>(0, (sum, e) => sum + e.size), 5555);
    expect(visited, contains(await first.resolveSymbolicLinks()));
    expect((await backend.scan(first.path, (_) {})).single.size, 1234);
  });

  test('permanent cleanup operates only on a temporary build and rescans real sizes', () async {
    final root = await Directory.systemTemp.createTemp('cleaner-delete-');
    addTearDown(() => root.delete(recursive: true));
    final dir = await createProject(root, 'fixture', 37);
    final backend = LocalProjectBackend(scopedAccess: false, nativeSafety: false);
    final found = await backend.scan(root.path, (_) {});
    final container = ProviderContainer(overrides: [projectBackendProvider.overrideWithValue(backend)]);
    addTearDown(container.dispose);
    final subscription = container.listen(projectListProvider, (_, __) {});
    addTearDown(subscription.close);
    container.read(sCacheDirProvider.notifier).update(root.path);
    await container.read(projectListProvider.notifier).refresh(root.path);
    expect(await container.read(projectListProvider.notifier).cleanBuildFolder(found.single, isDirectlyRemove: true), isTrue);
    expect(await Directory(p.join(dir.path, 'build')).exists(), isFalse);
    expect(await File(p.join(dir.path, 'pubspec.yaml')).exists(), isTrue);
    expect(container.read(projectListProvider), isEmpty);
  });

  test('scan errors keep actual system error and path, not a fake zero total', () async {
    final root = await Directory.systemTemp.createTemp('cleaner-error-');
    final missing = p.join(root.path, 'missing');
    addTearDown(() => root.delete(recursive: true));
    final container = ProviderContainer(overrides: [
      projectBackendProvider.overrideWithValue(LocalProjectBackend(scopedAccess: false, nativeSafety: false)),
    ]);
    addTearDown(container.dispose);
    final sub = container.listen(projectListProvider, (_, __) {});
    addTearDown(sub.close);
    await container.read(projectListProvider.notifier).refresh(missing);
    expect(container.read(projectStateProvider), ProjectStateType.error);
    expect(container.read(operationErrorProvider), contains(missing));
    expect(container.read(operationErrorProvider), contains('OS Error:'));
    expect(container.read(operationErrorProvider), contains('errno = 2'));
  });

  test('a symlink named build never contributes external bytes', () async {
    final root = await Directory.systemTemp.createTemp('cleaner-link-scan-');
    final external = await Directory.systemTemp.createTemp('cleaner-external-');
    addTearDown(() => root.delete(recursive: true));
    addTearDown(() => external.delete(recursive: true));
    final dir = await createProject(root, 'fixture', 37);
    final payload = File(p.join(external.path, 'precious.bin'));
    await payload.writeAsBytes(List.filled(8192, 9));
    final build = p.join(dir.path, 'build');
    await Directory(build).delete(recursive: true);
    await Link(build).create(external.path);
    final backend = LocalProjectBackend(scopedAccess: false, nativeSafety: false);
    expect(await backend.scan(root.path, (_) {}), isEmpty);
    await expectLater(FileUtils.calculateDirectorySize(build), throwsA(isA<FileSystemException>()));
    expect(await payload.length(), 8192);
  });

  for (final permanent in [false, true]) {
    for (final replaceAncestor in [false, true]) {
      test('reject ${replaceAncestor ? 'ancestor' : 'build'} symlink replacement, permanent=$permanent', () async {
        final root = await Directory.systemTemp.createTemp('cleaner-guard-');
        final external = await Directory.systemTemp.createTemp('cleaner-protected-');
        addTearDown(() => root.delete(recursive: true));
        addTearDown(() => external.delete(recursive: true));
        final parent = Directory(p.join(root.path, 'parent'));
        await parent.create();
        final dir = await createProject(parent, 'fixture', 37);
        final protectedProject = await createProject(external, 'fixture', 8192);
        final protectedBuild = p.join(protectedProject.path, 'build');
        final backend = LocalProjectBackend(scopedAccess: false, nativeSafety: false);
        final scanned = (await backend.scan(root.path, (_) {})).single;
        final build = p.join(scanned.path, 'build');
        if (replaceAncestor) {
          await parent.rename('${parent.path}-original');
          await Link(parent.path).create(external.path);
        } else {
          await Directory(p.join(dir.path, 'build')).rename(p.join(dir.path, 'saved-build'));
          await Link(p.join(dir.path, 'build')).create(protectedBuild);
        }
        await expectLater(permanent ? backend.permanentlyDelete(build) : backend.trash(build),
          throwsA(isA<FileSystemException>()));
        expect(await FileUtils.calculateDirectorySize(protectedBuild), 8192);
        expect(await File(p.join(protectedProject.path, 'pubspec.yaml')).exists(), isTrue);
        // A subsequent scan cannot count bytes from a substituted link.
        final rescanned = await backend.scan(root.path, (_) {});
        expect(rescanned.any((item) => item.size == 8192), isFalse);
      });
    }
  }

  // The app follows the system language; most tests pin Chinese so assertions are stable.
  Future<void> pumpApp(WidgetTester tester, FakeBackend backend, {Size size = const Size(900, 620), bool configured = false, bool dark = false,
      Locale locale = const Locale('zh')}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    if (configured) await Pref.instance.setString('cache_dir', '/projects');
    await tester.pumpWidget(ProviderScope(overrides: [projectBackendProvider.overrideWithValue(backend)], child: const MyApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  for (final size in [const Size(900, 620), const Size(760, 520)]) {
    for (final dark in [false, true]) {
      testWidgets('unconfigured ${size.width}x${size.height}, dark=$dark has no framework errors', (tester) async {
        await pumpApp(tester, FakeBackend(), size: size, dark: dark);
        await tester.pumpAndSettle();
        expect(find.text('Cleaner for Flutter'), findsOneWidget);
        expect(find.text('选择目录'), findsOneWidget);
        expect(find.text('选择包含 Flutter 项目的目录开始扫描。'), findsNWidgets(2));
        expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
        expect(find.text('移至废纸篓（可恢复）'), findsOneWidget);
        expect(tester.takeException(), isNull); // No RenderFlex or other errors suppressed.
      });
    }
  }

  testWidgets('non-Chinese systems fall back to English, narrow layout has no overflow', (tester) async {
    final backend = FakeBackend()..projects = [project(), project()];
    await pumpApp(tester, backend, size: const Size(760, 520), locale: const Locale('fr', 'FR'));
    await tester.pumpAndSettle();
    expect(find.text('Choose Folder'), findsOneWidget);
    expect(find.text('Choose a folder containing Flutter projects to start scanning.'), findsNWidgets(2));
    expect(find.text('Move to Trash (Recoverable)'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, backend, size: const Size(760, 520), configured: true, locale: const Locale('en', 'GB'));
    await tester.pumpAndSettle();
    expect(find.text('Found 2 cleanable projects'), findsOneWidget);
    expect(find.text('Cleanable: 4KB'), findsOneWidget);
    expect(find.text('Rescan'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Delete Permanently (Not Recoverable)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('results show real total; default trash requires confirmation and recalculates', (tester) async {
    final backend = FakeBackend()..projects = [project()];
    await pumpApp(tester, backend, configured: true);
    await tester.pumpAndSettle();
    expect(find.text('可清理空间  2KB'), findsOneWidget);
    expect(find.text('my_flutter_app'), findsOneWidget);
    await tester.tap(find.byTooltip('移到废纸篓'));
    await tester.pumpAndSettle();
    expect(backend.calls, isEmpty);
    expect(find.text('将项目移到废纸篓？'), findsOneWidget);
    await tester.tap(find.text('移到废纸篓'));
    await tester.pumpAndSettle();
    expect(backend.calls, ['trash:/projects/my_flutter_app/build']);
    expect(find.text('可清理空间  0 B'), findsOneWidget);
    expect(find.text('没有发现可清理的 build 缓存。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('permanent mode is explicit, cancel is safe and failures show error/path', (tester) async {
    final backend = FakeBackend()..projects = [project()]..failure = 'Permission denied (errno = 13)';
    await pumpApp(tester, backend, configured: true, size: const Size(760, 520));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('永久删除，不可恢复'), findsOneWidget);
    await tester.tap(find.byTooltip('永久删除'));
    await tester.pumpAndSettle();
    expect(find.text('永久删除这些文件？'), findsOneWidget);
    expect(find.textContaining('无法从废纸篓恢复'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(backend.calls, isEmpty);
    await tester.tap(find.byTooltip('永久删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('永久删除'));
    await tester.pumpAndSettle();
    expect(backend.calls, ['delete:/projects/my_flutter_app/build']);
    expect(find.textContaining('Permission denied'), findsOneWidget);
    expect(find.textContaining('/projects/my_flutter_app/build'), findsOneWidget);
    expect(find.text('可清理空间  2KB'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('trash failure is surfaced and does not claim success', (tester) async {
    final backend = FakeBackend()..projects = [project()]..failure = 'Trash unavailable';
    await pumpApp(tester, backend, configured: true);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('移到废纸篓'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('移到废纸篓'));
    await tester.pumpAndSettle();
    expect(find.textContaining('无法完成清理：'), findsOneWidget);
    expect(find.textContaining('Trash unavailable'), findsOneWidget);
    expect(find.text('my_flutter_app'), findsOneWidget);
    expect(find.textContaining('已将'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scanning shows actual current path, scan failure omits numeric total', (tester) async {
    final gate = Completer<void>();
    final backend = FakeBackend()..gate = gate..scanFailure = 'Access denied';
    await pumpApp(tester, backend, configured: true);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('/projects/current-project'), findsOneWidget);
    expect(find.text('可清理空间  0 B'), findsNothing);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('Access denied'), findsOneWidget);
    expect(find.text('无法读取大小'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cleaner/demo_mode.dart';
import 'package:flutter_cleaner/gen/assets.gen.dart';
import 'package:flutter_cleaner/l10n/l10n.dart';
import 'package:flutter_cleaner/riverpod/project.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoPage extends HookConsumerWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = useState('');
    useEffect(() {
      var mounted = true;
      PackageInfo.fromPlatform().then((info) {
        if (mounted) version.value = info.version;
      });
      return () { mounted = false; };
    }, const []);
    final directory = ref.watch(sCacheDirProvider);
    final busy = ref.watch(projectStateProvider) == ProjectStateType.loading || ref.watch(cleanupBusyProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    Future<void> selectDirectory() async {
      if (kDemoMode) return ref.read(projectListProvider.notifier).refresh(kDemoDirectory);
      try {
        final selected = await FilePicker.getDirectoryPath(dialogTitle: l10n.chooseProjectFolder);
        if (selected == null) return;
        final bookmark = await SecureBookmarks().bookmark(File(selected));
        await sCacheBookmark.write(bookmark);
        ref.read(sCacheDirProvider.notifier).update(selected);
        await ref.read(projectListProvider.notifier).refresh(selected);
      } catch (error) {
        ref.read(operationErrorProvider.notifier).state = '${l10n.errorFolderAccess}\n$error';
      }
    }
    Future<void> openLink(String url) async {
      try {
        if (!await launchUrl(Uri.parse(url))) throw StateError(l10n.errorOpenLink(url));
      } catch (error) {
        ref.read(operationErrorProvider.notifier).state = '$error';
      }
    }
    return Container(
      key: const ValueKey('information-pane'), width: 228,
      color: dark ? const Color(0xFF1E1E1E) : const Color(0xFFF6F6F6),
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Assets.logo.svg(width: 32, height: 32),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Cleaner for Flutter', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text(version.value.isEmpty ? '' : 'v${version.value}',
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ])),
        ]),
        const SizedBox(height: 36),
        Text(l10n.flutterProjects, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(directory.isEmpty ? l10n.chooseFolderPrompt : l10n.projectFolder,
            style: TextStyle(fontSize: 11, height: 1.6, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        if (directory.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6),
          child: Tooltip(message: directory, child: Text(directory, maxLines: 3, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, height: 1.5)))),
        const SizedBox(height: 20),
        SizedBox(height: 34, child: directory.isEmpty
          ? FilledButton(onPressed: busy ? null : selectDirectory, child: Text(l10n.chooseFolder, style: const TextStyle(fontSize: 12)))
          : OutlinedButton(onPressed: busy ? null : selectDirectory, child: Text(l10n.chooseFolder, style: const TextStyle(fontSize: 12)))),
        const SizedBox(height: 8),
        SizedBox(height: 34, child: OutlinedButton(
          onPressed: directory.isEmpty || busy ? null : () => ref.read(projectListProvider.notifier).refresh(directory),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.refresh_rounded, size: 15), const SizedBox(width: 6),
            Text(l10n.rescan, style: const TextStyle(fontSize: 12)),
          ]),
        )),
        const Spacer(),
        Row(children: [
          IconButton(tooltip: l10n.viewSourceCode, iconSize: 16,
            icon: const FaIcon(FontAwesomeIcons.github, size: 16),
            onPressed: () => openLink('https://github.com/xcc3641/flutter_cleaner')),
          IconButton(tooltip: 'X', iconSize: 16,
            icon: const FaIcon(FontAwesomeIcons.xTwitter, size: 16),
            onPressed: () => openLink('https://x.com/Lumosous')),
        ]),
      ]),
    );
  }
}

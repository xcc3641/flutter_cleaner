import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cleaner/foundation/preferences/keys.dart';
import 'package:flutter_cleaner/gen/assets.gen.dart';
import 'package:flutter_cleaner/riverpod/project.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_use/flutter_use.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;

class InfoPage extends HookConsumerWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = SecureBookmarks();
    final version = useState("");
    final dirList = ref.watch(cacheDirListProvider);

    useEffectOnce(() {
      final packageInfo = PackageInfo.fromPlatform();
      packageInfo.then((value) {
        version.value = value.version;
      });
      
      Future.microtask(() {
        final oldDir = ref.read(cacheDirProvider);
        if (oldDir.isNotEmpty && !dirList.contains(oldDir)) {
          ref.read(cacheDirListProvider.notifier).update([...dirList, oldDir]);
        }
      });
      
      return null;
    });

    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 5),
              Assets.logo.svg(width: 40, height: 40),
              const SizedBox(width: 8),
              const Text(
                'Cleaner',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            'PROJECT DIRECTORIES',
            style: ShadTheme.of(context).textTheme.muted.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: dirList.length,
              itemBuilder: (context, index) {
                final dir = dirList[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Tooltip(
                            message: dir,
                            child: Text(
                              path.basename(dir),
                              overflow: TextOverflow.ellipsis,
                              style: ShadTheme.of(context).textTheme.small,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            final newList = List<String>.from(dirList)..removeAt(index);
                            ref.read(cacheDirListProvider.notifier).update(newList);
                            ref.read(projectListProvider.notifier).refresh(newList);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          ShadButton.outline(
            width: double.maxFinite,
            child: const Text('Add Directory'),
            onPressed: () async {
              String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
              if (selectedDirectory != null) {
                if (Platform.isMacOS) {
                  selectedDirectory = selectedDirectory.replaceFirst('/Volumes/Macintosh HD', '');
                  final bookmark = await bookmarks.bookmark(File(selectedDirectory));
                  await sCacheBookmark.write(bookmark);
                }
                
                if (!dirList.contains(selectedDirectory)) {
                  final newList = [...dirList, selectedDirectory];
                  ref.read(cacheDirListProvider.notifier).update(newList);
                  ref.read(projectListProvider.notifier).refresh(newList);
                }
              }
            },
          ),
          const SizedBox(height: 8),
          ShadButton.outline(
            width: double.maxFinite,
            enabled: dirList.isNotEmpty,
            onPressed: () {
              ref.read(projectListProvider.notifier).refresh(dirList);
            },
            child: const Text('Refresh All'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ShadButton.outline(
                size: ShadButtonSize.sm,
                leading: const Icon(FontAwesomeIcons.github, size: 16),
                onPressed: () {
                  launchUrl(Uri.parse('https://github.com/xcc3641/flutter_cleaner'));
                },
              ),
              const SizedBox(width: 8),
              ShadButton.outline(
                size: ShadButtonSize.sm,
                leading: const Icon(FontAwesomeIcons.xTwitter, size: 16),
                onPressed: () {
                  launchUrl(Uri.parse('https://x.com/Lumosous'));
                },
              ),
              const Spacer(),
              Text(
                'v${version.value}',
                style: ShadTheme.of(context).textTheme.muted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

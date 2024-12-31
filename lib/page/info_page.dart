import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cleaner/foundation/logger.dart';
import 'package:flutter_cleaner/foundation/preferences/prefs.dart';
import 'package:flutter_cleaner/gen/assets.gen.dart';
import 'package:flutter_cleaner/riverpod/project.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_use/flutter_use.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences_riverpod/shared_preferences_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoPage extends HookConsumerWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = SecureBookmarks();
    final version = useState("");

    useEffectOnce(() {
      final packageInfo = PackageInfo.fromPlatform();
      packageInfo.then((value) {
        version.value = value.version;
      });
      return null;
    });

    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              const SizedBox(width: 5),
              Assets.logo.svg(width: 40, height: 40),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Flutter Cleaner'),
                ],
              ),
              const SizedBox(width: 5),
            ],
          ),
          const SizedBox(height: 60),
          const Spacer(),
          ShadButton.outline(
            width: double.maxFinite,
            child: const Text('Select Directory'),
            onPressed: () async {
              String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
              if (selectedDirectory != null) {
                selectedDirectory = selectedDirectory.replaceFirst('/Volumes/Macintosh HD', '');
                final bookmark = await bookmarks.bookmark(File(selectedDirectory));
                await sCacheBookmark.write(bookmark);
                ref.read(sCacheDirProvider.notifier).update(selectedDirectory);
                ref.read(projectListProvider.notifier).refresh(selectedDirectory);
                logger.d('selectedDirectory:[$selectedDirectory] bookmark:$bookmark');
              }
            },
          ),
          ShadButton.outline(
            width: double.maxFinite,
            enabled: ref.watch(sCacheDirProvider).isNotEmpty,
            onPressed: () {
              ref.read(projectListProvider.notifier).refresh(ref.read(sCacheDirProvider));
            },
            child: const Text('Refresh Directory'),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ShadButton.outline(
                size: ShadButtonSize.sm,
                icon: const Icon(
                  FontAwesomeIcons.github,
                  size: 16,
                ),
                onPressed: () {
                  launchUrl(Uri.parse('https://github.com/xcc3641/flutter_cleaner'));
                },
              ),
              // https://x.com/Lumosous
              ShadButton.outline(
                size: ShadButtonSize.sm,
                icon: const Icon(
                  FontAwesomeIcons.xTwitter,
                  size: 16,
                ),
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

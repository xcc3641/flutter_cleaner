import 'package:flutter/material.dart';
import 'package:flutter_cleaner/foundation/preferences/prefs.dart';
import 'package:flutter_cleaner/page/info_page.dart';
import 'package:flutter_cleaner/page/file_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await Pref.awaitReady();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(
      child: ShadApp(
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.light,
        home: HomePage(),
      ),
    );
  }
}

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          const InfoPage(),
          Container(width: 1, color: Colors.grey[300]),
          const Expanded(child: FilePage()),
        ],
      ),
    );
  }
}

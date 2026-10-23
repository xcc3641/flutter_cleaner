import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_cleaner/demo_mode.dart';
import 'package:flutter_cleaner/foundation/preferences/prefs.dart';
import 'package:flutter_cleaner/l10n/l10n.dart';
import 'package:flutter_cleaner/page/info_page.dart';
import 'package:flutter_cleaner/page/file_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

const accentColor = Color(0xFF007AFF);
const dangerColor = Color(0xFFFF3B30);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await (kDemoMode ? prepareDemoPreferences() : Pref.awaitReady());
  const options = WindowOptions(
    size: Size(900, 620), minimumSize: Size(760, 520),
    center: true, backgroundColor: Colors.transparent,
    skipTaskbar: false, title: 'Cleaner for Flutter',
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true, brightness: brightness,
      colorScheme: ColorScheme.fromSeed(seedColor: accentColor, brightness: brightness)
          .copyWith(primary: accentColor, error: dangerColor,
              surface: dark ? const Color(0xFF141414) : Colors.white),
      scaffoldBackgroundColor: dark ? const Color(0xFF141414) : Colors.white,
      dividerColor: dark ? const Color(0xFF333333) : const Color(0xFFE3E3E3),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(
        minimumSize: const Size(0, 34), padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 34), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      )),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        minimumSize: const Size(0, 34), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      )),
    );
  }

  @override
  Widget build(BuildContext context) => ProviderScope(child: MaterialApp(
    title: 'Cleaner for Flutter', debugShowCheckedModeBanner: false,
    themeMode: ThemeMode.system, theme: _theme(Brightness.light), darkTheme: _theme(Brightness.dark),
    // Follows the system language; anything other than Chinese falls back to English.
    localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
    supportedLocales: AppLocalizations.supportedLocales,
    home: const HomePage(),
  ));
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(body: Row(children: [
    const InfoPage(),
    VerticalDivider(width: 1, thickness: 1, color: Theme.of(context).dividerColor),
    const Expanded(child: FilePage()),
  ]));
}

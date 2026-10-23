import 'package:flutter/widgets.dart';
import 'package:flutter_cleaner/l10n/app_localizations.dart';

export 'package:flutter_cleaner/l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// For code without a [BuildContext] (file operations, providers). Resolves the
/// system locale the same way [WidgetsApp] does, so messages match the UI.
AppLocalizations get systemL10n => lookupAppLocalizations(basicLocaleListResolution(
    WidgetsBinding.instance.platformDispatcher.locales, AppLocalizations.supportedLocales));

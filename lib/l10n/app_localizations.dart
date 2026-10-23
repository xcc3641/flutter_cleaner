import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @flutterProjects.
  ///
  /// In en, this message translates to:
  /// **'Flutter Projects'**
  String get flutterProjects;

  /// No description provided for @projectFolder.
  ///
  /// In en, this message translates to:
  /// **'Project Folder'**
  String get projectFolder;

  /// No description provided for @chooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose Folder'**
  String get chooseFolder;

  /// No description provided for @chooseProjectFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose Project Folder'**
  String get chooseProjectFolder;

  /// No description provided for @chooseFolderPrompt.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder containing Flutter projects to start scanning.'**
  String get chooseFolderPrompt;

  /// No description provided for @rescan.
  ///
  /// In en, this message translates to:
  /// **'Rescan'**
  String get rescan;

  /// No description provided for @viewSourceCode.
  ///
  /// In en, this message translates to:
  /// **'View Source Code'**
  String get viewSourceCode;

  /// No description provided for @cleanableSpace.
  ///
  /// In en, this message translates to:
  /// **'Cleanable Space'**
  String get cleanableSpace;

  /// No description provided for @cleanableSpaceTotal.
  ///
  /// In en, this message translates to:
  /// **'Cleanable: {size}'**
  String cleanableSpaceTotal(String size);

  /// No description provided for @sizeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Size Unavailable'**
  String get sizeUnavailable;

  /// No description provided for @moveToTrashHint.
  ///
  /// In en, this message translates to:
  /// **'Move to Trash (Recoverable)'**
  String get moveToTrashHint;

  /// No description provided for @deletePermanentlyHint.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently (Not Recoverable)'**
  String get deletePermanentlyHint;

  /// No description provided for @deleteImmediately.
  ///
  /// In en, this message translates to:
  /// **'Delete Immediately'**
  String get deleteImmediately;

  /// No description provided for @scanningProjects.
  ///
  /// In en, this message translates to:
  /// **'Scanning Flutter projects…'**
  String get scanningProjects;

  /// No description provided for @scanFailed.
  ///
  /// In en, this message translates to:
  /// **'Scan failed. Check folder permissions and try again.'**
  String get scanFailed;

  /// No description provided for @noBuildCaches.
  ///
  /// In en, this message translates to:
  /// **'No build caches to clean.'**
  String get noBuildCaches;

  /// No description provided for @noBuildCachesDetail.
  ///
  /// In en, this message translates to:
  /// **'No projects in this folder have build files to clean.'**
  String get noBuildCachesDetail;

  /// No description provided for @foundProjects.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Found 1 cleanable project} other{Found {count} cleanable projects}}'**
  String foundProjects(int count);

  /// No description provided for @moveToTrash.
  ///
  /// In en, this message translates to:
  /// **'Move to Trash'**
  String get moveToTrash;

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deletePermanently;

  /// No description provided for @moveToTrashTitle.
  ///
  /// In en, this message translates to:
  /// **'Move Build Files to Trash?'**
  String get moveToTrashTitle;

  /// No description provided for @deletePermanentlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete These Files Permanently?'**
  String get deletePermanentlyTitle;

  /// No description provided for @moveToTrashMessage.
  ///
  /// In en, this message translates to:
  /// **'The build files in “{name}” will be moved to the Trash. You can restore them from the Trash.'**
  String moveToTrashMessage(String name);

  /// No description provided for @deletePermanentlyMessage.
  ///
  /// In en, this message translates to:
  /// **'The build files in “{name}” will be permanently deleted and can\'t be restored from the Trash.'**
  String deletePermanentlyMessage(String name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @movedToTrash.
  ///
  /// In en, this message translates to:
  /// **'Moved the build files of {name} to the Trash.'**
  String movedToTrash(String name);

  /// No description provided for @showInFinder.
  ///
  /// In en, this message translates to:
  /// **'Show in Finder'**
  String get showInFinder;

  /// No description provided for @errorFolderAccess.
  ///
  /// In en, this message translates to:
  /// **'Can\'t access this folder. Choose the folder again and allow access.'**
  String get errorFolderAccess;

  /// No description provided for @errorOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open {url}'**
  String errorOpenLink(String url);

  /// No description provided for @errorCleanup.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t clean up: {error}'**
  String errorCleanup(String error);

  /// No description provided for @errorReveal.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t show in Finder: {error}'**
  String errorReveal(String error);

  /// No description provided for @errorScan.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t scan: {error}'**
  String errorScan(String error);

  /// No description provided for @errorNotScanned.
  ///
  /// In en, this message translates to:
  /// **'This folder hasn\'t been scanned. Rescan and try again.'**
  String get errorNotScanned;

  /// No description provided for @errorOutsideSelection.
  ///
  /// In en, this message translates to:
  /// **'This folder is outside the selected folder. Rescan and try again.'**
  String get errorOutsideSelection;

  /// No description provided for @errorReplacedOrLinked.
  ///
  /// In en, this message translates to:
  /// **'This folder was replaced or contains a symbolic link. Rescan and try again.'**
  String get errorReplacedOrLinked;

  /// No description provided for @errorChangedSinceScan.
  ///
  /// In en, this message translates to:
  /// **'This folder changed after it was scanned. Rescan and try again.'**
  String get errorChangedSinceScan;

  /// No description provided for @errorBuildNotDirectory.
  ///
  /// In en, this message translates to:
  /// **'The build folder isn\'t a regular folder (symbolic links aren\'t allowed).'**
  String get errorBuildNotDirectory;

  /// No description provided for @errorIdentityUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t verify the folder\'s identity.'**
  String get errorIdentityUnavailable;

  /// No description provided for @errorIdentityNotVerified.
  ///
  /// In en, this message translates to:
  /// **'The folder\'s identity hasn\'t been verified. Rescan and try again.'**
  String get errorIdentityNotVerified;

  /// No description provided for @errorSymlinkNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Symbolic links and non-canonical folders aren\'t allowed. Rescan and try again.'**
  String get errorSymlinkNotAllowed;

  /// No description provided for @errorMissingIdentity.
  ///
  /// In en, this message translates to:
  /// **'The folder\'s identity is missing.'**
  String get errorMissingIdentity;

  /// No description provided for @errorMissingScanIdentity.
  ///
  /// In en, this message translates to:
  /// **'The scanned folder\'s identity is missing. Rescan and try again.'**
  String get errorMissingScanIdentity;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

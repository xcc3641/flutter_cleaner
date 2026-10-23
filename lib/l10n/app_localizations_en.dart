// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get flutterProjects => 'Flutter Projects';

  @override
  String get projectFolder => 'Project Folder';

  @override
  String get chooseFolder => 'Choose Folder';

  @override
  String get chooseProjectFolder => 'Choose Project Folder';

  @override
  String get chooseFolderPrompt =>
      'Choose a folder containing Flutter projects to start scanning.';

  @override
  String get rescan => 'Rescan';

  @override
  String get viewSourceCode => 'View Source Code';

  @override
  String get cleanableSpace => 'Cleanable Space';

  @override
  String cleanableSpaceTotal(String size) {
    return 'Cleanable: $size';
  }

  @override
  String get sizeUnavailable => 'Size Unavailable';

  @override
  String get moveToTrashHint => 'Move to Trash (Recoverable)';

  @override
  String get deletePermanentlyHint => 'Delete Permanently (Not Recoverable)';

  @override
  String get deleteImmediately => 'Delete Immediately';

  @override
  String get scanningProjects => 'Scanning Flutter projects…';

  @override
  String get scanFailed =>
      'Scan failed. Check folder permissions and try again.';

  @override
  String get noBuildCaches => 'No build caches to clean.';

  @override
  String get noBuildCachesDetail =>
      'No projects in this folder have build files to clean.';

  @override
  String foundProjects(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Found $count cleanable projects',
      one: 'Found 1 cleanable project',
    );
    return '$_temp0';
  }

  @override
  String get moveToTrash => 'Move to Trash';

  @override
  String get deletePermanently => 'Delete Permanently';

  @override
  String get moveToTrashTitle => 'Move Build Files to Trash?';

  @override
  String get deletePermanentlyTitle => 'Delete These Files Permanently?';

  @override
  String moveToTrashMessage(String name) {
    return 'The build files in “$name” will be moved to the Trash. You can restore them from the Trash.';
  }

  @override
  String deletePermanentlyMessage(String name) {
    return 'The build files in “$name” will be permanently deleted and can\'t be restored from the Trash.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String movedToTrash(String name) {
    return 'Moved the build files of $name to the Trash.';
  }

  @override
  String get showInFinder => 'Show in Finder';

  @override
  String get errorFolderAccess =>
      'Can\'t access this folder. Choose the folder again and allow access.';

  @override
  String errorOpenLink(String url) {
    return 'Couldn\'t open $url';
  }

  @override
  String errorCleanup(String error) {
    return 'Couldn\'t clean up: $error';
  }

  @override
  String errorReveal(String error) {
    return 'Couldn\'t show in Finder: $error';
  }

  @override
  String errorScan(String error) {
    return 'Couldn\'t scan: $error';
  }

  @override
  String get errorNotScanned =>
      'This folder hasn\'t been scanned. Rescan and try again.';

  @override
  String get errorOutsideSelection =>
      'This folder is outside the selected folder. Rescan and try again.';

  @override
  String get errorReplacedOrLinked =>
      'This folder was replaced or contains a symbolic link. Rescan and try again.';

  @override
  String get errorChangedSinceScan =>
      'This folder changed after it was scanned. Rescan and try again.';

  @override
  String get errorBuildNotDirectory =>
      'The build folder isn\'t a regular folder (symbolic links aren\'t allowed).';

  @override
  String get errorIdentityUnavailable =>
      'Couldn\'t verify the folder\'s identity.';

  @override
  String get errorIdentityNotVerified =>
      'The folder\'s identity hasn\'t been verified. Rescan and try again.';

  @override
  String get errorSymlinkNotAllowed =>
      'Symbolic links and non-canonical folders aren\'t allowed. Rescan and try again.';

  @override
  String get errorMissingIdentity => 'The folder\'s identity is missing.';

  @override
  String get errorMissingScanIdentity =>
      'The scanned folder\'s identity is missing. Rescan and try again.';
}

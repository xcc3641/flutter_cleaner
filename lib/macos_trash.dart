import 'dart:io' show Platform, FileSystemException;
import 'package:flutter/services.dart';
import 'package:flutter_cleaner/l10n/l10n.dart';

class MacOSTrash {
  static const MethodChannel _channel = MethodChannel('macos_trash');

  /// Maps the plugin's stable error codes to localized text; system errors
  /// (CLEANUP_ERROR) keep the native localized description.
  static String messageFor(PlatformException e, AppLocalizations l10n) => switch (e.code) {
    'REPLACED_OR_LINKED' => l10n.errorReplacedOrLinked,
    'OUT_OF_SCOPE' => l10n.errorOutsideSelection,
    'SYMLINK_OR_NONCANONICAL' => l10n.errorSymlinkNotAllowed,
    'MISSING_IDENTITY' => l10n.errorMissingIdentity,
    'MISSING_SCAN_IDENTITY' => l10n.errorMissingScanIdentity,
    'CHANGED_SINCE_SCAN' => l10n.errorChangedSinceScan,
    _ => e.message ?? e.code,
  };

  static Future<T?> _invoke<T>(Future<T?> Function() call, String path) async {
    try {
      return await call();
    } on PlatformException catch (e) {
      final details = e.details;
      throw FileSystemException(messageFor(e, systemL10n),
          details is String && details.isNotEmpty ? details : path);
    }
  }

  static Future<Map<String, dynamic>> captureIdentity(String root, String project, String build) async {
    final identity = await _invoke(() => _channel.invokeMapMethod<String, dynamic>('inspectBuild', {
      'root': root, 'project': project, 'build': build,
    }), build);
    if (identity == null) throw FileSystemException(systemL10n.errorIdentityUnavailable, build);
    return identity;
  }

  static Future<void> moveToTrash(String filePath, {Map<String, dynamic>? identity}) =>
      _cleanup('moveToTrash', filePath, identity);

  static Future<void> permanentlyDelete(String filePath, {required Map<String, dynamic> identity}) =>
      _cleanup('permanentlyDelete', filePath, identity);

  static Future<void> _cleanup(String method, String filePath, Map<String, dynamic>? identity) async {
    if (!Platform.isMacOS) throw UnsupportedError('MacOSTrash is only supported on macOS');
    if (identity == null) throw FileSystemException(systemL10n.errorIdentityNotVerified, filePath);
    await _invoke(() => _channel.invokeMethod<void>(method, {'path': filePath, 'identity': identity}), filePath);
  }

  /// Selects [filePath] in Finder via NSWorkspace (works inside the sandbox).
  static Future<void> reveal(String filePath) async {
    if (!Platform.isMacOS) throw UnsupportedError('MacOSTrash is only supported on macOS');
    await _invoke(() => _channel.invokeMethod<void>('reveal', {'path': filePath}), filePath);
  }
}

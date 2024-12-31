import 'dart:io' show Platform;
import 'package:flutter/services.dart';

class MacOSTrash {
  static const MethodChannel _channel = MethodChannel('macos_trash');

  static Future<void> moveToTrash(String filePath) async {
    if (!Platform.isMacOS) {
      throw UnsupportedError('MacOSTrash is only supported on macOS');
    }

    try {
      await _channel.invokeMethod('moveToTrash', filePath);
    } on PlatformException catch (e) {
      throw Exception('Failed to move file to trash: ${e.message}');
    }
  }
}
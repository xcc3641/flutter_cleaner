import 'dart:convert';

import 'package:flutter_cleaner/foundation/preferences/typed.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Pref {
  Pref._();

  static late SharedPreferences instance;

  static Future<void> awaitReady() async {
    instance = await SharedPreferences.getInstance();
  }

  /// 默认行为
  static PrefKey<T?> nullable<T>(String key) => NullablePrefKey(key);

  /// 非空数据，用 [defaultValue] 兜底
  static PrefKey<T> nonNull<T>(String key, T defaultValue) => NonNullPrefKey(
        NullablePrefKey<T>(key),
        defaultValue: defaultValue,
      );

  /// 把对象转成 String 存储
  static PrefKey<T?> transform<T>(
    String key, {
    required String Function(T) toString,
    required T Function(String) fromString,
  }) =>
      TransformPrefKey(
        NullablePrefKey(key),
        dataFromString: (s) => fromString(s),
        dataToString: (d) => toString(d),
      );

  /// 把对象转成 JSON 存储
  static PrefKey<T?> json<T>(
    String key, {
    required Map<String, dynamic> Function(T) toJson,
    required T Function(Map<String, dynamic>) fromJson,
  }) =>
      TransformPrefKey(
        NullablePrefKey(key),
        dataFromString: (s) => fromJson(jsonDecode(s)),
        dataToString: (d) => jsonEncode(toJson(d)),
      );
}

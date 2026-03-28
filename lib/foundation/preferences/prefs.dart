import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cleaner/foundation/ext.dart';

abstract class PrefKey<T> {
  const PrefKey();
  String get key;
  Future<bool> write(T value);
  T read();
  Future<bool> remove();
  bool exists();
}

class NullablePrefKey<T> extends PrefKey<T?> {
  @override
  final String key;
  const NullablePrefKey(this.key);

  @override
  Future<bool> write(T? value) {
    if (value == null) {
      return remove();
    }
    final p = Pref.instance;
    if (T == bool) {
      return p.setBool(key, value as bool);
    } else if (T == int) {
      return p.setInt(key, value as int);
    } else if (T == double) {
      return p.setDouble(key, value as double);
    } else if (T == String) {
      return p.setString(key, value as String);
    } else if (_isListString()) {
      return p.setStringList(key, (value as List).cast<String>().toList());
    } else {
      assert(false, "write was called with an unsupported type: $T");
      return Future.value(false);
    }
  }

  bool _isListString() {
    final typeStr = T.toString();
    return typeStr == 'List<String>' || typeStr == 'List<String>?';
  }

  @override
  T? read() {
    final p = Pref.instance;
    if (T == bool) {
      return p.getBool(key) as T?;
    } else if (T == int) {
      return p.getInt(key) as T?;
    } else if (T == double) {
      return p.getDouble(key) as T?;
    } else if (T == String) {
      return p.getString(key) as T?;
    } else if (_isListString()) {
      final list = p.getStringList(key);
      return list?.cast<String>() as T?;
    } else {
      final val = p.get(key);
      if (val is List && _isListString()) {
        return val.cast<String>() as T?;
      }
      return val as T?;
    }
  }

  @override
  Future<bool> remove() {
    return Pref.instance.remove(key);
  }

  @override
  bool exists() {
    return Pref.instance.containsKey(key);
  }
}

class NonNullPrefKey<T> extends PrefKeyDelegate<T?, T> {
  final T defaultValue;

  const NonNullPrefKey(super.delegate, {required this.defaultValue});

  @override
  T read() => delegate.read() ?? defaultValue;

  @override
  Future<bool> write(T value) => delegate.write(value);
}

class TransformPrefKey<T> extends PrefKeyDelegate<String?, T?> {
  final String Function(T) dataToString;
  final T? Function(String) dataFromString;

  const TransformPrefKey(
    super.delegate, {
    required this.dataToString,
    required this.dataFromString,
  });

  @override
  T? read() {
    final s = delegate.read();
    if (s == null) return null;
    return runCatching<T?>(
      func: () => dataFromString(s),
      desc: "TransformPrefKey['$key'] dataFromString",
    );
  }

  @override
  Future<bool> write(T? value) {
    final s = value == null
        ? null
        : runCatching(
            func: () => dataToString(value),
            desc: "TransformPrefKey['$key'] dataToString",
          );
    return delegate.write(s);
  }
}

abstract class PrefKeyDelegate<T, F> extends PrefKey<F> {
  final PrefKey<T> delegate;

  const PrefKeyDelegate(this.delegate);

  @override
  String get key => delegate.key;

  @override
  bool exists() => delegate.exists();

  @override
  Future<bool> remove() => delegate.remove();
}

class Pref {
  Pref._();

  static late SharedPreferences instance;

  static Future<void> awaitReady() async {
    instance = await SharedPreferences.getInstance();
  }

  static PrefKey<T?> nullable<T>(String key) => NullablePrefKey(key);

  static PrefKey<T> nonNull<T>(String key, T defaultValue) => NonNullPrefKey(
        NullablePrefKey<T>(key),
        defaultValue: defaultValue,
      );

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

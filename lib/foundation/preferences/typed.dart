import 'package:flutter_cleaner/foundation/ext.dart';
import 'package:flutter_cleaner/foundation/preferences/prefs.dart';

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
    assert(
      value != null,
      "You can't write null to SharedPreferences. Use key.remove() instead.",
    );
    final p = Pref.instance;
    switch (T) {
      case bool:
        return p.setBool(key, value as bool);
      case int:
        return p.setInt(key, value as int);
      case double:
        return p.setDouble(key, value as double);
      case String:
        return p.setString(key, value as String);
      case const (List<String>):
        return p.setStringList(key, value as List<String>);
      default:
        assert(false, "write was called with an unsupported type: $T");
        return Future.value(false);
    }
  }

  @override
  T? read() {
    final p = Pref.instance;
    switch (T) {
      case bool:
        return p.getBool(key) as T?;
      case int:
        return p.getInt(key) as T?;
      case double:
        return p.getDouble(key) as T?;
      case String:
        return p.getString(key) as T?;
      case const (List<String>):
        return p.getStringList(key) as T?;
      default:
        return p.get(key) as T?;
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

/// 底层存储数据类型为 [T], 上次交互数据类型为 [F]
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

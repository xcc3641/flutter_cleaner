
import 'package:flutter_cleaner/foundation/logger.dart';

extension ListExtension<T> on List<T> {
  List<T> count(int n) {
    return List.generate(n, (index) => this[index]);
  }
}

T? runCatching<T>({required T Function() func, String? desc}) {
  try {
    return func();
  } catch (e, s) {
    logger.w("error in runCatching: ${desc ?? ""}", error: e, stackTrace: s);
    return null;
  }
}

Future<T?> runCatchingFuture<T>({required Future<T> future, String? desc}) async {
  try {
    return await future;
  } catch (e, s) {
    logger.w("error in runCatching: ${desc ?? ""}", error: e, stackTrace: s);
    return null;
  }
}

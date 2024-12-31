import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final logger = createTagLogger();

Logger createTagLogger() {
  return Logger(
    printer: HybridPrinter(
      SimplePrinter(printTime: true, colors: false),
      error: PrettyPrinter(colors: false),
    ),
    filter: ProductionFilter()..level = kReleaseMode ? Level.off : Level.debug,
  );
}

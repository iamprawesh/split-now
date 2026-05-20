import 'package:firebase_crashlytics/firebase_crashlytics.dart';

T safeParse<T>(T Function() parseFn, {String? context}) {
  try {
    return parseFn();
  } catch (e, s) {
    FirebaseCrashlytics.instance.recordError(
      e,
      s,
      reason: context ?? 'ModelParseError',
      fatal: false,
    );
    rethrow;
  }
}

void logError(Object error, StackTrace stack, {String? context}) {
  FirebaseCrashlytics.instance.recordError(
    error,
    stack,
    reason: context,
    fatal: false,
  );
}

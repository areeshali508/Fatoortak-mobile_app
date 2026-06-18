import 'dart:async';
import 'package:flutter/foundation.dart';

/// Performance utilities for optimizing app performance
class PerformanceUtils {
  /// Debounce function calls to reduce unnecessary operations
  /// Useful for search inputs, scroll events, etc.
  static Timer? _debounceTimer;

  static void debounce({
    required VoidCallback callback,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, callback);
  }

  /// Throttle function calls to limit execution frequency
  /// Useful for scroll listeners, resize events, etc.
  static DateTime? _lastThrottleTime;

  static void throttle({
    required VoidCallback callback,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    final DateTime now = DateTime.now();
    if (_lastThrottleTime == null ||
        now.difference(_lastThrottleTime!) > duration) {
      _lastThrottleTime = now;
      callback();
    }
  }

  /// Measure execution time of a function (debug mode only)
  static Future<T> measureAsync<T>({
    required String label,
    required Future<T> Function() operation,
  }) async {
    if (!kDebugMode) {
      return operation();
    }

    final Stopwatch stopwatch = Stopwatch()..start();
    try {
      final T result = await operation();
      stopwatch.stop();
      debugPrint('⏱️ $label took ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ $label failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      rethrow;
    }
  }

  /// Measure execution time of a synchronous function (debug mode only)
  static T measureSync<T>({
    required String label,
    required T Function() operation,
  }) {
    if (!kDebugMode) {
      return operation();
    }

    final Stopwatch stopwatch = Stopwatch()..start();
    try {
      final T result = operation();
      stopwatch.stop();
      debugPrint('⏱️ $label took ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ $label failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      rethrow;
    }
  }

  /// Cancel any pending debounce timers
  static void cancelDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  /// Reset throttle timer
  static void resetThrottle() {
    _lastThrottleTime = null;
  }
}

/// Mixin for widgets that need debouncing
mixin DebounceMixin {
  Timer? _debounceTimer;

  void debounce(VoidCallback callback, {Duration delay = const Duration(milliseconds: 500)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  void cancelDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  void disposeDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }
}

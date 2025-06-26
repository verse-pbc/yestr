import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Performance monitoring service for tracking app performance metrics
class PerformanceMonitor {
  static PerformanceMonitor? _instance;
  final Logger _logger = Logger();
  
  // Metrics storage
  final Map<String, PerformanceMetric> _metrics = {};
  final Map<String, Stopwatch> _activeTimers = {};
  
  // Performance thresholds
  static const Duration _slowOperationThreshold = Duration(seconds: 1);
  static const Duration _criticalOperationThreshold = Duration(seconds: 3);
  
  // Singleton pattern
  static PerformanceMonitor get instance {
    _instance ??= PerformanceMonitor._internal();
    return _instance!;
  }
  
  PerformanceMonitor._internal() {
    // Start periodic reporting in debug mode
    if (kDebugMode) {
      Timer.periodic(const Duration(minutes: 5), (_) {
        reportMetrics();
      });
    }
  }
  
  /// Start timing an operation
  void startOperation(String operationName, {Map<String, dynamic>? metadata}) {
    _activeTimers[operationName] = Stopwatch()..start();
    
    _logger.d('Started operation: $operationName', time: DateTime.now());
  }
  
  /// End timing an operation
  void endOperation(String operationName, {bool success = true, String? error}) {
    final stopwatch = _activeTimers.remove(operationName);
    if (stopwatch == null) {
      _logger.w('No active timer found for operation: $operationName');
      return;
    }
    
    stopwatch.stop();
    final duration = stopwatch.elapsed;
    
    // Record metric
    _recordMetric(operationName, duration, success: success, error: error);
    
    // Log slow operations
    if (duration > _criticalOperationThreshold) {
      _logger.w('CRITICAL: Slow operation detected: $operationName took ${duration.inMilliseconds}ms');
    } else if (duration > _slowOperationThreshold) {
      _logger.d('SLOW: Operation $operationName took ${duration.inMilliseconds}ms');
    }
  }
  
  /// Record a metric
  void _recordMetric(
    String name,
    Duration duration, {
    bool success = true,
    String? error,
  }) {
    _metrics[name] ??= PerformanceMetric(name: name);
    _metrics[name]!.record(duration, success: success, error: error);
  }
  
  /// Track a counter metric
  void incrementCounter(String name, {int value = 1}) {
    _metrics[name] ??= PerformanceMetric(name: name, isCounter: true);
    _metrics[name]!.incrementCounter(value);
  }
  
  /// Track memory usage
  void trackMemoryUsage() {
    // This is a placeholder - in production, you'd use proper memory profiling
    // For now, just log that we're tracking
    _logger.d('Memory tracking checkpoint');
  }
  
  /// Get metrics summary
  Map<String, MetricsSummary> getMetricsSummary() {
    final summary = <String, MetricsSummary>{};
    
    for (final entry in _metrics.entries) {
      summary[entry.key] = entry.value.getSummary();
    }
    
    return summary;
  }
  
  /// Report current metrics
  void reportMetrics() {
    if (_metrics.isEmpty) return;
    
    _logger.i('=== Performance Metrics Report ===');
    
    for (final entry in _metrics.entries) {
      final summary = entry.value.getSummary();
      
      if (summary.isCounter) {
        _logger.i('${entry.key}: ${summary.count} total');
      } else {
        _logger.i('''
${entry.key}:
  Count: ${summary.count}
  Success Rate: ${summary.successRate.toStringAsFixed(1)}%
  Avg Duration: ${summary.averageDuration.inMilliseconds}ms
  Min Duration: ${summary.minDuration.inMilliseconds}ms
  Max Duration: ${summary.maxDuration.inMilliseconds}ms
''');
      }
    }
    
    _logger.i('=================================');
  }
  
  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
    _activeTimers.clear();
  }
  
  /// Create a performance scope for automatic timing
  Future<T> measureAsync<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, dynamic>? metadata,
  }) async {
    startOperation(operationName, metadata: metadata);
    
    try {
      final result = await operation();
      endOperation(operationName, success: true);
      return result;
    } catch (e) {
      endOperation(operationName, success: false, error: e.toString());
      rethrow;
    }
  }
  
  /// Create a sync performance scope
  T measureSync<T>(
    String operationName,
    T Function() operation, {
    Map<String, dynamic>? metadata,
  }) {
    startOperation(operationName, metadata: metadata);
    
    try {
      final result = operation();
      endOperation(operationName, success: true);
      return result;
    } catch (e) {
      endOperation(operationName, success: false, error: e.toString());
      rethrow;
    }
  }
}

/// Performance metric tracking
class PerformanceMetric {
  final String name;
  final bool isCounter;
  final List<Duration> _durations = [];
  final List<DateTime> _timestamps = [];
  int _successCount = 0;
  int _failureCount = 0;
  int _counterValue = 0;
  final Map<String, int> _errors = {};
  
  PerformanceMetric({
    required this.name,
    this.isCounter = false,
  });
  
  void record(Duration duration, {bool success = true, String? error}) {
    if (isCounter) return;
    
    _durations.add(duration);
    _timestamps.add(DateTime.now());
    
    if (success) {
      _successCount++;
    } else {
      _failureCount++;
      if (error != null) {
        _errors[error] = (_errors[error] ?? 0) + 1;
      }
    }
    
    // Keep only last 1000 records
    if (_durations.length > 1000) {
      _durations.removeAt(0);
      _timestamps.removeAt(0);
    }
  }
  
  void incrementCounter(int value) {
    if (!isCounter) return;
    _counterValue += value;
  }
  
  MetricsSummary getSummary() {
    if (isCounter) {
      return MetricsSummary(
        name: name,
        isCounter: true,
        count: _counterValue,
        successRate: 100.0,
        averageDuration: Duration.zero,
        minDuration: Duration.zero,
        maxDuration: Duration.zero,
        errors: {},
      );
    }
    
    if (_durations.isEmpty) {
      return MetricsSummary(
        name: name,
        isCounter: false,
        count: 0,
        successRate: 0.0,
        averageDuration: Duration.zero,
        minDuration: Duration.zero,
        maxDuration: Duration.zero,
        errors: Map.from(_errors),
      );
    }
    
    final totalCount = _successCount + _failureCount;
    final successRate = totalCount > 0 ? (_successCount / totalCount) * 100 : 0.0;
    
    final totalMilliseconds = _durations.fold<int>(
      0,
      (sum, duration) => sum + duration.inMilliseconds,
    );
    final averageDuration = Duration(
      milliseconds: (totalMilliseconds / _durations.length).round(),
    );
    
    final sortedDurations = List<Duration>.from(_durations)
      ..sort((a, b) => a.compareTo(b));
    
    return MetricsSummary(
      name: name,
      isCounter: false,
      count: totalCount,
      successRate: successRate,
      averageDuration: averageDuration,
      minDuration: sortedDurations.first,
      maxDuration: sortedDurations.last,
      errors: Map.from(_errors),
    );
  }
}

/// Metrics summary
class MetricsSummary {
  final String name;
  final bool isCounter;
  final int count;
  final double successRate;
  final Duration averageDuration;
  final Duration minDuration;
  final Duration maxDuration;
  final Map<String, int> errors;
  
  MetricsSummary({
    required this.name,
    required this.isCounter,
    required this.count,
    required this.successRate,
    required this.averageDuration,
    required this.minDuration,
    required this.maxDuration,
    required this.errors,
  });
}
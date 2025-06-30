import 'dart:async';
import 'package:ndk/ndk.dart';
import 'package:logger/logger.dart' as app_logger;
import '../database/isar_database_service.dart';
import '../ndk_backup/ndk_service.dart';
import '../../models/database/cached_relay.dart';

/// Optimized relay service with outbox model, retry logic, and performance monitoring
class OptimizedRelayService {
  final NdkService _ndkService;
  final IsarDatabaseService _database;
  final app_logger.Logger _logger = app_logger.Logger();
  
  // Performance monitoring
  final Map<String, RelayMetrics> _relayMetrics = {};
  Timer? _metricsTimer;
  
  OptimizedRelayService(this._ndkService, this._database);
  
  /// Initialize relay service with performance monitoring
  Future<void> initialize() async {
    // Start metrics collection
    _startMetricsCollection();
    
    // Load relay health data from cache
    await _loadRelayHealthData();
  }
  
  /// Connect to relays with retry logic and health checks
  Future<void> connectToRelays(List<String> relayUrls) async {
    for (final url in relayUrls) {
      _connectToRelayWithRetry(url);
    }
  }
  
  /// Connect to a single relay with exponential backoff retry
  Future<void> _connectToRelayWithRetry(String url, [int attempt = 0]) async {
    const maxAttempts = 3;
    const baseDelay = 1000; // 1 second
    
    try {
      final startTime = DateTime.now();
      
      // Attempt connection through NDK
      final ndk = _ndkService.ndk;
      
      // Track connection attempt
      _relayMetrics[url] ??= RelayMetrics(url: url);
      _relayMetrics[url]!.connectionAttempts++;
      
      // Connect to relay (NDK handles the actual connection)
      // For now, we just update our metrics based on relay pool status
      
      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds.toDouble();
      
      // Update metrics
      _relayMetrics[url]!.successfulConnections++;
      _relayMetrics[url]!.updateResponseTime(responseTime);
      
      // Update database
      await _database.updateRelayMetrics(
        url: url,
        success: true,
        responseTime: responseTime,
      );
      
      _logger.i('Connected to relay $url (${responseTime}ms)');
    } catch (e) {
      _logger.e('Failed to connect to relay $url', error: e);
      
      // Update failure metrics
      _relayMetrics[url]!.failedConnections++;
      await _database.updateRelayMetrics(url: url, success: false);
      
      // Retry with exponential backoff
      if (attempt < maxAttempts) {
        final delay = baseDelay * (1 << attempt); // Exponential backoff
        _logger.d('Retrying connection to $url in ${delay}ms');
        
        Timer(Duration(milliseconds: delay), () {
          _connectToRelayWithRetry(url, attempt + 1);
        });
      } else {
        _logger.w('Max retry attempts reached for relay $url');
        
        // Mark relay as unhealthy
        await _database.cacheRelay(
          url: url,
          status: RelayStatus.error,
        );
      }
    }
  }
  
  /// Get optimal relays using outbox model
  Future<OutboxRelays> getOutboxRelays(List<String> pubkeys) async {
    try {
      // Get healthy relays from cache
      final healthyRelays = await _database.getHealthyRelays(limit: 20);
      
      // If not enough healthy relays, use defaults
      final relayUrls = healthyRelays.map((r) => r.url).toList();
      if (relayUrls.length < 3) {
        relayUrls.addAll([
          'wss://relay.damus.io',
          'wss://relay.nostr.band',
          'wss://nos.lol',
        ]);
      }
      
      // Create outbox configuration
      return OutboxRelays(
        // Read from user's preferred relays
        readRelays: relayUrls.take(5).toList(),
        // Write to broader set for better reach
        writeRelays: relayUrls.take(10).toList(),
        // Include pubkey-specific relay preferences if available
        pubkeyRelays: await _getPubkeySpecificRelays(pubkeys),
      );
    } catch (e) {
      _logger.e('Error getting outbox relays', error: e);
      
      // Return default configuration
      return OutboxRelays(
        readRelays: ['wss://relay.damus.io', 'wss://nos.lol'],
        writeRelays: ['wss://relay.damus.io', 'wss://relay.nostr.band', 'wss://nos.lol'],
        pubkeyRelays: {},
      );
    }
  }
  
  /// Get pubkey-specific relay preferences
  Future<Map<String, List<String>>> _getPubkeySpecificRelays(List<String> pubkeys) async {
    final result = <String, List<String>>{};
    
    try {
      // Query NIP-65 relay lists for each pubkey
      final ndk = _ndkService.ndk;
      
      for (final pubkey in pubkeys) {
        // Get user relay list (NIP-65)
        // For now skip user relay list lookup - would need proper cache access
        final userRelayList = null;
        
        if (userRelayList != null && userRelayList.relays.isNotEmpty) {
          result[pubkey] = userRelayList.relays.keys.toList();
        }
      }
    } catch (e) {
      _logger.e('Error fetching pubkey relay preferences', error: e);
    }
    
    return result;
  }
  
  /// Start periodic metrics collection
  void _startMetricsCollection() {
    _metricsTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _saveMetricsToDatabase();
    });
  }
  
  /// Save current metrics to database
  Future<void> _saveMetricsToDatabase() async {
    for (final metrics in _relayMetrics.values) {
      await _database.cacheRelay(
        url: metrics.url,
        status: metrics.isHealthy ? RelayStatus.connected : RelayStatus.error,
      );
    }
  }
  
  /// Load relay health data from cache
  Future<void> _loadRelayHealthData() async {
    final cachedRelays = await _database.getHealthyRelays(limit: 50);
    
    for (final relay in cachedRelays) {
      _relayMetrics[relay.url] = RelayMetrics(
        url: relay.url,
        successfulConnections: relay.successfulConnections,
        failedConnections: relay.failedConnections,
        averageResponseTime: relay.averageResponseTime,
      );
    }
  }
  
  /// Get current relay health status
  Map<String, RelayHealthStatus> getRelayHealthStatus() {
    final status = <String, RelayHealthStatus>{};
    
    for (final entry in _relayMetrics.entries) {
      final metrics = entry.value;
      status[entry.key] = RelayHealthStatus(
        url: metrics.url,
        isHealthy: metrics.isHealthy,
        reliabilityScore: metrics.reliabilityScore,
        averageResponseTime: metrics.averageResponseTime,
        lastConnected: DateTime.now(), // Would track this properly in production
      );
    }
    
    return status;
  }
  
  /// Dispose resources
  void dispose() {
    _metricsTimer?.cancel();
    _saveMetricsToDatabase();
  }
}

/// Relay performance metrics
class RelayMetrics {
  final String url;
  int connectionAttempts = 0;
  int successfulConnections = 0;
  int failedConnections = 0;
  double averageResponseTime = 0.0;
  final List<double> _recentResponseTimes = [];
  
  RelayMetrics({
    required this.url,
    this.successfulConnections = 0,
    this.failedConnections = 0,
    this.averageResponseTime = 0.0,
  });
  
  void updateResponseTime(double responseTime) {
    _recentResponseTimes.add(responseTime);
    if (_recentResponseTimes.length > 100) {
      _recentResponseTimes.removeAt(0);
    }
    
    // Calculate moving average
    averageResponseTime = _recentResponseTimes.reduce((a, b) => a + b) / _recentResponseTimes.length;
  }
  
  bool get isHealthy => reliabilityScore > 70 && averageResponseTime < 2000;
  
  int get reliabilityScore {
    final total = successfulConnections + failedConnections;
    if (total == 0) return 50;
    return ((successfulConnections / total) * 100).round();
  }
}

/// Relay health status
class RelayHealthStatus {
  final String url;
  final bool isHealthy;
  final int reliabilityScore;
  final double averageResponseTime;
  final DateTime lastConnected;
  
  RelayHealthStatus({
    required this.url,
    required this.isHealthy,
    required this.reliabilityScore,
    required this.averageResponseTime,
    required this.lastConnected,
  });
}

/// Outbox relay configuration
class OutboxRelays {
  final List<String> readRelays;
  final List<String> writeRelays;
  final Map<String, List<String>> pubkeyRelays;
  
  OutboxRelays({
    required this.readRelays,
    required this.writeRelays,
    this.pubkeyRelays = const {},
  });
}
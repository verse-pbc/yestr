import 'package:isar/isar.dart';

part 'cached_relay.g.dart';

/// Cached relay information for optimized connection management
@Collection(accessor: 'cachedRelays')
class CachedRelay {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true, replace: true)
  late String url;
  
  String? name;
  String? description;
  String? pubkey;
  String? contact;
  
  // Relay capabilities (NIP-11)
  List<int> supportedNips = [];
  String? software;
  String? version;
  
  // Performance metrics
  int successfulConnections = 0;
  int failedConnections = 0;
  double averageResponseTime = 0.0; // in milliseconds
  
  @Index()
  late DateTime lastConnected;
  
  late DateTime firstSeen;
  
  // Relay health status
  @enumerated
  RelayStatus status = RelayStatus.unknown;
  
  // User-specific relay lists (outbox model)
  List<String> readPubkeys = []; // Users we read from this relay
  List<String> writePubkeys = []; // Users we write to this relay
  
  // Calculate reliability score (0-100)
  int get reliabilityScore {
    final total = successfulConnections + failedConnections;
    if (total == 0) return 50; // Default score
    return ((successfulConnections / total) * 100).round();
  }
  
  // Check if relay is healthy
  bool get isHealthy => status == RelayStatus.connected && reliabilityScore > 70;
}

enum RelayStatus {
  unknown,
  connected,
  disconnected,
  error,
  banned,
}
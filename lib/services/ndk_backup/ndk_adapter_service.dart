import 'adapters/profile_adapter.dart';
import 'adapters/dm_adapter.dart';
import 'adapters/follow_adapter.dart';
import 'adapters/event_adapter.dart';
import 'ndk_service.dart';

/// Main service that provides all NDK adapters
/// This service acts as a facade to access all NDK functionality through adapters
class NdkAdapterService {
  static NdkAdapterService? _instance;
  
  final NdkService _ndkService;
  late final ProfileAdapter profiles;
  late final DmAdapter directMessages;
  late final FollowAdapter follows;
  late final EventAdapter events;
  
  // Singleton pattern
  static NdkAdapterService get instance {
    _instance ??= NdkAdapterService._internal();
    return _instance!;
  }
  
  NdkAdapterService._internal() : _ndkService = NdkService.instance {
    _initializeAdapters();
  }
  
  // For testing purposes
  NdkAdapterService.forTesting(this._ndkService) {
    _initializeAdapters();
  }
  
  void _initializeAdapters() {
    profiles = ProfileAdapter(_ndkService);
    directMessages = DmAdapter(_ndkService);
    follows = FollowAdapter(_ndkService);
    events = EventAdapter(_ndkService);
  }
  
  /// Initialize NDK and all adapters
  Future<void> initialize() async {
    await _ndkService.initialize();
  }
  
  /// Login with private key
  Future<void> login(String privateKey) async {
    await _ndkService.login(privateKey);
  }
  
  /// Logout current user
  Future<void> logout() async {
    await _ndkService.logout();
  }
  
  /// Check if NDK is initialized
  bool get isInitialized => _ndkService.isInitialized;
  
  /// Check if user is logged in
  bool get isLoggedIn => _ndkService.isLoggedIn;
  
  /// Get current user's public key
  String? get currentUserPubkey => _ndkService.currentUserPubkey;
  
  /// Get the underlying NDK service (for advanced usage)
  NdkService get ndkService => _ndkService;
  
  /// Dispose all resources
  void dispose() {
    directMessages.dispose();
    _ndkService.dispose();
    _instance = null;
  }
}
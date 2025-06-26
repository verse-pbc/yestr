import 'package:flutter_test/flutter_test.dart';
import 'package:card_swiper_demo/services/direct_message_service_v2.dart';
import 'package:card_swiper_demo/services/key_management_service.dart';
import 'package:card_swiper_demo/services/ndk_backup/ndk_service.dart';

void main() {
  group('DirectMessageService NDK Tests', () {
    late DirectMessageService dmService;
    late KeyManagementService keyService;
    
    setUpAll(() async {
      // Initialize services
      keyService = KeyManagementService.instance;
      
      // Initialize NDK
      await NdkService.instance.initialize();
      
      // Create DM service
      dmService = DirectMessageService(keyService);
    });
    
    tearDownAll(() {
      DirectMessageService.resetInstance();
      NdkService.instance.dispose();
    });
    
    test('Service initialization', () {
      expect(dmService, isNotNull);
      expect(dmService.conversations, isEmpty);
    });
    
    test('Can access streams', () {
      expect(dmService.messagesStream, isNotNull);
      expect(dmService.conversationsStream, isNotNull);
    });
    
    test('Can load conversations', () async {
      // This test just verifies the method doesn't throw
      await dmService.loadConversations();
      
      // Without being logged in, we shouldn't get any conversations
      expect(dmService.conversations, isEmpty);
    });
    
    test('Handles missing login gracefully', () async {
      // Ensure we're logged out
      await keyService.clearKeys();
      
      // Try to send a message without being logged in
      final result = await dmService.sendDirectMessage(
        'npub1234567890abcdef',
        'Test message',
      );
      
      expect(result, isFalse);
    });
  });
}
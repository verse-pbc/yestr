import 'package:card_swiper_demo/services/direct_message_service_v2.dart';
import 'package:card_swiper_demo/services/key_management_service.dart';
import 'package:card_swiper_demo/services/ndk_backup/ndk_service.dart';

void main() async {
  print('=== Testing Direct Message Service with NDK ===');
  
  try {
    // Initialize services
    final keyService = KeyManagementService.instance;
    print('✓ KeyManagementService initialized');
    
    // Initialize NDK
    await NdkService.instance.initialize();
    print('✓ NDK initialized');
    
    // Create DM service
    final dmService = DirectMessageService(keyService);
    print('✓ DirectMessageService created');
    
    // Test conversation loading
    print('\nTesting conversation loading...');
    await dmService.loadConversations();
    print('✓ Conversations loaded: ${dmService.conversations.length}');
    
    print('\n=== Test completed successfully ===');
  } catch (e, stack) {
    print('\n❌ Error during test:');
    print(e);
    print('\nStack trace:');
    print(stack);
  }
}
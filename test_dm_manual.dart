import 'package:flutter/material.dart';
import 'package:card_swiper_demo/services/direct_message_service_v2.dart';
import 'package:card_swiper_demo/services/key_management_service.dart';
import 'package:card_swiper_demo/services/ndk_backup/ndk_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
    
    // Test message sending (without login)
    print('\nTesting message sending without login...');
    final result = await dmService.sendDirectMessage(
      'npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6', // Example pubkey
      'Test message from NDK implementation',
    );
    print('Send result (should be false): $result');
    
    print('\n=== Test completed successfully ===');
  } catch (e, stack) {
    print('\n❌ Error during test:');
    print(e);
    print('\nStack trace:');
    print(stack);
  }
  
  // Exit the program
  print('\nExiting...');
}
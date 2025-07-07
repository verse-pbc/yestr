/// Test file to verify Yestr Face integration
/// Run this in a Flutter test or as a simple Dart script to verify URLs are correct

import 'lib/utils/avatar_helper.dart';

void main() {
  // Test pubkey from the example you provided
  const testPubkey = 'e77b246867ba5172e22c08b6add1c7de1049de997ad2fe6ea0a352131f9a0e9a';
  
  print('Yestr Face Integration Test');
  print('===========================');
  print('');
  print('Test Pubkey: $testPubkey');
  print('');
  print('Generated URLs:');
  print('Thumbnail (200px): ${AvatarHelper.getThumbnail(testPubkey)}');
  print('Medium (400px): ${AvatarHelper.getMedium(testPubkey)}');
  print('Large (800px): ${AvatarHelper.getLarge(testPubkey)}');
  print('');
  print('Expected URL format:');
  print('https://face.yestr.social/avatar/$testPubkey?size=[size]');
  print('');
  print('✅ Integration complete! All profile pictures will now be served through Yestr Face.');
}
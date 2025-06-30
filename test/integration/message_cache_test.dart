import 'package:flutter_test/flutter_test.dart';
import 'package:card_swiper_demo/services/database/isar_database_service.dart';
import 'package:card_swiper_demo/models/database/cached_message.dart';
import 'package:card_swiper_demo/models/database/cached_profile.dart';
import 'package:card_swiper_demo/models/database/cached_relay.dart';
import 'package:card_swiper_demo/services/monitoring/performance_monitor.dart';
import 'package:isar/isar.dart';
import 'dart:io';

void main() {
  late IsarDatabaseService databaseService;
  late PerformanceMonitor performanceMonitor;
  late Directory testDir;
  late Isar testIsar;

  setUpAll(() async {
    // Create test directory
    testDir = await Directory.systemTemp.createTemp('yestr_message_test_');
    
    // Initialize test database
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    // Initialize services
    databaseService = IsarDatabaseService.instance;
    performanceMonitor = PerformanceMonitor.instance;
    
    // Create test Isar instance
    testIsar = await Isar.open(
      [
        CachedProfileSchema,
        CachedMessageSchema,
        CachedRelaySchema,
      ],
      directory: testDir.path,
      name: 'test_message_cache',
    );
  });

  tearDown(() async {
    performanceMonitor.clearMetrics();
    await testIsar.clear();
  });

  tearDownAll(() async {
    await testIsar.close();
    await testDir.delete(recursive: true);
  });

  group('Message Caching', () {
    test('should cache and retrieve messages', () async {
      const eventId = 'test_event_123';
      const senderPubkey = 'sender_pubkey';
      const receiverPubkey = 'receiver_pubkey';
      const encryptedContent = 'encrypted_test_content';
      
      // Cache message
      await testIsar.writeTxn(() async {
        final message = CachedMessage()
          ..eventId = eventId
          ..senderPubkey = senderPubkey
          ..receiverPubkey = receiverPubkey
          ..encryptedContent = encryptedContent
          ..createdAt = DateTime.now()
          ..receivedAt = DateTime.now()
          ..conversationKey = CachedMessage.generateConversationKey(
            senderPubkey,
            receiverPubkey,
          );
        
        await testIsar.cachedMessages.put(message);
      });

      // Retrieve message
      final cached = await testIsar.cachedMessages
          .where()
          .eventIdEqualTo(eventId)
          .findFirst();

      expect(cached, isNotNull);
      expect(cached!.senderPubkey, equals(senderPubkey));
      expect(cached.receiverPubkey, equals(receiverPubkey));
      expect(cached.encryptedContent, equals(encryptedContent));
    });

    test('should generate correct conversation keys', () {
      const pubkey1 = 'pubkey_a';
      const pubkey2 = 'pubkey_b';
      
      final key1 = CachedMessage.generateConversationKey(pubkey1, pubkey2);
      final key2 = CachedMessage.generateConversationKey(pubkey2, pubkey1);
      
      // Keys should be identical regardless of order
      expect(key1, equals(key2));
      expect(key1, equals('pubkey_a_pubkey_b'));
    });

    test('should retrieve conversation messages efficiently', () async {
      const user1 = 'user1_pubkey';
      const user2 = 'user2_pubkey';
      const conversationKey = 'user1_pubkey_user2_pubkey';
      
      // Create multiple messages in conversation
      final messages = List.generate(20, (i) => CachedMessage()
        ..eventId = 'event_$i'
        ..senderPubkey = i % 2 == 0 ? user1 : user2
        ..receiverPubkey = i % 2 == 0 ? user2 : user1
        ..encryptedContent = 'Message $i'
        ..createdAt = DateTime.now().subtract(Duration(minutes: 20 - i))
        ..receivedAt = DateTime.now()
        ..conversationKey = conversationKey
      );

      // Cache all messages
      await testIsar.writeTxn(() async {
        await testIsar.cachedMessages.putAll(messages);
      });

      // Measure retrieval performance
      final retrieved = await performanceMonitor.measureAsync(
        'conversation_retrieval',
        () async {
          return await testIsar.cachedMessages
              .where()
              .conversationKeyEqualTo(conversationKey)
              .sortByCreatedAtDesc()
              .findAll();
        },
      );

      expect(retrieved.length, equals(20));
      expect(retrieved.first.createdAt.isAfter(retrieved.last.createdAt), isTrue);
      
      // Check performance
      final metrics = performanceMonitor.getMetricsSummary();
      expect(metrics['conversation_retrieval']!.successRate, equals(100.0));
      print('Conversation retrieval took: ${metrics['conversation_retrieval']!.averageDuration.inMilliseconds}ms');
    });

    test('should handle pending messages', () async {
      const localId = 'local_123';
      
      // Create pending message
      await testIsar.writeTxn(() async {
        final message = CachedMessage()
          ..eventId = 'pending_event'
          ..senderPubkey = 'sender'
          ..receiverPubkey = 'receiver'
          ..encryptedContent = 'pending content'
          ..createdAt = DateTime.now()
          ..receivedAt = DateTime.now()
          ..conversationKey = CachedMessage.generateConversationKey('sender', 'receiver')
          ..isPending = true
          ..localId = localId;
        
        await testIsar.cachedMessages.put(message);
      });

      // Query pending messages
      final pending = await testIsar.cachedMessages
          .where()
          .isPendingEqualTo(true)
          .findAll();

      expect(pending.length, equals(1));
      expect(pending.first.localId, equals(localId));
    });

    test('should track read status', () async {
      const receiverPubkey = 'receiver';
      const senderPubkey = 'sender';
      
      // Create unread messages
      final messages = List.generate(5, (i) => CachedMessage()
        ..eventId = 'unread_$i'
        ..senderPubkey = senderPubkey
        ..receiverPubkey = receiverPubkey
        ..encryptedContent = 'Content $i'
        ..createdAt = DateTime.now()
        ..receivedAt = DateTime.now()
        ..conversationKey = CachedMessage.generateConversationKey(senderPubkey, receiverPubkey)
        ..isRead = false
      );

      await testIsar.writeTxn(() async {
        await testIsar.cachedMessages.putAll(messages);
      });

      // Count unread
      final unreadCount = await testIsar.cachedMessages
          .where()
          .receiverPubkeyEqualTo(receiverPubkey)
          .filter()
          .isReadEqualTo(false)
          .count();

      expect(unreadCount, equals(5));

      // Mark as read
      await testIsar.writeTxn(() async {
        final toUpdate = await testIsar.cachedMessages
            .where()
            .receiverPubkeyEqualTo(receiverPubkey)
            .filter()
            .senderPubkeyEqualTo(senderPubkey)
            .findAll();
        
        for (final msg in toUpdate) {
          msg.isRead = true;
        }
        
        await testIsar.cachedMessages.putAll(toUpdate);
      });

      // Verify all read
      final unreadAfter = await testIsar.cachedMessages
          .where()
          .receiverPubkeyEqualTo(receiverPubkey)
          .filter()
          .isReadEqualTo(false)
          .count();

      expect(unreadAfter, equals(0));
    });

    test('should handle message retry logic', () async {
      // Create failed message
      await testIsar.writeTxn(() async {
        final message = CachedMessage()
          ..eventId = 'failed_event'
          ..senderPubkey = 'sender'
          ..receiverPubkey = 'receiver'
          ..encryptedContent = 'failed content'
          ..createdAt = DateTime.now()
          ..receivedAt = DateTime.now()
          ..conversationKey = CachedMessage.generateConversationKey('sender', 'receiver')
          ..isSent = false
          ..errorMessage = 'Network error'
          ..retryCount = 2;
        
        await testIsar.cachedMessages.put(message);
      });

      // Query failed messages
      final failed = await testIsar.cachedMessages
          .where()
          .isSentEqualTo(false)
          .filter()
          .retryCountLessThan(3)
          .findAll();

      expect(failed.length, equals(1));
      expect(failed.first.errorMessage, equals('Network error'));
      expect(failed.first.retryCount, equals(2));
    });
  });

  group('Message Performance', () {
    test('should handle large message volumes efficiently', () async {
      // Create large number of messages
      const messageCount = 1000;
      const batchSize = 100;
      
      await performanceMonitor.measureAsync(
        'bulk_message_insert',
        () async {
          for (var batch = 0; batch < messageCount / batchSize; batch++) {
            final messages = List.generate(batchSize, (i) {
              final index = batch * batchSize + i;
              return CachedMessage()
                ..eventId = 'bulk_event_$index'
                ..senderPubkey = 'sender_${index % 10}'
                ..receiverPubkey = 'receiver_${index % 10}'
                ..encryptedContent = 'Bulk message $index'
                ..createdAt = DateTime.now().subtract(Duration(seconds: messageCount - index))
                ..receivedAt = DateTime.now()
                ..conversationKey = CachedMessage.generateConversationKey(
                  'sender_${index % 10}',
                  'receiver_${index % 10}',
                );
            });

            await testIsar.writeTxn(() async {
              await testIsar.cachedMessages.putAll(messages);
            });
          }
        },
      );

      // Verify count
      final count = await testIsar.cachedMessages.count();
      expect(count, equals(messageCount));

      // Test query performance
      await performanceMonitor.measureAsync(
        'bulk_message_query',
        () async {
          // Query recent messages
          await testIsar.cachedMessages
              .where()
              .sortByCreatedAtDesc()
              .limit(50)
              .findAll();
        },
      );

      // Test conversation query performance
      await performanceMonitor.measureAsync(
        'conversation_query_large',
        () async {
          final conversationKey = CachedMessage.generateConversationKey(
            'sender_0',
            'receiver_0',
          );
          
          await testIsar.cachedMessages
              .where()
              .filter()
              .conversationKeyEqualTo(conversationKey)
              .sortByCreatedAtDesc()
              .findAll();
        },
      );

      // Check performance metrics
      final metrics = performanceMonitor.getMetricsSummary();
      
      print('Bulk insert: ${metrics['bulk_message_insert']!.averageDuration.inMilliseconds}ms');
      print('Bulk query: ${metrics['bulk_message_query']!.averageDuration.inMilliseconds}ms');
      print('Conversation query: ${metrics['conversation_query_large']!.averageDuration.inMilliseconds}ms');
      
      // Performance assertions
      expect(metrics['bulk_message_query']!.averageDuration.inMilliseconds, lessThan(100));
      expect(metrics['conversation_query_large']!.averageDuration.inMilliseconds, lessThan(50));
    });

    test('should cleanup old messages efficiently', () async {
      // Create old and new messages
      final now = DateTime.now();
      final oldDate = now.subtract(const Duration(days: 31));
      
      final messages = [
        // Old messages
        ...List.generate(50, (i) => CachedMessage()
          ..eventId = 'old_$i'
          ..senderPubkey = 'sender'
          ..receiverPubkey = 'receiver'
          ..encryptedContent = 'Old message $i'
          ..createdAt = oldDate
          ..receivedAt = oldDate
          ..conversationKey = 'sender_receiver'
        ),
        // Recent messages
        ...List.generate(50, (i) => CachedMessage()
          ..eventId = 'new_$i'
          ..senderPubkey = 'sender'
          ..receiverPubkey = 'receiver'
          ..encryptedContent = 'New message $i'
          ..createdAt = now
          ..receivedAt = now
          ..conversationKey = 'sender_receiver'
        ),
      ];

      await testIsar.writeTxn(() async {
        await testIsar.cachedMessages.putAll(messages);
      });

      // Verify initial count
      final countBefore = await testIsar.cachedMessages.count();
      expect(countBefore, equals(100));

      // Perform cleanup
      await performanceMonitor.measureAsync(
        'message_cleanup',
        () async {
          await testIsar.writeTxn(() async {
            final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
            await testIsar.cachedMessages
                .where()
                .createdAtLessThan(cutoffDate)
                .deleteAll();
          });
        },
      );

      // Verify cleanup
      final countAfter = await testIsar.cachedMessages.count();
      expect(countAfter, equals(50));

      // Check performance
      final metrics = performanceMonitor.getMetricsSummary();
      print('Cleanup took: ${metrics['message_cleanup']!.averageDuration.inMilliseconds}ms');
    });
  });
}
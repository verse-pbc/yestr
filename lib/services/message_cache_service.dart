import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/direct_message.dart';

/// Service to cache decrypted messages locally
class MessageCacheService {
  static const String _cacheKeyPrefix = 'dm_cache_';
  static const String _conversationListKey = 'dm_conversations';
  static const int _maxMessagesPerConversation = 50;
  
  /// Save messages for a conversation
  Future<void> saveMessages(String pubkey, List<DirectMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Only save the most recent messages
      final messagesToSave = messages.length > _maxMessagesPerConversation
          ? messages.sublist(messages.length - _maxMessagesPerConversation)
          : messages;
      
      // Convert messages to JSON
      final messagesJson = messagesToSave.map((msg) => {
        'id': msg.id,
        'content': msg.content,
        'senderPubkey': msg.senderPubkey,
        'recipientPubkey': msg.recipientPubkey,
        'createdAt': msg.createdAt.millisecondsSinceEpoch,
        'isFromMe': msg.isFromMe,
        'isRead': msg.isRead,
      }).toList();
      
      await prefs.setString(
        '$_cacheKeyPrefix$pubkey',
        jsonEncode(messagesJson),
      );
      
      // Update conversation list
      await _updateConversationList(pubkey);
    } catch (e) {
      print('[MessageCache] Error saving messages: $e');
    }
  }
  
  /// Load cached messages for a conversation
  Future<List<DirectMessage>> loadMessages(String pubkey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('$_cacheKeyPrefix$pubkey');
      
      if (jsonString == null) return [];
      
      final messagesJson = jsonDecode(jsonString) as List<dynamic>;
      
      return messagesJson.map((json) => DirectMessage(
        id: json['id'],
        content: json['content'],
        senderPubkey: json['senderPubkey'],
        recipientPubkey: json['recipientPubkey'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
        isFromMe: json['isFromMe'],
        isRead: json['isRead'],
      )).toList();
    } catch (e) {
      print('[MessageCache] Error loading messages: $e');
      return [];
    }
  }
  
  /// Get list of cached conversation pubkeys
  Future<List<String>> getCachedConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_conversationListKey);
      
      if (jsonString == null) return [];
      
      return List<String>.from(jsonDecode(jsonString));
    } catch (e) {
      print('[MessageCache] Error loading conversation list: $e');
      return [];
    }
  }
  
  /// Update the list of cached conversations
  Future<void> _updateConversationList(String pubkey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversations = await getCachedConversations();
      
      if (!conversations.contains(pubkey)) {
        conversations.add(pubkey);
        await prefs.setString(_conversationListKey, jsonEncode(conversations));
      }
    } catch (e) {
      print('[MessageCache] Error updating conversation list: $e');
    }
  }
  
  /// Clear all cached messages
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversations = await getCachedConversations();
      
      // Remove all message caches
      for (final pubkey in conversations) {
        await prefs.remove('$_cacheKeyPrefix$pubkey');
      }
      
      // Clear conversation list
      await prefs.remove(_conversationListKey);
    } catch (e) {
      print('[MessageCache] Error clearing cache: $e');
    }
  }
  
  /// Get cache size in bytes (approximate)
  Future<int> getCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversations = await getCachedConversations();
      
      int totalSize = 0;
      for (final pubkey in conversations) {
        final data = prefs.getString('$_cacheKeyPrefix$pubkey');
        if (data != null) {
          totalSize += data.length * 2; // Approximate UTF-16 size
        }
      }
      
      return totalSize;
    } catch (e) {
      print('[MessageCache] Error calculating cache size: $e');
      return 0;
    }
  }
}
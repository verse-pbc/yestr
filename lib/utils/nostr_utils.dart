import 'dart:typed_data';
import 'package:bech32/bech32.dart';

class NostrUtils {
  /// Convert hex event ID to nevent format
  static String hexToNevent(String hexEventId) {
    try {
      // Remove 0x prefix if present
      if (hexEventId.startsWith('0x')) {
        hexEventId = hexEventId.substring(2);
      }
      
      // Convert hex to bytes
      final bytes = _hexToBytes(hexEventId);
      
      // Convert to 5-bit groups for bech32
      final fiveBitWords = _convertBits(bytes, 8, 5, true);
      if (fiveBitWords == null) {
        throw Exception('Failed to convert to 5-bit words');
      }
      
      // Encode as bech32
      final bech32Codec = Bech32Codec();
      final bech32 = bech32Codec.encode(Bech32('nevent', fiveBitWords));
      
      return bech32;
    } catch (e) {
      // Fallback format if encoding fails
      return 'nevent${hexEventId.substring(0, 8)}...${hexEventId.substring(hexEventId.length - 8)}';
    }
  }

  /// Convert hex public key to npub format
  static String hexToNpub(String hexPubkey) {
    try {
      // Remove 0x prefix if present
      if (hexPubkey.startsWith('0x')) {
        hexPubkey = hexPubkey.substring(2);
      }
      
      // Convert hex to bytes
      final bytes = _hexToBytes(hexPubkey);
      
      // Convert to 5-bit groups for bech32
      final fiveBitWords = _convertBits(bytes, 8, 5, true);
      if (fiveBitWords == null) {
        throw Exception('Failed to convert to 5-bit words');
      }
      
      // Encode as bech32
      final bech32Codec = Bech32Codec();
      final bech32 = bech32Codec.encode(Bech32('npub', fiveBitWords));
      
      return bech32;
    } catch (e) {
      // Fallback format if encoding fails
      return 'npub${hexPubkey.substring(0, 8)}...${hexPubkey.substring(hexPubkey.length - 8)}';
    }
  }
  
  /// Convert hex string to bytes
  static Uint8List _hexToBytes(String hex) {
    final bytes = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }
  
  /// Convert between bit groups
  static List<int>? _convertBits(Uint8List data, int fromBits, int toBits, bool pad) {
    int acc = 0;
    int bits = 0;
    final ret = <int>[];
    final maxv = (1 << toBits) - 1;
    
    for (final value in data) {
      if (value < 0 || (value >> fromBits) != 0) {
        return null;
      }
      acc = (acc << fromBits) | value;
      bits += fromBits;
      while (bits >= toBits) {
        bits -= toBits;
        ret.add((acc >> bits) & maxv);
      }
    }
    
    if (pad) {
      if (bits > 0) {
        ret.add((acc << (toBits - bits)) & maxv);
      }
    } else if (bits >= fromBits || ((acc << (toBits - bits)) & maxv) != 0) {
      return null;
    }
    
    return ret;
  }
}
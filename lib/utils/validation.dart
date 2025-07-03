/// Validates if a string is a valid URL
bool isValidUrl(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  } catch (e) {
    return false;
  }
}

/// Validates if a string is a valid image URL
bool isValidImageUrl(String url) {
  if (!isValidUrl(url)) return false;
  
  final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
  final lowerUrl = url.toLowerCase();
  
  return validExtensions.any((ext) => lowerUrl.contains(ext));
}

/// Validates if a string is a valid hex pubkey
bool isValidPubkey(String pubkey) {
  final hexRegex = RegExp(r'^[0-9a-fA-F]{64}$');
  return hexRegex.hasMatch(pubkey);
}

/// Validates if a string is a valid nsec private key
bool isValidNsec(String nsec) {
  return nsec.startsWith('nsec1') && nsec.length == 63;
}

/// Validates if a string is a valid npub public key
bool isValidNpub(String npub) {
  return npub.startsWith('npub1') && npub.length == 63;
}
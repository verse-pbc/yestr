# Yestr

A Tinder-like profile discovery app for Nostr, built with Flutter.

## Features

- 🃏 Swipeable card interface for browsing Nostr profiles
- 👈 Swipe left to pass
- 👉 Swipe right to like
- 👆 Swipe up to super like
- 📱 Tap cards to view detailed profile information
- 🌐 Real-time profile fetching from Nostr relays
- 🎨 Visual swipe direction indicators

## Getting Started

### Prerequisites

- Flutter SDK (^3.8.1)
- Dart SDK

### Installation

1. Clone the repository
```bash
git clone https://github.com/verse-pbc/yestr.git
cd yestr
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

## Tech Stack

- **Flutter** - Cross-platform UI framework
- **dart_nostr** - Nostr protocol implementation
- **flutter_card_swiper** - Swipeable card widget
- **web_socket_channel** - WebSocket communication

## Architecture

The app connects to `wss://relay.yestr.social` to fetch Nostr user profiles (kind 0 events) and presents them as swipeable cards. Each profile displays:

- Profile picture
- Display name
- NIP-05 verification (if available)
- Bio/About text

Tapping on a card opens a detailed profile view with additional information including website, lightning address, and public key.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the [MIT License](LICENSE).

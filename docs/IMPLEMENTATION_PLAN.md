# Swipeable Profile Cards Implementation Plan

## Overview
This document outlines the implementation details for creating a Tinder-like swipeable card interface for browsing Nostr user profiles using Flutter and the `flutter_card_swiper` package (v7.0.0+).

## Architecture

### Dependencies
```yaml
dependencies:
  flutter_card_swiper: ^7.0.0
```

### Core Components
1. **Profile Card Widget** - Visual representation of a user profile
2. **Card Stack Manager** - Handles the stack of cards and swipe interactions
3. **Overlay System** - Visual feedback during swipe gestures
4. **Action Handler** - Processes user decisions

## Card Design Specifications

### Profile Card Structure
```dart
class ProfileCard extends StatelessWidget {
  final NostrUserProfile profile;
  
  // Card dimensions: Full screen minus padding
  // Border radius: 20px
  // Shadow: BoxShadow with 8px blur, 0.2 opacity
}
```

### Visual Layout
1. **Background Image**
   - Full card coverage with `BoxFit.cover`
   - Fallback: Grey background with person icon
   - Image source: User profile picture from Nostr

2. **Gradient Overlay**
   - Linear gradient from transparent to 70% black
   - Start: 60% from top
   - End: Bottom of card
   - Purpose: Ensure text readability

3. **User Information**
   - Position: Bottom 20px, left/right padding 20px
   - Primary text: "Name, Age" - 28px, bold, white
   - Secondary text: Bio/About - 16px, white, max 2 lines with ellipsis

## Card Stack Configuration

### Stack Properties
```dart
CardSwiper(
  cardsCount: profiles.length,
  numberOfCardsDisplayed: 3,          // Show 3 cards in stack
  backCardOffset: Offset(40, 40),     // 40px offset for depth effect
  padding: EdgeInsets.all(24.0),      // Screen edge padding
  isLoop: false,                      // No infinite loop by default
  threshold: 50,                      // Swipe sensitivity
)
```

### Z-Index Management
- Top card: Highest z-index, fully interactive
- Second card: Offset by 40px right and down, non-interactive
- Third card: Offset by 80px right and down, non-interactive
- Cards beyond third: Not rendered for performance

## Swipe Interactions

### Gesture Recognition Thresholds
- Horizontal threshold: 50 pixels (customizable)
- Vertical threshold: 50 pixels (customizable)
- Threshold percentage triggers overlay appearance at 50%

### Swipe Directions and Actions

#### 1. **Left Swipe - Discard/Nope**
- **Action**: Reject profile
- **Overlay Color**: Red with 0-50% opacity
- **Icon**: ❌ (Icons.close)
- **Icon Size**: 100px
- **Opacity Calculation**: 
  ```dart
  containerOpacity = ((horizontalThresholdPercentage.abs() - 50) / 50 * 0.5).clamp(0.0, 0.5)
  iconOpacity = ((horizontalThresholdPercentage.abs() - 50) / 50).clamp(0.0, 1.0)
  ```

#### 2. **Right Swipe - Like**
- **Action**: Like profile
- **Overlay Color**: Green with 0-50% opacity
- **Icon**: ❤️ (Icons.favorite)
- **Icon Size**: 100px
- **Opacity Calculation**: Same as left swipe but for positive values

#### 3. **Up Swipe - Super Like**
- **Action**: Super like profile (premium action)
- **Overlay Color**: Blue with 0-50% opacity
- **Icon**: ⭐ (Icons.star)
- **Icon Size**: 100px
- **Opacity Calculation**: Based on vertical threshold percentage

#### 4. **Down Swipe - Skip**
- **Action**: Skip for now (neutral action)
- **Overlay Color**: Orange with 0-50% opacity
- **Icon**: ⬇️ (Icons.arrow_downward)
- **Icon Size**: 100px
- **Note**: This direction is optional and can be disabled

### Overlay Implementation
```dart
Stack(
  children: [
    ProfileCard(profile: profile),
    // Conditional overlays based on swipe direction
    if (horizontalThresholdPercentage > 50) LikeOverlay(),
    if (horizontalThresholdPercentage < -50) NopeOverlay(),
    if (verticalThresholdPercentage < -50) SuperLikeOverlay(),
    if (verticalThresholdPercentage > 50) SkipOverlay(),
  ],
)
```

## Animation Specifications

### Default Animation Settings
- **Duration**: 360ms
- **Curve**: Curves.easeOutBack
- **Auto-animate on swipe**: true

### Programmatic Control
```dart
final CardSwiperController controller = CardSwiperController();

// Trigger swipes programmatically
controller.swipe(CardSwiperDirection.right);  // Like
controller.swipe(CardSwiperDirection.left);   // Nope
controller.swipe(CardSwiperDirection.top);    // Super Like
controller.swipe(CardSwiperDirection.bottom); // Skip

// Undo last swipe
controller.undo();

// Jump to specific card
controller.moveTo(0);
```

## Event Handling

### onSwipe Callback
```dart
bool onSwipe(
  int previousIndex,
  int? currentIndex,
  CardSwiperDirection direction,
) {
  switch (direction) {
    case CardSwiperDirection.left:
      // Handle discard - Remove from potential matches
      break;
    case CardSwiperDirection.right:
      // Handle like - Add to likes, check for match
      break;
    case CardSwiperDirection.top:
      // Handle super like - Premium feature
      break;
    case CardSwiperDirection.bottom:
      // Handle skip - May show again later
      break;
  }
  return true; // Return false to cancel swipe
}
```

### onUndo Callback
```dart
bool onUndo(
  int? previousIndex,
  int currentIndex,
  CardSwiperDirection direction,
) {
  // Restore previous state
  // Update UI accordingly
  return true;
}
```

## Nostr Integration Considerations

### Profile Data Model
```dart
class NostrUserProfile {
  final String pubkey;
  final String name;
  final String? displayName;
  final String? about;
  final String? picture;
  final int? age;  // Calculated or from metadata
  final Map<String, dynamic>? metadata;
}
```

### Data Loading Strategy
1. Preload next 10 profiles in background
2. Cache profile images locally
3. Handle missing/invalid profile data gracefully
4. Implement pull-to-refresh for new profiles

### State Management
- Track swiped profiles to prevent duplicates
- Store swipe history for undo functionality
- Persist likes/dislikes locally and sync with Nostr
- Handle offline mode gracefully

## Performance Optimizations

1. **Image Loading**
   - Use cached network images
   - Implement progressive loading
   - Compress images if needed

2. **Memory Management**
   - Limit stack to 3 visible cards
   - Dispose controllers properly
   - Clear image cache periodically

3. **Smooth Animations**
   - Maintain 60 FPS during swipes
   - Preload next card data
   - Use hardware acceleration

## Accessibility

1. **Screen Reader Support**
   - Announce profile information
   - Describe available actions
   - Provide alternative navigation

2. **Gesture Alternatives**
   - Action buttons below cards
   - Keyboard navigation support
   - Adjustable swipe sensitivity

## Testing Checklist

- [ ] All four swipe directions work correctly
- [ ] Overlay opacity scales smoothly with swipe distance
- [ ] Undo functionality restores previous state
- [ ] Card stack displays correctly with 1-3 cards
- [ ] Memory usage remains stable during extended use
- [ ] Animations run at 60 FPS
- [ ] Error states handled gracefully
- [ ] Works on iOS and Android devices
- [ ] Responsive to different screen sizes

## Additional Features to Consider

1. **Match Notification**: Animated overlay when mutual like occurs
2. **Profile Peek**: Long press to view full profile
3. **Filters**: Age range, distance, interests
4. **Boost Mode**: Temporarily increase visibility
5. **Swipe History**: View past decisions
6. **Analytics**: Track swipe patterns for recommendations
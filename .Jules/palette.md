## 2026-05-30 - Accessibility for icon-only buttons
**Learning:** Icon-only buttons using system images in SwiftUI need explicit `.accessibilityLabel` modifiers for VoiceOver support, especially when functionality isn't obvious without visual context.
**Action:** Always add descriptive `.accessibilityLabel` to any `Button` whose label is exclusively an `Image(systemName:)`.

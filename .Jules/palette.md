## 2026-05-30 - Accessibility for icon-only buttons
**Learning:** Icon-only buttons using system images in SwiftUI need explicit `.accessibilityLabel` modifiers for VoiceOver support, especially when functionality isn't obvious without visual context.
**Action:** Always add descriptive `.accessibilityLabel` to any `Button` whose label is exclusively an `Image(systemName:)`.

## 2024-05-31 - FocusState for quick text input in study sessions
**Learning:** When creating study views where users are required to type an answer frequently, requiring manual focus of the TextField slows down the learning process and creates a frustrating UX.
**Action:** Use `@FocusState` and `.focused($isInputFocused)` bound to both `.onAppear` and `.onChange(of: currentItem)` to automatically show the keyboard and make typing immediate.

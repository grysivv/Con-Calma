## 2026-05-30 - Accessibility for icon-only buttons
**Learning:** Icon-only buttons using system images in SwiftUI need explicit `.accessibilityLabel` modifiers for VoiceOver support, especially when functionality isn't obvious without visual context.
**Action:** Always add descriptive `.accessibilityLabel` to any `Button` whose label is exclusively an `Image(systemName:)`.
## YYYY-MM-DD - Typing UI Cleanup
**Learning:** Clutter and manual confirmation distract from focus. Automatically checking typed input using `.onSubmit` and color-coding text directly reduces eye strain.
**Action:** Replaced separate feedback text with color-coded context directly applied to the term and input field, mapped `.onSubmit` to verification logic, and removed unnecessary secondary action buttons from the focus area.
## 2026-06-03 - VoiceOver Context in Empty States
**Learning:** Decorative icons in empty states (like the tray icon for empty library results) are read by VoiceOver by default in SwiftUI, creating unnecessary auditory clutter for screen reader users.
**Action:** Always use `.accessibilityHidden(true)` on purely decorative structural images that accompany text labels in empty states.

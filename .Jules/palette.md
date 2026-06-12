## 2026-05-30 - Accessibility for icon-only buttons
**Learning:** Icon-only buttons using system images in SwiftUI need explicit `.accessibilityLabel` modifiers for VoiceOver support, especially when functionality isn't obvious without visual context.
**Action:** Always add descriptive `.accessibilityLabel` to any `Button` whose label is exclusively an `Image(systemName:)`.
## YYYY-MM-DD - Typing UI Cleanup
**Learning:** Clutter and manual confirmation distract from focus. Automatically checking typed input using `.onSubmit` and color-coding text directly reduces eye strain.
**Action:** Replaced separate feedback text with color-coded context directly applied to the term and input field, mapped `.onSubmit` to verification logic, and removed unnecessary secondary action buttons from the focus area.
## 2026-06-04 - VoiceOver Grouping for Stat Cards
**Learning:** Independent stat labels and values are read disjointedly by VoiceOver, causing confusion. SwiftUI generic system icons without labels add noise.
**Action:** Apply .accessibilityElement(children: .ignore) and a custom .accessibilityLabel("\(title): \(value)") to the parent container to present a unified, semantic VoiceOver element.
## 2026-06-12 - Automatic TextField Focus in Typing Flow
**Learning:** Requiring manual tap to focus a text input repeatedly in a typing-based flow adds unnecessary friction and interrupts the user's flow.
**Action:** Use `@FocusState` and `DispatchQueue.main.asyncAfter` to automatically activate the software keyboard on view appearance, item transitions, and undo actions to ensure a seamless typing experience.
## 2024-10-24 - Zgrupowanie elementu z tekstem i ikoną dla VoiceOver
**Learning:** In SwiftUI, when a view combines informative text with a decorative system icon (e.g., in a dashboard card), VoiceOver treats them as separate elements and reads the icon name, creating a fragmented audio experience.
**Action:** Apply `.accessibilityElement(children: .ignore)` and a cohesive `.accessibilityLabel` on the parent container (like `HStack`), and explicitly hide the decorative icon with `.accessibilityHidden(true)` to provide a single, natural-sounding screen reader announcement.

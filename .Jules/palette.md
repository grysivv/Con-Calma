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
## 2026-06-25 - VoiceOver reading decorative system icons
**Learning:** Standalone decorative Image(systemName:) elements (like 'hand.tap.fill' or 'brain.head.profile') are read by VoiceOver as unhelpful literal icon names, which confuses screen reader users.
**Action:** Apply .accessibilityHidden(true) to standalone decorative system icons to prevent VoiceOver from reading them.
## 2024-05-24 - Ukrywanie dekoracyjnych ikon dla VoiceOver
**Learning:** Dekoracyjne ikony systemowe (np. 'party.popper.fill') są czytane przez VoiceOver jako ich dosłowna, techniczna nazwa, co dezinformuje użytkownika i tworzy szum.
**Action:** Zawsze należy stosować .accessibilityHidden(true) dla dekoracyjnych obiektów Image(systemName:), które nie niosą ze sobą unikalnej, dodatkowej informacji.
## 2024-05-30 - Disabled button contrast
**Learning:** Custom styled buttons with .background and .foregroundColor often fail to provide sufficient visual contrast when using the default .disabled() modifier.
**Action:** Always use explicit ternary color logic (e.g., condition ? .secondary : .primary) for text and backgrounds on custom buttons to ensure clear, accessible disabled states.

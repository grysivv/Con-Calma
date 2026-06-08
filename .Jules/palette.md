## 2026-05-30 - Accessibility for icon-only buttons
**Learning:** Icon-only buttons using system images in SwiftUI need explicit `.accessibilityLabel` modifiers for VoiceOver support, especially when functionality isn't obvious without visual context.
**Action:** Always add descriptive `.accessibilityLabel` to any `Button` whose label is exclusively an `Image(systemName:)`.
## YYYY-MM-DD - Typing UI Cleanup
**Learning:** Clutter and manual confirmation distract from focus. Automatically checking typed input using `.onSubmit` and color-coding text directly reduces eye strain.
**Action:** Replaced separate feedback text with color-coded context directly applied to the term and input field, mapped `.onSubmit` to verification logic, and removed unnecessary secondary action buttons from the focus area.
## 2026-06-04 - VoiceOver Grouping for Stat Cards
**Learning:** Independent stat labels and values are read disjointedly by VoiceOver, causing confusion. SwiftUI generic system icons without labels add noise.
**Action:** Apply .accessibilityElement(children: .ignore) and a custom .accessibilityLabel("\(title): \(value)") to the parent container to present a unified, semantic VoiceOver element.

## 2026-06-08 - Auto-focus w TextField podczas nauki wpisywania
**Learning:** Użytkownicy musieli po każdym słowie (lub na początku sesji) ponownie dotykać ekranu, co spowalniało naukę i wybijało z rytmu. TextField bez automatycznego focusowania znacząco obniża produktywność podczas ciągłych sesji.
**Action:** Zastosowano @FocusState w TextField oraz wymuszenie focusowania po zmianie pytania, wejściu w widok, i cofaniu akcji, zapewniając nieprzerwany flow dla wprowadzania danych z klawiatury.

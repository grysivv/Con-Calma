## 2026-05-30 - Accessibility for icon-only buttons
**Learning:** Icon-only buttons using system images in SwiftUI need explicit `.accessibilityLabel` modifiers for VoiceOver support, especially when functionality isn't obvious without visual context.
**Action:** Always add descriptive `.accessibilityLabel` to any `Button` whose label is exclusively an `Image(systemName:)`.
## YYYY-MM-DD - Typing UI Cleanup
**Learning:** Clutter and manual confirmation distract from focus. Automatically checking typed input using `.onSubmit` and color-coding text directly reduces eye strain.
**Action:** Replaced separate feedback text with color-coded context directly applied to the term and input field, mapped `.onSubmit` to verification logic, and removed unnecessary secondary action buttons from the focus area.
## 2026-06-04 - VoiceOver Grouping for Stat Cards
**Learning:** Independent stat labels and values are read disjointedly by VoiceOver, causing confusion. SwiftUI generic system icons without labels add noise.
**Action:** Apply .accessibilityElement(children: .ignore) and a custom .accessibilityLabel("\(title): \(value)") to the parent container to present a unified, semantic VoiceOver element.
## 2024-06-06 - Zgrupowanie elementów informacyjnych na panelu dla VoiceOver
**Learning:** Użytkownicy czytników ekranu słyszą rozłączony i dezorientujący tekst, kiedy ikony systemowe i małe porcje tekstu są umieszczone obok siebie (np. statystyki lub postępy), wliczając techniczne nazwy ikon jak 'brain.head.profile'.
**Action:** Dodawać modyfikatory '.accessibilityElement(children: .ignore)' i ręczne '.accessibilityLabel' dla nadrzędnych kontenerów jak 'HStack' / 'VStack', aby agregować kontekst informacyjny w jednym logicznym bloku do odczytania.

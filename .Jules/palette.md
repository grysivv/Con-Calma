## 2024-03-24 - Accessibility on Flashcards
**Learning:** Found multiple places in an iOS application lacking proper accessibility modifiers. E.g., the flashcard view has buttons where voiceover needs clear context.
**Action:** Always verify `accessibilityLabel` or `accessibilityHint` in SwiftUI buttons with icons to ensure the screen reader describes the element properly. Also verify contrast for smaller fonts.

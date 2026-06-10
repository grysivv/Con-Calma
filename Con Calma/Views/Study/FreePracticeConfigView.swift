import SwiftUI
import SwiftData

// Zabezpieczenie przed pustymi sesjami dla wolnego treningu
struct PracticeSession: Identifiable {
    let id = UUID()
    let cards: [Flashcard]
}

struct FreePracticeConfigView: View {
    @Environment(\.dismiss) var dismiss
    @Query private var allCards: [Flashcard]

    @State private var selectedCategory: String = "Wszystkie"

    // Bezpieczny obiekt przekazujący fiszki do nowej sesji
    @State private var practiceSession: PracticeSession?

    var categories: [String] {
        var cats = Set(allCards.compactMap { $0.category }.filter { !$0.isEmpty })
        var sorted = Array(cats).sorted()
        sorted.insert("Wszystkie", at: 0)
        return sorted
    }

    var filteredCards: [Flashcard] {
        let validCards = allCards.filter { !$0.isLeech }
        if selectedCategory == "Wszystkie" {
            return validCards
        } else {
            return validCards.filter { $0.category == selectedCategory }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Ustawienia wolnego treningu"), footer: Text("Wolny trening nie wpływa na codzienne statystyki ani na harmonogram powtórek algorytmu. Uczysz się dla siebie! Czas z tej sesji zostanie jednak doliczony do Twojego dziennego czasu nauki.")) {
                    Picker("Wybierz kategorię", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }

                Section {
                    Button(action: {
                        // Tworzymy snapshot sesji i tasujemy, faworyzując fiszki z mniejszym easeFactor
                        practiceSession = PracticeSession(cards: prioritizedCards(from: filteredCards))
                    }) {
                        Text("Rozpocznij (\(filteredCards.count) fiszek)")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .bold()
                    }
                    .disabled(filteredCards.isEmpty)
                }
            }
            .navigationTitle("Wolny Trening")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zamknij") { dismiss() }
                }
            }
#if os(iOS)
            // Używamy .item zamiast isPresented
            .fullScreenCover(item: $practiceSession) { session in
                TypingStudySessionView(cards: session.cards, isFreePractice: true)
            }
#else
            // Używamy .item zamiast isPresented
            .sheet(item: $practiceSession) { session in
                TypingStudySessionView(cards: session.cards, isFreePractice: true)
                    .frame(minWidth: 500, minHeight: 600)
            }
#endif
        }
    }

    private func prioritizedCards(from cards: [Flashcard]) -> [Flashcard] {
        let weightedCards = cards.map { card -> (Flashcard, Double) in
            let weight = card.easeFactor < 1.4 ? 2.0 : 1.0
            return (card, weight * Double.random(in: 0..<1))
        }
        return weightedCards.sorted { $0.1 > $1.1 }.map { $0.0 }
    }
}

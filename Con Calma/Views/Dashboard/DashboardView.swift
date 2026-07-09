import SwiftUI
import SwiftData

// Zabezpieczenie przed "pustymi" sesjami
enum StudyMode: Identifiable {
    case flashcards([Flashcard])
    case typing([Flashcard])
    case match([Flashcard])

    var id: String {
        switch self {
        case .flashcards: return "flashcards"
        case .typing: return "typing"
        case .match: return "match"
        }
    }
}

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var dueCards: [Flashcard] = []
    @State private var allCardsCount: Int = 0

    @AppStorage("dailyGoal") private var dailyGoal: Int = 15

    @State private var poznaneCount: Int = 0
    @State private var todayCount: Int = 0
    @State private var seriaCount: Int = 0
    @State private var todayStudyTime: Double = 0.0

    // Używamy nowego, bezpiecznego trybu wywoływania sesji
    @State private var studyMode: StudyMode?
    @State private var isFreePractice = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                            Text("Ciao!")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text("Czas na codzienną dawkę włoskiego.")
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.top)

                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Do powtórki")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("\(dueCards.count)")
                                    .font(.system(size: 64, weight: .semibold, design: .rounded))
                            }
                            Spacer()
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 50))
                                .foregroundColor(.accentColor.opacity(0.8))
                                .accessibilityHidden(true)
                        }

                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Button(action: {
                                    studyMode = .flashcards(prioritizedCards(from: dueCards))
                                }) {
                                    Text("Nauka")
                                        .font(.subheadline).bold()
                                        .foregroundColor(dueCards.isEmpty ? .secondary : .white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(dueCards.isEmpty ? Color.gray.opacity(0.3) : Color.primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .disabled(dueCards.isEmpty)
                                .buttonStyle(.borderless)

                                Button(action: {
                                    studyMode = .typing(prioritizedCards(from: dueCards))
                                }) {
                                    Text("Wpisywanie")
                                        .font(.subheadline).bold()
                                        .foregroundColor(dueCards.isEmpty ? .secondary : .primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(dueCards.isEmpty ? Color.gray.opacity(0.15) : Color.orange.opacity(0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .disabled(dueCards.isEmpty)
                                .buttonStyle(.borderless)
                            }

                            HStack(spacing: 12) {
                                Button(action: { isFreePractice = true }) {
                                    Text("Trening")
                                        .font(.subheadline).bold()
                                        .foregroundColor(.blue)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.blue.opacity(0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .buttonStyle(.borderless)

                                Button(action: {
                                    // Fetch all cards on demand for the quick match game
                                    let fetchAll = FetchDescriptor<Flashcard>()
                                    if let fetchedAll = try? modelContext.fetch(fetchAll) {
                                        studyMode = .match(fetchedAll)
                                    }
                                }) {
                                    Text("Szybki")
                                        .font(.subheadline).bold()
                                        .foregroundColor(allCardsCount < 6 ? .secondary : .purple)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(allCardsCount < 6 ? Color.gray.opacity(0.15) : Color.purple.opacity(0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .disabled(allCardsCount < 6)
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    .padding(24)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                    HStack(spacing: 12) {
                        StatCard(title: "Seria", value: "\(seriaCount) dni", icon: "flame.fill", color: .orange)
                        StatCard(title: "Czas", value: formatTime(todayStudyTime), icon: "clock.fill", color: .blue)
                        StatCard(title: "Poznane", value: "\(poznaneCount)", icon: "checkmark.seal.fill", color: .green)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Dzisiejszy cel (seria)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(todayCount) / \(dailyGoal)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        ProgressView(value: min(Double(todayCount), Double(dailyGoal)), total: Double(dailyGoal))
                            .progressViewStyle(LinearProgressViewStyle(tint: todayCount >= dailyGoal ? .green : .orange))
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Spacer()
            }
            .padding(.horizontal)
            .scrollDisabled(true)
            .background(Color.primary.opacity(0.03).ignoresSafeArea())
            .onAppear { calculateStats() }
            .onChange(of: dailyGoal) { _, _ in calculateStats() }
#if os(iOS)
            .fullScreenCover(item: $studyMode, onDismiss: { calculateStats() }) { mode in
                switch mode {
                case .flashcards(let cards):
                    StudySessionView(cards: cards, isFreePractice: false)
                case .typing(let cards):
                    TypingStudySessionView(cards: cards, isFreePractice: false)
                case .match(let cards):
                    QuickMatchSessionView(allCards: cards)
                }
            }
#else
            .sheet(item: $studyMode, onDismiss: { calculateStats() }) { mode in
                switch mode {
                case .flashcards(let cards):
                    StudySessionView(cards: cards, isFreePractice: false)
                        .frame(minWidth: 400, minHeight: 500)
                case .typing(let cards):
                    TypingStudySessionView(cards: cards, isFreePractice: false)
                        .frame(minWidth: 400, minHeight: 500)
                case .match(let cards):
                    QuickMatchSessionView(allCards: cards)
                        .frame(minWidth: 500, minHeight: 600)
                }
            }
#endif
            .sheet(isPresented: $isFreePractice) {
                FreePracticeConfigView()
            }
        }
    }

    private func prioritizedCards(from cards: [Flashcard]) -> [Flashcard] {
        // performance hack: stabilne sortowanie unikające naruszenia strict weak ordering
        let weightedCards = cards.map { card -> (Flashcard, Double) in
            let weight = card.easeFactor < 1.4 ? 2.0 : 1.0
            return (card, weight * Double.random(in: 0..<1))
        }
        return weightedCards.sorted { $0.1 > $1.1 }.map { $0.0 }
    }

    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        if minutes == 0 { return "< 1 min" }
        return "\(minutes) min"
    }

    private func calculateStats() {
        // Fetch due cards optimized: splitting OR into two separate queries to sidestep #Predicate limits
        let now = Date()
        let overdueDesc = FetchDescriptor<Flashcard>(predicate: #Predicate { $0.isLeech == false && $0.nextReviewDate <= now })
        let hardDesc = FetchDescriptor<Flashcard>(predicate: #Predicate { $0.isLeech == false && $0.easeFactor < 1.4 })

        let overdueCards = (try? modelContext.fetch(overdueDesc)) ?? []
        let hardCards = (try? modelContext.fetch(hardDesc)) ?? []

        // Use Set to uniquely combine the arrays efficiently
        let combinedSet = Set(overdueCards).union(hardCards)
        self.dueCards = Array(combinedSet)

        let allCountDesc = FetchDescriptor<Flashcard>()
        self.allCardsCount = (try? modelContext.fetchCount(allCountDesc)) ?? 0

        let todayStr = DateFormatter.yyyyMMdd.string(from: Date())
        let poznaneDescriptor = FetchDescriptor<Flashcard>(predicate: #Predicate { $0.repetitions > 0 })
        poznaneCount = (try? modelContext.fetchCount(poznaneDescriptor)) ?? 0

        let allActDescriptor = FetchDescriptor<DailyActivity>()
        if let allActivities = try? modelContext.fetch(allActDescriptor) {
            // performance hack: użycie reduce(into:) zamiast map+Dictionary unika alokacji tymczasowej tablicy krotek (O(N) pamięciowo optymalne)
            let activityDict = allActivities.reduce(into: [String: DailyActivity]()) { dict, activity in
                dict[activity.dateString] = activity
            }

            todayCount = activityDict[todayStr]?.count ?? 0
            todayStudyTime = activityDict[todayStr]?.studyTime ?? 0.0

            var currentStreak = 0
            var checkDate = Date()
            let calendar = Calendar.current

            if (activityDict[todayStr]?.count ?? 0) >= dailyGoal {
                currentStreak += 1
            }

            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            while true {
                let dateStr = DateFormatter.yyyyMMdd.string(from: checkDate)
                if let act = activityDict[dateStr], act.count >= dailyGoal {
                    currentStreak += 1
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                } else {
                    break
                }
            }
            seriaCount = currentStreak
        }
    }
}

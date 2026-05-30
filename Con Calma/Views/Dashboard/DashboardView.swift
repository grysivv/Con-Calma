import SwiftUI
import SwiftData

// Zabezpieczenie przed "pustymi" sesjami
enum StudyMode: Identifiable {
    case flashcards([Flashcard])
    case typing([Flashcard])

    var id: String {
        switch self {
        case .flashcards: return "flashcards"
        case .typing: return "typing"
        }
    }
}

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var allCards: [Flashcard]

    var dueCards: [Flashcard] {
        let now = Date()
        // Pobierz fiszki, których termin minął, ORAZ te, które są trudne (niezależnie od daty)
        return allCards.filter { $0.nextReviewDate <= now || $0.easeFactor < 1.4 }
    }

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
                        }

                        HStack(spacing: 12) {
                            Button(action: {
                                studyMode = .flashcards(prioritizedCards(from: dueCards))
                            }) {
                                Text("Nauka")
                                    .font(.subheadline).bold()
                                    .foregroundColor(.white)
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
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.orange.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .disabled(dueCards.isEmpty)
                            .buttonStyle(.borderless)

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
                }
            }
#endif
            .sheet(isPresented: $isFreePractice) {
                FreePracticeConfigView()
            }
        }
    }

    private func prioritizedCards(from cards: [Flashcard]) -> [Flashcard] {
        let weightedCards = cards.map { card -> (Flashcard, Double) in
            let weight = card.easeFactor < 1.4 ? 2.0 : 1.0
            return (card, weight * Double.random(in: 0..<1))
        }
        // Stabilne sortowanie na podstawie wylosowanej wagi
        return weightedCards.sorted { $0.1 > $1.1 }.map { $0.0 }
    }

    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        if minutes == 0 { return "< 1 min" }
        return "\(minutes) min"
    }

    private func calculateStats() {
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

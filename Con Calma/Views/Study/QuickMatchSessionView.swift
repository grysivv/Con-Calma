import SwiftUI
import SwiftData
import AVFoundation

struct MatchPair: Identifiable, Equatable {
    let id = UUID()
    let card: Flashcard
}

struct MatchItem: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isItalian: Bool
    let pairId: UUID
}

struct QuickMatchSessionView: View {
    @Environment(\.dismiss) var dismiss

    let allCards: [Flashcard]

    @State private var leftItems: [MatchItem] = []
    @State private var rightItems: [MatchItem] = []

    @State private var selectedLeft: MatchItem?
    @State private var selectedRight: MatchItem?

    @State private var matchedPairIds: Set<UUID> = []
    @State private var isWrongMatch: Bool = false

    @State private var timeRemaining: Int = 9
    @State private var timer: Timer? = nil

    @State private var roundComplete: Bool = false
    @State private var gameOver: Bool = false
    @State private var matchesFoundCount: Int = 0

    @State private var synthesizer = AVSpeechSynthesizer()

    var body: some View {
        NavigationStack {
            VStack {
                if gameOver {
                    gameOverView
                } else if roundComplete {
                    roundCompleteView
                } else {
                    gameView
                }
            }
            .background(Color.primary.opacity(0.03).ignoresSafeArea())
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        stopTimer()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title3)
                            .accessibilityLabel("Zamknij")
                    }
                    .buttonStyle(.plain)
                }
            }
            .onAppear {
                startNewRound()
            }
            .onDisappear {
                stopTimer()
            }
        }
    }

    private var gameView: some View {
        VStack {
            // Timer Bar
            VStack {
                Text("00:0\(timeRemaining)")
                    .font(.system(.title, design: .monospaced, weight: .bold))
                    .foregroundColor(timeRemaining <= 3 ? .red : .primary)

                ProgressView(value: Double(timeRemaining), total: 9.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: timeRemaining <= 3 ? .red : .accentColor))
                    .padding(.horizontal)
            }
            .padding(.top)

            Spacer()

            HStack(spacing: 20) {
                // Left Column (Italian)
                VStack(spacing: 12) {
                    ForEach(leftItems) { item in
                        ItemButton(
                            item: item,
                            isSelected: selectedLeft?.id == item.id,
                            isMatched: matchedPairIds.contains(item.pairId),
                            isError: isWrongMatch && selectedLeft?.id == item.id
                        ) {
                            handleSelection(item: item)
                        }
                    }
                }

                // Right Column (Polish)
                VStack(spacing: 12) {
                    ForEach(rightItems) { item in
                        ItemButton(
                            item: item,
                            isSelected: selectedRight?.id == item.id,
                            isMatched: matchedPairIds.contains(item.pairId),
                            isError: isWrongMatch && selectedRight?.id == item.id
                        ) {
                            handleSelection(item: item)
                        }
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
    }

    private var gameOverView: some View {
        VStack(spacing: 20) {
            Image(systemName: "timer")
                .font(.system(size: 60))
                .foregroundColor(.red)
                .accessibilityHidden(true)
            Text("Czas minął!")
                .font(.title)
                .bold()
            Text("Zdobyte pary: \(matchesFoundCount)")
                .font(.headline)
                .foregroundColor(.secondary)

            Button(action: {
                matchesFoundCount = 0
                startNewRound()
            }) {
                Text("Zagraj ponownie")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.top, 20)
        }
    }

    private var roundCompleteView: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
                .accessibilityHidden(true)
            Text("Runda zaliczona!")
                .font(.title)
                .bold()
            Text("Przygotuj się...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }

    private func startNewRound() {
        guard allCards.count >= 6 else {
            // Bezpiecznik jeśli za mało fiszek
            gameOver = true
            return
        }

        let shuffledCards = allCards.shuffled().prefix(6)
        let pairs = shuffledCards.map { MatchPair(card: $0) }

        var lefts: [MatchItem] = []
        var rights: [MatchItem] = []

        for pair in pairs {
            lefts.append(MatchItem(text: pair.card.front, isItalian: true, pairId: pair.id))
            rights.append(MatchItem(text: pair.card.back, isItalian: false, pairId: pair.id))
        }

        leftItems = lefts.shuffled()
        rightItems = rights.shuffled()

        selectedLeft = nil
        selectedRight = nil
        matchedPairIds.removeAll()
        isWrongMatch = false
        roundComplete = false
        gameOver = false
        timeRemaining = 9

        startTimer()
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.stopTimer()
                self.gameOver = true
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func handleSelection(item: MatchItem) {
        if matchedPairIds.contains(item.pairId) || isWrongMatch { return }

        if item.isItalian {
            if selectedLeft?.id == item.id {
                selectedLeft = nil
            } else {
                selectedLeft = item
                speak(item.text)
            }
        } else {
            if selectedRight?.id == item.id {
                selectedRight = nil
            } else {
                selectedRight = item
            }
        }

        checkMatch()
    }

    private func checkMatch() {
        guard let left = selectedLeft, let right = selectedRight else { return }

        if left.pairId == right.pairId {
            // Sukces
            withAnimation(.spring()) {
                matchedPairIds.insert(left.pairId)
                selectedLeft = nil
                selectedRight = nil
                matchesFoundCount += 1
            }

#if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
#endif

            if matchedPairIds.count == leftItems.count {
                stopTimer()
                withAnimation(.easeInOut) {
                    roundComplete = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        startNewRound()
                    }
                }
            }

        } else {
            // Błąd
            isWrongMatch = true
#if os(iOS)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
#endif

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut) {
                    selectedLeft = nil
                    selectedRight = nil
                    isWrongMatch = false
                }
            }
        }
    }

    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "it-IT")
        synthesizer.speak(utterance)
    }
}

struct ItemButton: View {
    let item: MatchItem
    let isSelected: Bool
    let isMatched: Bool
    let isError: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(item.text)
                .font(.system(size: 16, weight: .semibold))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, minHeight: 60)
                .padding(.horizontal, 8)
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected && !isError ? Color.accentColor : Color.clear, lineWidth: 2)
                )
                .opacity(isMatched ? 0.0 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isMatched)
    }

    private var backgroundColor: Color {
        if isError {
            return .red.opacity(0.8)
        } else if isSelected {
            return Color.accentColor.opacity(0.15)
        } else {
            return Color.secondary.opacity(0.1)
        }
    }

    private var foregroundColor: Color {
        if isError {
            return .white
        } else if isSelected {
            return .accentColor
        } else {
            return .primary
        }
    }
}

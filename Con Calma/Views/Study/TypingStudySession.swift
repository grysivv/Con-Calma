import SwiftUI
import SwiftData
import Combine
import AVFoundation
#if os(iOS)
import UIKit
#endif

struct TypingStudySessionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    let cards: [Flashcard]
    var isFreePractice: Bool = false

    @State private var currentIndex = 0
    @State private var userAnswer = ""
    @State private var showFeedback = false
    @State private var wasCorrect = false
    @State private var hasFailedCurrentCard = false
    @State private var editingCard: Flashcard?

    @State private var lastBackup: FlashcardBackup?

    @State private var sessionTime: Double = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @State private var synthesizer = AVSpeechSynthesizer()
    @FocusState private var isInputFieldFocused: Bool

    var progress: Double {
        guard !cards.isEmpty else { return 1.0 }
        return Double(currentIndex) / Double(cards.count)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .primary))
                    .padding(.horizontal)
                    .padding(.top)

                Spacer()

                if currentIndex < cards.count {
                    let card = cards[currentIndex]
                    VStack(spacing: 16) {
                        if let category = card.category, !category.isEmpty {
                            Text(category.uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                        } else {
                            Text(" ")
                                .font(.caption)
                        }

                        if showFeedback {
                            if !wasCorrect {
                                Text(card.front)
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.green)
                                    Text(card.front)
                                        .font(.system(size: 34, weight: .bold, design: .rounded))
                                        .foregroundColor(.green)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                            }
                        } else {
                            Text(card.back)
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        TextField("Wpisz po włosku...", text: $userAnswer)
                            .textFieldStyle(.roundedBorder)
                            .focused($isInputFieldFocused)
                            .foregroundStyle(showFeedback ? (wasCorrect ? .green : .red) : .primary)
                            .onSubmit { checkAnswer() }
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
#endif

                        HStack(spacing: 12) {
                            Button(action: { submit(answerIsCorrect: false, skipForceTyping: true) }) {
                                Text("Pomiń")
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(showFeedback ? Color.secondary.opacity(0.05) : Color.secondary.opacity(0.15))
                                    .foregroundColor(showFeedback ? Color.secondary.opacity(0.3) : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            .disabled(showFeedback)

                            Button(action: { checkAnswer() }) {
                                Text("Sprawdź")
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background((showFeedback || userAnswer.trimmingCharacters(in: .whitespaces).isEmpty) ? Color.secondary.opacity(0.2) : Color.primary)
                                    .foregroundColor((showFeedback || userAnswer.trimmingCharacters(in: .whitespaces).isEmpty) ? Color.secondary.opacity(0.5) : .white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            .disabled(showFeedback || userAnswer.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                            .accessibilityHidden(true)
                        Text(isFreePractice ? "Koniec treningu!" : "Koniec na dzisiaj!")
                            .font(.title)
                            .bold()

                        Button(action: { dismiss() }) {
                            Text("Zakończ")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 14)
                                .background(Color.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
            }
            .background(Color.primary.opacity(0.03).ignoresSafeArea())
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.title3)
                                .accessibilityLabel("Zamknij")
                        }
                        .buttonStyle(.plain)

                        Button(action: { undoLastAction() }) {
                            Image(systemName: "arrow.uturn.backward")
                                .foregroundColor(lastBackup == nil ? .gray : .accentColor)
                                .font(.title3)
                                .accessibilityLabel("Cofnij")
                        }
                        .disabled(lastBackup == nil)
                        .buttonStyle(.plain)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("\(currentIndex) / \(cards.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .primaryAction) {
                    if currentIndex < cards.count {
                        Button(action: { editingCard = cards[currentIndex] }) {
                            Image(systemName: "pencil")
                                .accessibilityLabel("Edytuj fiszkę")
                        }
                    }
                }
            }
            .sheet(item: $editingCard) { card in
                EditFlashcardView(card: card)
            }
            .onReceive(timer) { _ in
                if currentIndex < cards.count && !showFeedback {
                    sessionTime += 1
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isInputFieldFocused = true
                }
            }
            .onDisappear {
                saveStudyTime()
            }
        }
    }

    private func checkAnswer() {
        let card = cards[currentIndex]

        let normalizedUser = userAnswer
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "´", with: "'")
            .replacingOccurrences(of: "`", with: "'")

        let normalizedCorrect = card.front
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "´", with: "'")
            .replacingOccurrences(of: "`", with: "'")

        let correct = normalizedUser == normalizedCorrect
        submit(answerIsCorrect: correct)
    }

    private func submit(answerIsCorrect: Bool, skipForceTyping: Bool = false) {
        showFeedback = true
        wasCorrect = answerIsCorrect

#if os(iOS)
        if answerIsCorrect {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
#endif

        let utterance = AVSpeechUtterance(string: cards[currentIndex].front)
        utterance.voice = AVSpeechSynthesisVoice(language: "it-IT")
        synthesizer.speak(utterance)

        if !answerIsCorrect {
            hasFailedCurrentCard = true

            if !skipForceTyping {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showFeedback = false
                        userAnswer = ""
                    }
                }
                return
            }
        } else if hasFailedCurrentCard {
            // Jeśli użytkownik wpisuje poprawnie z przymusu, nie pokazujemy feedbacku przez długi czas i pomijamy 'Dobrze'
            showFeedback = false
        }

        if !isFreePractice {
            let card = cards[currentIndex]
            let quality: ReviewQuality = hasFailedCurrentCard ? .again : .good
            lastBackup = FlashcardBackup(
                repetitions: card.repetitions,
                interval: card.interval,
                easeFactor: card.easeFactor,
                nextReviewDate: card.nextReviewDate,
                lapsesCount: card.lapsesCount,
                totalReviews: card.totalReviews,
                successReviews: card.successReviews,
                isLeech: card.isLeech,
                activityModified: (quality != .again)
            )

            SRSAlgorithm.processReview(for: card, quality: quality)

            if quality != .again {
                let todayStr = DateFormatter.yyyyMMdd.string(from: Date())
                // performance hack: predykat i fetchLimit = 1 aby uniknąć ładowania wszystkich rekordów bazy w poszukiwaniu jednego
                var descriptor = FetchDescriptor<DailyActivity>(predicate: #Predicate { $0.dateString == todayStr })
                descriptor.fetchLimit = 1
                if let activities = try? modelContext.fetch(descriptor) {
                    if let todayActivity = activities.first {
                        todayActivity.count += 1
                    } else {
                        let newActivity = DailyActivity(dateString: todayStr, count: 1)
                        modelContext.insert(newActivity)
                    }
                }
            }
            try? modelContext.save()
        }

        saveStudyTime()

        // Wydłużony czas dla nowych słówek, krótki jeśli wpisanie wymuszone po błędzie
        let delayTime = hasFailedCurrentCard && answerIsCorrect ? 0.3 : 1.5
        DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentIndex += 1
                userAnswer = ""
                showFeedback = false
                hasFailedCurrentCard = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isInputFieldFocused = true
            }
        }
    }

    private func undoLastAction() {
        guard let backup = lastBackup else { return }
        guard currentIndex > 0 else { return }

        currentIndex -= 1
        let card = cards[currentIndex]

        card.repetitions = backup.repetitions
        card.interval = backup.interval
        card.easeFactor = backup.easeFactor
        card.nextReviewDate = backup.nextReviewDate
        card.lapsesCount = backup.lapsesCount
        card.totalReviews = backup.totalReviews
        card.successReviews = backup.successReviews
        card.isLeech = backup.isLeech

        if backup.activityModified {
            let todayStr = DateFormatter.yyyyMMdd.string(from: Date())
            var descriptor = FetchDescriptor<DailyActivity>(predicate: #Predicate { $0.dateString == todayStr })
            descriptor.fetchLimit = 1
            if let activities = try? modelContext.fetch(descriptor), let todayActivity = activities.first {
                todayActivity.count = max(0, todayActivity.count - 1)
            }
        }

        try? modelContext.save()

        withAnimation(.easeInOut(duration: 0.3)) {
            userAnswer = ""
            showFeedback = false
            hasFailedCurrentCard = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isInputFieldFocused = true
        }

        lastBackup = nil
    }

    private func saveStudyTime() {
        guard sessionTime > 0 else { return }
        let todayStr = DateFormatter.yyyyMMdd.string(from: Date())
        // performance hack: predykat i fetchLimit = 1 zapobiega problemom pamięciowym przy dużej ilości dni
        var descriptor = FetchDescriptor<DailyActivity>(predicate: #Predicate { $0.dateString == todayStr })
        descriptor.fetchLimit = 1
        if let activities = try? modelContext.fetch(descriptor) {
            if let todayActivity = activities.first {
                todayActivity.studyTime += sessionTime
            } else {
                let newActivity = DailyActivity(dateString: todayStr, count: 0, studyTime: sessionTime)
                modelContext.insert(newActivity)
            }
            try? modelContext.save()
            sessionTime = 0
        }
    }
}

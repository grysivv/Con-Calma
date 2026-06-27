import SwiftUI
import SwiftData
import Combine
import AVFoundation
#if os(iOS)
import UIKit
#endif

struct FlashcardBackup {
    let repetitions: Int
    let interval: Int
    let easeFactor: Double
    let nextReviewDate: Date
    let lapsesCount: Int
    let totalReviews: Int
    let successReviews: Int
    let isLeech: Bool
    let activityModified: Bool
}

struct StudySessionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("showPolishOnFront") private var showPolishOnFront: Bool = true

    let cards: [Flashcard]
    var isFreePractice: Bool = false

    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var editingCard: Flashcard?
    @State private var cardOffset: CGSize = .zero

    @State private var lastBackup: FlashcardBackup?

    @State private var sessionTime: Double = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @State private var synthesizer = AVSpeechSynthesizer()

    var progress: Double {
        guard !cards.isEmpty else { return 1.0 }
        return Double(currentIndex) / Double(cards.count)
    }

    var body: some View {
        NavigationStack {
            VStack {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .primary))
                    .padding(.horizontal)
                    .padding(.top)

                Spacer()

                if currentIndex < cards.count {
                    FlashcardView(card: cards[currentIndex], isFlipped: $isFlipped)
                        .id(currentIndex)
                        .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                        .padding(.horizontal, 24)
                        .offset(x: cardOffset.width, y: 0)
                        .rotationEffect(.degrees(Double(cardOffset.width / 20)))
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    // Umożliwiamy swipe w każdym wypadku. Zgodnie z prośbą, można przesunąć fiszkę od razu przy polskiej wersji.
                                    cardOffset = gesture.translation
                                }
                                .onEnded { _ in
                                    if cardOffset.width > 100 {
                                        // Swipe right - Good
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            cardOffset.width = 500
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            processAnswer(quality: .good)
                                        }
                                    } else if cardOffset.width < -100 {
                                        // Swipe left - Again
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            cardOffset.width = -500
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            processAnswer(quality: .again)
                                        }
                                    } else {
                                        withAnimation(.spring()) {
                                            cardOffset = .zero
                                        }
                                    }
                                }
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isFlipped.toggle()
                            }
                            triggerTTS()
                        }

                    Spacer()

                    if isFlipped {
                        HStack(spacing: 16) {
                            StudyButton(title: "Nie umiem", color: .red) {
                                processAnswer(quality: .again)
                            }
                            StudyButton(title: "Średnio", color: .orange) {
                                processAnswer(quality: .hard)
                            }
                            StudyButton(title: "Umiem", color: .green) {
                                processAnswer(quality: .good)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 30)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
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
                if currentIndex < cards.count {
                    sessionTime += 1
                }
            }
            .onAppear {
                triggerTTS()
            }
            .onDisappear {
                saveStudyTime()
            }
        }
    }

    // Głos TTS: Odpala się wyłącznie, gdy widoczna strona fiszki zawiera język włoski
    private func triggerTTS() {
        guard currentIndex < cards.count else { return }
        let isItalianVisible = showPolishOnFront ? isFlipped : !isFlipped
        if isItalianVisible {
            let utterance = AVSpeechUtterance(string: cards[currentIndex].front)
            utterance.voice = AVSpeechSynthesisVoice(language: "it-IT")
            synthesizer.speak(utterance)
        }
    }

    private func processAnswer(quality: ReviewQuality) {
#if os(iOS)
        switch quality {
        case .good:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .hard:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .again:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
#endif

        if !isFreePractice {
            let card = cards[currentIndex]
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

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            isFlipped = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentIndex += 1
            }
        }

        // Zresetuj offset bez animacji aby nowa karta wjechała z poprawnej pozycji
        cardOffset = .zero

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            triggerTTS()
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
            isFlipped = false
            cardOffset = .zero
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

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

    @State private var sessionTime: Double = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var synthesizer = AVSpeechSynthesizer()

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
                        Text("Przetłumacz na włoski:")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(card.back)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        TextField("Wpisz po włosku...", text: $userAnswer)
                            .textFieldStyle(.roundedBorder)
#if os(iOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
#endif

                        if showFeedback {
                            HStack(spacing: 8) {
                                Image(systemName: wasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(wasCorrect ? .green : .red)
                                Text(wasCorrect ? "Dobrze!" : "Poprawna odpowiedź: \(card.front)")
                                    .foregroundColor(wasCorrect ? .green : .red)
                            }
                        }

                        HStack(spacing: 12) {
                            Button(action: { submit(answerIsCorrect: false) }) {
                                Text("Pomiń")
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.secondary.opacity(0.15))
                                    .foregroundColor(.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                            .disabled(showFeedback)
                            
                            Button(action: { checkAnswer() }) {
                                Text("Sprawdź")
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.primary)
                                    .foregroundColor(.white)
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
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }
                ToolbarItem(placement: .principal) {
                    Text("\(currentIndex) / \(cards.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            .onReceive(timer) { _ in
                if currentIndex < cards.count && !showFeedback {
                    sessionTime += 1
                }
            }
            .onDisappear {
                saveStudyTime()
            }
        }
    }

    private func checkAnswer() {
        let card = cards[currentIndex]
        let normalizedUser = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedCorrect = card.front.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let correct = normalizedUser == normalizedCorrect
        submit(answerIsCorrect: correct)
    }

    private func submit(answerIsCorrect: Bool) {
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

        if !isFreePractice {
            let card = cards[currentIndex]
            let quality: ReviewQuality = answerIsCorrect ? .good : .again
            SRSAlgorithm.processReview(for: card, quality: quality)

            if answerIsCorrect {
                let todayStr = DateFormatter.yyyyMMdd.string(from: Date())
                let descriptor = FetchDescriptor<DailyActivity>()
                if let activities = try? modelContext.fetch(descriptor) {
                    if let todayActivity = activities.first(where: { $0.dateString == todayStr }) {
                        todayActivity.count += 1
                    } else {
                        let newActivity = DailyActivity(dateString: todayStr, count: 1)
                        modelContext.insert(newActivity)
                    }
                }
            }
            try? modelContext.save()
        }

        // Wydłużony czas, byś zdążył usłyszeć słówko po włosku i zobaczyć błędy
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentIndex += 1
                userAnswer = ""
                showFeedback = false
            }
        }
    }
    
    private func saveStudyTime() {
        guard sessionTime > 0 else { return }
        let todayStr = DateFormatter.yyyyMMdd.string(from: Date())
        let descriptor = FetchDescriptor<DailyActivity>()
        if let activities = try? modelContext.fetch(descriptor) {
            if let todayActivity = activities.first(where: { $0.dateString == todayStr }) {
                todayActivity.studyTime += sessionTime
            } else {
                let newActivity = DailyActivity(dateString: todayStr, count: 0, studyTime: sessionTime)
                modelContext.insert(newActivity)
            }
            try? modelContext.save()
        }
    }
}

import Foundation

enum ReviewQuality: Int {
    case again = 0
    case hard = 1
    case good = 2
}

struct SRSAlgorithm {
    static func processReview(for card: Flashcard, quality: ReviewQuality) {
        let now = Date()

        card.totalReviews += 1

        switch quality {
        case .again:
            card.lapsesCount += 1
            if card.interval > 8 {
                card.interval = 1
                card.easeFactor = max(1.3, card.easeFactor * 0.75)
            } else {
                card.repetitions = 0
                card.interval = 0
            }
            // Celowe wymuszenie daty z przeszłości, aby po wyjściu z sesji i wejściu
            // z powrotem słówko NATYCHMIAST pojawiło się ponownie w puli "Do powtórki",
            // nawet jeśli aplikacja zapamiętała `Date()` ze startu widoku.
            card.nextReviewDate = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now

        case .hard:
            card.lapsesCount += 1
            if card.interval > 8 {
                card.interval = 1
                card.easeFactor = max(1.3, card.easeFactor * 0.75)
            } else {
                card.interval = 1
            }
            card.nextReviewDate = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now

        case .good:
            card.successReviews += 1
            card.lapsesCount = 0 // Reset błędów pod rząd w przypadku poprawnej odpowiedzi
            if card.repetitions == 0 {
                card.interval = 3
            } else if card.repetitions == 1 {
                card.interval = 7
            } else {
                card.interval = Int(round(Double(card.interval) * card.easeFactor))
            }
            card.repetitions += 1
            card.nextReviewDate = Calendar.current.date(byAdding: .day, value: card.interval, to: now) ?? now
        }

        // Sprawdzenie warunków Leech (Pijawki)
        let easeRatio = Double(card.successReviews) / Double(max(1, card.totalReviews))
        if (card.totalReviews >= 10 && easeRatio < 0.3) || card.lapsesCount >= 5 {
            card.isLeech = true
        }
    }
}

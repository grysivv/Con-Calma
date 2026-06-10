import Foundation
import SwiftData

@Model
final class Flashcard {
    var front: String
    var back: String
    var example: String?
    var category: String?

    var repetitions: Int = 0
    var interval: Int = 0
    var easeFactor: Double = 2.5
    var nextReviewDate: Date = Date()
    var lapsesCount: Int = 0
    var totalReviews: Int = 0
    var successReviews: Int = 0
    var isLeech: Bool = false

    var creationDate: Date = Date()

    init(front: String, back: String, example: String? = nil, category: String? = nil) {
        self.front = front
        self.back = back
        self.example = example
        self.category = category
    }

    func reviveLeech() {
        self.isLeech = false
        self.lapsesCount = 0
        self.totalReviews = 0
        self.successReviews = 0
        self.interval = 1
        self.easeFactor = 2.0
        self.nextReviewDate = Date()
    }
}

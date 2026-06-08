//
//  SRSAlgorithmTests.swift
//  Con CalmaTests
//

import Testing
import Foundation
@testable import Con_Calma

struct SRSAlgorithmTests {

    @Test func testProcessReviewAgain_IntervalGreaterThan8() {
        let card = Flashcard(front: "A", back: "B")
        card.interval = 10
        card.easeFactor = 2.0

        SRSAlgorithm.processReview(for: card, quality: .again)

        #expect(card.interval == 1)
        #expect(card.easeFactor == 1.5)
        #expect(card.nextReviewDate < Date())
    }

    @Test func testProcessReviewAgain_IntervalLessThanOrEqual8() {
        let card = Flashcard(front: "A", back: "B")
        card.interval = 5
        card.repetitions = 3

        SRSAlgorithm.processReview(for: card, quality: .again)

        #expect(card.repetitions == 0)
        #expect(card.interval == 0)
        #expect(card.nextReviewDate < Date())
    }

    @Test func testProcessReviewAgain_EaseFactorFloor() {
        let card = Flashcard(front: "A", back: "B")
        card.interval = 10
        card.easeFactor = 1.3

        SRSAlgorithm.processReview(for: card, quality: .again)

        // 1.3 * 0.75 = 0.975, but max(1.3, ...) ensures it doesn't drop below 1.3
        #expect(card.easeFactor == 1.3)
    }

    @Test func testProcessReviewHard_IntervalGreaterThan8() {
        let card = Flashcard(front: "A", back: "B")
        card.interval = 10
        card.easeFactor = 2.0

        SRSAlgorithm.processReview(for: card, quality: .hard)

        #expect(card.interval == 1)
        #expect(card.easeFactor == 1.5)
        #expect(card.nextReviewDate > Date())
    }

    @Test func testProcessReviewHard_IntervalLessThanOrEqual8() {
        let card = Flashcard(front: "A", back: "B")
        card.interval = 5
        card.easeFactor = 2.0

        SRSAlgorithm.processReview(for: card, quality: .hard)

        #expect(card.interval == 1)
        #expect(card.easeFactor == 2.0)
        #expect(card.nextReviewDate > Date())
    }

    @Test func testProcessReviewGood_Repetitions0() {
        let card = Flashcard(front: "A", back: "B")
        card.repetitions = 0
        card.interval = 0

        SRSAlgorithm.processReview(for: card, quality: .good)

        #expect(card.interval == 3)
        #expect(card.repetitions == 1)
        #expect(card.nextReviewDate > Date())
    }

    @Test func testProcessReviewGood_Repetitions1() {
        let card = Flashcard(front: "A", back: "B")
        card.repetitions = 1
        card.interval = 3

        SRSAlgorithm.processReview(for: card, quality: .good)

        #expect(card.interval == 7)
        #expect(card.repetitions == 2)
        #expect(card.nextReviewDate > Date())
    }

    @Test func testProcessReviewGood_RepetitionsMoreThan1() {
        let card = Flashcard(front: "A", back: "B")
        card.repetitions = 2
        card.interval = 7
        card.easeFactor = 2.5

        SRSAlgorithm.processReview(for: card, quality: .good)

        // Int(round(Double(7) * 2.5)) = Int(round(17.5)) = 18
        #expect(card.interval == 18)
        #expect(card.repetitions == 3)
        #expect(card.nextReviewDate > Date())
    }

    @Test func testLeechDetection_LapsesThreshold() {
        let card = Flashcard(front: "A", back: "B")
        card.lapsesCount = 4
        card.totalReviews = 2
        card.successReviews = 1

        SRSAlgorithm.processReview(for: card, quality: .again)

        #expect(card.lapsesCount == 5)
        #expect(card.isLeech == true)
    }


    @Test func testLeechDetection_EaseRatioThreshold() {
        let card = Flashcard(front: "A", back: "B")
        card.totalReviews = 9 // To be 10 after review
        card.successReviews = 2 // 2/10 = 0.2 (< 0.3)
        card.lapsesCount = 1

        SRSAlgorithm.processReview(for: card, quality: .hard)

        #expect(card.totalReviews == 10)
        #expect(card.isLeech == true)
    }

    @Test func testReviveLeech() {
        let card = Flashcard(front: "A", back: "B")
        card.isLeech = true
        card.lapsesCount = 5
        card.totalReviews = 10
        card.successReviews = 2
        card.interval = 10
        card.easeFactor = 1.3

        card.reviveLeech()

        #expect(card.isLeech == false)
        #expect(card.lapsesCount == 0)
        #expect(card.totalReviews == 0)
        #expect(card.successReviews == 0)
        #expect(card.interval == 1)
        #expect(card.easeFactor == 2.0)
    }

    @Test func testLeechDetection_LapsesCountResetOnGood() {
        let card = Flashcard(front: "A", back: "B")
        card.lapsesCount = 4
        card.totalReviews = 5
        card.successReviews = 1

        SRSAlgorithm.processReview(for: card, quality: .good)

        #expect(card.lapsesCount == 0)
        #expect(card.isLeech == false)
    }
}

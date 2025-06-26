import XCTest
@testable import HikingSurvey

final class ScorerTests: XCTestCase {
    var scorer: Scorer!
    
    override func setUp() {
        super.setUp()
        scorer = Scorer()
    }
    
    override func tearDown() {
        scorer = nil
        super.tearDown()
    }
    
    func testPositiveSentiment() {
        let result = scorer.score("I love hiking! It's amazing and makes me happy.")
        XCTAssertGreaterThan(result.score, 0.1, "Score should be positive for positive sentiment.")
    }
    
    func testNegativeSentiment() {
        let result = scorer.score("I hate hiking. It's boring and exhausting.")
        XCTAssertLessThan(result.score, -0.1, "Score should be negative for negative sentiment.")
    }
    
    func testModerateSentiment() {
        let result = scorer.score("Hiking is okay. Sometimes I like it, sometimes I don't.")
        XCTAssertGreaterThanOrEqual(result.score, -0.1)
        XCTAssertLessThanOrEqual(result.score, 0.1)
    }
    
    func testEdgeCaseEmptyString() {
        let result = scorer.score("")
        XCTAssertEqual(result.score, 0.0, accuracy: 0.01, "Score should be 0 for empty string.")
    }
    
    func testEdgeCaseNeutralStatement() {
        let result = scorer.score("The sky is blue.")
        XCTAssertGreaterThanOrEqual(result.score, -0.1)
        XCTAssertLessThanOrEqual(result.score, 0.1)
    }
}

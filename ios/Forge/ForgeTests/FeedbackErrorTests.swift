import XCTest
@testable import Forge

/// Feedback failures used to collapse to a single Bool + one catch-all message.
/// These verify the typed mapping that replaced it.
final class FeedbackErrorTests: XCTestCase {

    func testHTTPStatusMapping() {
        XCTAssertNil(FeedbackError.fromHTTP(200))
        XCTAssertNil(FeedbackError.fromHTTP(201))
        XCTAssertEqual(FeedbackError.fromHTTP(400), .invalidRequest)
        XCTAssertEqual(FeedbackError.fromHTTP(422), .invalidRequest)
        XCTAssertEqual(FeedbackError.fromHTTP(401), .unauthorized)
        XCTAssertEqual(FeedbackError.fromHTTP(403), .unauthorized)
        XCTAssertEqual(FeedbackError.fromHTTP(429), .rateLimited)
        XCTAssertEqual(FeedbackError.fromHTTP(500), .serverError)
        XCTAssertEqual(FeedbackError.fromHTTP(503), .serverError)
        XCTAssertEqual(FeedbackError.fromHTTP(418), .unknown)
    }

    func testURLErrorMapping() {
        XCTAssertEqual(FeedbackError.fromURLError(URLError(.notConnectedToInternet)), .offline)
        XCTAssertEqual(FeedbackError.fromURLError(URLError(.networkConnectionLost)), .offline)
        XCTAssertEqual(FeedbackError.fromURLError(URLError(.timedOut)), .timeout)
        XCTAssertEqual(FeedbackError.fromURLError(URLError(.badServerResponse)), .unknown)
    }

    func testValidationCatchesEmptyAndTooLong() {
        XCTAssertEqual(FeedbackError.validate(message: "", email: nil),
                       .validation("Add a little detail before sending."))
        let long = String(repeating: "x", count: 4001)
        XCTAssertNotNil(FeedbackError.validate(message: long, email: nil))
    }

    func testValidationAcceptsGoodInputAndRejectsBadEmail() {
        XCTAssertNil(FeedbackError.validate(message: "the timer resets on lock", email: nil))
        XCTAssertNil(FeedbackError.validate(message: "hi", email: "user@example.com"))
        if case .validation? = FeedbackError.validate(message: "hi", email: "not-an-email") {
            // expected
        } else {
            XCTFail("Malformed email should fail validation")
        }
    }

    func testEveryErrorHasNonTechnicalMessage() {
        let all: [FeedbackError] = [.offline, .timeout, .invalidRequest, .unauthorized,
                                    .rateLimited, .serverError, .validation("x"), .unknown]
        for e in all { XCTAssertFalse(e.userMessage.isEmpty) }
    }
}

import XCTest

@testable import DeenFirst

final class HTTPClientTests: XCTestCase {

    func testHTTPClientSharedInstance() {
        XCTAssertNotNil(HTTPClient.shared)
    }

    func testNetworkErrorDescriptions() {
        let invalidResponse = NetworkError.invalidResponse
        XCTAssertEqual(invalidResponse.errorDescription, "Invalid server response")

        let httpError = NetworkError.httpError(404)
        XCTAssertEqual(httpError.errorDescription, "HTTP error: 404")
    }
}

import XCTest
@testable import SurahFocus

final class HTTPClientTests: XCTestCase {
    var client: HTTPClient!

    override func setUp() {
        client = HTTPClient()
    }

    override func tearDown() {
        client = nil
    }

    func testHTTPClientInitialization() {
        XCTAssertNotNil(client)
    }

    func testNetworkErrorDescriptions() {
        let invalidResponse = NetworkError.invalidResponse
        XCTAssertEqual(invalidResponse.errorDescription, "Invalid server response")

        let httpError = NetworkError.httpError(404)
        XCTAssertEqual(httpError.errorDescription, "HTTP error: 404")
    }
}

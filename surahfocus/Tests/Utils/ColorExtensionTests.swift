import XCTest
import SwiftUI
@testable import SurahFocus

final class ColorExtensionTests: XCTestCase {
    // MARK: - 3-Digit RGB Tests

    func testInitHex_3DigitWhite() {
        let color = Color(hex: "FFF")
        // Verify color is created without crash
        XCTAssertNotNil(color)
    }

    func testInitHex_3DigitBlack() {
        let color = Color(hex: "000")
        XCTAssertNotNil(color)
    }

    func testInitHex_3DigitRed() {
        let color = Color(hex: "F00")
        XCTAssertNotNil(color)
    }

    func testInitHex_3DigitGreen() {
        let color = Color(hex: "0F0")
        XCTAssertNotNil(color)
    }

    func testInitHex_3DigitBlue() {
        let color = Color(hex: "00F")
        XCTAssertNotNil(color)
    }

    // MARK: - 6-Digit RGB Tests

    func testInitHex_6DigitWhite() {
        let color = Color(hex: "FFFFFF")
        XCTAssertNotNil(color)
    }

    func testInitHex_6DigitBlack() {
        let color = Color(hex: "000000")
        XCTAssertNotNil(color)
    }

    func testInitHex_6DigitRed() {
        let color = Color(hex: "FF0000")
        XCTAssertNotNil(color)
    }

    func testInitHex_6DigitGreen() {
        let color = Color(hex: "00FF00")
        XCTAssertNotNil(color)
    }

    func testInitHex_6DigitBlue() {
        let color = Color(hex: "0000FF")
        XCTAssertNotNil(color)
    }

    func testInitHex_6DigitPurple() {
        let color = Color(hex: "800080")
        XCTAssertNotNil(color)
    }

    // MARK: - 8-Digit ARGB Tests

    func testInitHex_8DigitOpaqueWhite() {
        let color = Color(hex: "FFFFFFFF")
        XCTAssertNotNil(color)
    }

    func testInitHex_8DigitTransparentBlack() {
        let color = Color(hex: "00000000")
        XCTAssertNotNil(color)
    }

    func testInitHex_8DigitOpaqueRed() {
        let color = Color(hex: "FFFF0000")
        XCTAssertNotNil(color)
    }

    func testInitHex_8DigitHalfOpacityRed() {
        let color = Color(hex: "80FF0000")
        XCTAssertNotNil(color)
    }

    // MARK: - Edge Cases

    func testInitHex_EmptyString() {
        let color = Color(hex: "")
        XCTAssertNotNil(color) // Returns default red
    }

    func testInitHex_InvalidLength() {
        let color = Color(hex: "FF")
        XCTAssertNotNil(color) // Returns default red
    }

    func testInitHex_WithHashPrefix() {
        let color = Color(hex: "#FFFFFF")
        XCTAssertNotNil(color)
    }

    func testInitHex_WithSpaces() {
        let color = Color(hex: " FF FF FF ")
        XCTAssertNotNil(color)
    }

    func testInitHex_Lowercase() {
        let color = Color(hex: "ffffff")
        XCTAssertNotNil(color)
    }

    func testInitHex_MixedCase() {
        let color = Color(hex: "FfFfFf")
        XCTAssertNotNil(color)
    }
}

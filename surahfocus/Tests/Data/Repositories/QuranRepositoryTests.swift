import XCTest
@testable import SurahFocus

final class QuranRepositoryTests: XCTestCase {
    var repository: QuranRepositoryImpl!
    var mockAPIDataSource: MockQuranAPIDataSource!

    override func setUp() async throws {
        try await super.setUp()
        mockAPIDataSource = MockQuranAPIDataSource()
        repository = QuranRepositoryImpl(apiDataSource: mockAPIDataSource)
    }

    override func tearDown() async throws {
        repository = nil
        mockAPIDataSource = nil
        try await super.tearDown()
    }

    func testGetAllSurahs_ReturnsSurahs() async throws {
        // Given
        mockAPIDataSource.surahs = [
            Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationPlace: "Meccan")
        ]

        // When
        let result = try await repository.getAllSurahs()

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Al-Fatihah")
    }
}

class MockQuranAPIDataSource: QuranAPIDataSource {
    var surahs: [Surah] = []

    func fetchAllSurahs() async throws -> [Surah] {
        return surahs
    }

    func fetchSurah(number: Int) async throws -> (Surah, [Ayah]) {
        throw NSError(domain: "test", code: -1)
    }

    func fetchVerse(surahNo: Int, ayahNo: Int) async throws -> Ayah {
        throw NSError(domain: "test", code: -1)
    }

    func getReciters() -> [Reciter] {
        []
    }
}

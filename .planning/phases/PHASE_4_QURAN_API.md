# PHASE 4: QURAN API INTEGRATION
**Timeline:** Day 7 (Feb 9)  
**Duration:** 1 full day  
**Goal:** Quran API fully integrated, can fetch all surahs and ayahs, caching working

---

## PREREQUISITES

- [ ] Phase 3 completed (Onboarding + Screen Time working)
- [ ] 70+ tests passing
- [ ] HTTPClient ready from Phase 1
- [ ] Physical device available for testing

---

## PHASE OVERVIEW

This phase integrates the Quran API:
1. API data transfer objects (DTOs)
2. QuranAPIDataSource implementation
3. Caching strategy (text: 30 days, audio: stream only)
4. QuranRepository with cache layer
5. QuranService business logic
6. Integration tests with real API

**By end of Phase 4, you will have:**
- ✅ Can fetch all 114 surahs
- ✅ Can fetch surah details with ayahs
- ✅ Can get audio URLs for reciters
- ✅ Text content cached for 30 days
- ✅ 85+ unit tests passing

---

## TASK 4.1: API DTOS (Day 7 Morning - 1 hour)

### Step 1: Create Response DTOs

**Create `Sources/Data/DataSource/API/QuranAPIDTOs.swift`:**

```swift
import Foundation

// MARK: - Surah List Response

struct SurahListResponse: Codable {
    let data: [SurahDTO]
}

struct SurahDTO: Codable {
    let number: Int
    let name: String
    let englishName: String
    let englishNameTranslation: String
    let numberOfAyahs: Int
    let revelationType: String
}

// MARK: - Surah Detail Response

struct SurahDetailResponse: Codable {
    let data: SurahDetailDTO
}

struct SurahDetailDTO: Codable {
    let number: Int
    let name: String
    let englishName: String
    let englishNameTranslation: String
    let numberOfAyahs: Int
    let revelationType: String
    let ayahs: [AyahDTO]
}

struct AyahDTO: Codable {
    let number: Int
    let text: String
    let numberInSurah: Int
}

// MARK: - Reciter List Response

struct ReciterListResponse: Codable {
    let reciters: [ReciterDTO]
}

struct ReciterDTO: Codable {
    let id: Int
    let name: String
    let style: String?
}

// MARK: - DTO to Entity Mappers

extension SurahDTO {
    func toEntity() -> Surah {
        return Surah(
            number: number,
            name: name,
            englishName: englishName,
            englishNameTranslation: englishNameTranslation,
            numberOfAyahs: numberOfAyahs,
            revelationType: revelationType
        )
    }
}

extension AyahDTO {
    func toEntity(translation: String? = nil) -> Ayah {
        return Ayah(
            number: number,
            text: text,
            numberInSurah: numberInSurah,
            translation: translation
        )
    }
}

extension ReciterDTO {
    func toEntity() -> Reciter {
        return Reciter(
            id: id,
            name: name,
            style: style
        )
    }
}
```

### Step 2: Create DTO Tests

**Create `Tests/Data/DataSource/QuranAPIDTOsTests.swift`:**

```swift
import XCTest
@testable import SurahFocus

final class QuranAPIDTOsTests: XCTestCase {
    
    func testSurahDTODecoding() throws {
        let json = """
        {
            "number": 1,
            "name": "سُورَةُ ٱلْفَاتِحَةِ",
            "englishName": "Al-Fatihah",
            "englishNameTranslation": "The Opening",
            "numberOfAyahs": 7,
            "revelationType": "Meccan"
        }
        """
        
        let data = json.data(using: .utf8)!
        let dto = try JSONDecoder().decode(SurahDTO.self, from: data)
        
        XCTAssertEqual(dto.number, 1)
        XCTAssertEqual(dto.englishName, "Al-Fatihah")
        XCTAssertEqual(dto.numberOfAyahs, 7)
    }
    
    func testSurahDTOToEntity() {
        let dto = SurahDTO(
            number: 1,
            name: "سُورَةُ ٱلْفَاتِحَةِ",
            englishName: "Al-Fatihah",
            englishNameTranslation: "The Opening",
            numberOfAyahs: 7,
            revelationType: "Meccan"
        )
        
        let entity = dto.toEntity()
        
        XCTAssertEqual(entity.number, 1)
        XCTAssertEqual(entity.englishName, "Al-Fatihah")
        XCTAssertEqual(entity.numberOfAyahs, 7)
    }
    
    func testAyahDTOToEntity() {
        let dto = AyahDTO(
            number: 1,
            text: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
            numberInSurah: 1
        )
        
        let entity = dto.toEntity()
        
        XCTAssertEqual(entity.number, 1)
        XCTAssertEqual(entity.numberInSurah, 1)
        XCTAssertEqual(entity.text, "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
    }
    
    func testReciterDTOToEntity() {
        let dto = ReciterDTO(
            id: 7,
            name: "Mishary Rashid Alafasy",
            style: "Warsh"
        )
        
        let entity = dto.toEntity()
        
        XCTAssertEqual(entity.id, 7)
        XCTAssertEqual(entity.name, "Mishary Rashid Alafasy")
        XCTAssertEqual(entity.style, "Warsh")
    }
}
```

### Verification Checkpoint 1:

```bash
make test
```

**Expected Output:**
```
Test Suite 'QuranAPIDTOsTests' passed (4 tests)
```

---

## TASK 4.2: QURAN API DATA SOURCE (Day 7 Morning - 2 hours)

### Step 1: Create QuranAPIDataSource

**Create `Sources/Data/DataSource/API/QuranAPIDataSource.swift`:**

```swift
import Foundation

protocol QuranAPIDataSource {
    func fetchAllSurahs() async throws -> [Surah]
    func fetchSurahDetail(number: Int) async throws -> (surah: Surah, ayahs: [Ayah])
    func fetchSurahWithTranslation(number: Int, translationId: Int) async throws -> [Ayah]
    func getAudioURL(surahNumber: Int, reciterId: Int) -> String
}

final class QuranAPIDataSourceImpl: QuranAPIDataSource {
    private let httpClient: HTTPClient
    private let baseURL = "https://api.alquran.cloud/v1"
    
    init(httpClient: HTTPClient = HTTPClient()) {
        self.httpClient = httpClient
    }
    
    // MARK: - Fetch All Surahs
    
    func fetchAllSurahs() async throws -> [Surah] {
        let url = URL(string: "\(baseURL)/surah")!
        
        let response: SurahListResponse = try await httpClient.fetch(url: url)
        return response.data.map { $0.toEntity() }
    }
    
    // MARK: - Fetch Surah Detail (Arabic Only)
    
    func fetchSurahDetail(number: Int) async throws -> (surah: Surah, ayahs: [Ayah]) {
        guard number >= 1 && number <= 114 else {
            throw QuranAPIError.invalidSurahNumber
        }
        
        let url = URL(string: "\(baseURL)/surah/\(number)")!
        
        let response: SurahDetailResponse = try await httpClient.fetch(url: url)
        let dto = response.data
        
        let surah = Surah(
            number: dto.number,
            name: dto.name,
            englishName: dto.englishName,
            englishNameTranslation: dto.englishNameTranslation,
            numberOfAyahs: dto.numberOfAyahs,
            revelationType: dto.revelationType
        )
        
        let ayahs = dto.ayahs.map { $0.toEntity() }
        
        return (surah, ayahs)
    }
    
    // MARK: - Fetch Surah with Translation
    
    func fetchSurahWithTranslation(number: Int, translationId: Int) async throws -> [Ayah] {
        guard number >= 1 && number <= 114 else {
            throw QuranAPIError.invalidSurahNumber
        }
        
        // Fetch Arabic text
        let (_, arabicAyahs) = try await fetchSurahDetail(number: number)
        
        // Fetch translation
        let translationURL = URL(string: "\(baseURL)/surah/\(number)/en.sahih")!
        let translationResponse: SurahDetailResponse = try await httpClient.fetch(url: translationURL)
        
        // Combine Arabic with translation
        var combinedAyahs: [Ayah] = []
        
        for (index, arabicAyah) in arabicAyahs.enumerated() {
            if index < translationResponse.data.ayahs.count {
                let translationText = translationResponse.data.ayahs[index].text
                combinedAyahs.append(
                    Ayah(
                        number: arabicAyah.number,
                        text: arabicAyah.text,
                        numberInSurah: arabicAyah.numberInSurah,
                        translation: translationText
                    )
                )
            } else {
                combinedAyahs.append(arabicAyah)
            }
        }
        
        return combinedAyahs
    }
    
    // MARK: - Get Audio URL
    
    func getAudioURL(surahNumber: Int, reciterId: Int) -> String {
        // Default reciter format: https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3
        return "https://cdn.islamic.network/quran/audio/128/ar.alafasy/\(surahNumber).mp3"
    }
}

enum QuranAPIError: Error, LocalizedError {
    case invalidSurahNumber
    case networkError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidSurahNumber:
            return "Invalid surah number. Must be between 1 and 114."
        case .networkError:
            return "Network error occurred while fetching Quran data."
        case .decodingError:
            return "Failed to decode API response."
        }
    }
}
```

### Step 2: Create QuranAPIDataSource Tests

**Create `Tests/Data/DataSource/QuranAPIDataSourceTests.swift`:**

```swift
import XCTest
@testable import SurahFocus

final class QuranAPIDataSourceTests: XCTestCase {
    var dataSource: QuranAPIDataSource!
    
    override func setUp() {
        dataSource = QuranAPIDataSourceImpl()
    }
    
    override func tearDown() {
        dataSource = nil
    }
    
    // MARK: - Integration Tests (require network)
    
    func testFetchAllSurahs() async throws {
        let surahs = try await dataSource.fetchAllSurahs()
        
        XCTAssertEqual(surahs.count, 114)
        XCTAssertEqual(surahs[0].englishName, "Al-Fatihah")
        XCTAssertEqual(surahs[0].numberOfAyahs, 7)
    }
    
    func testFetchSurahDetail() async throws {
        let (surah, ayahs) = try await dataSource.fetchSurahDetail(number: 1)
        
        XCTAssertEqual(surah.englishName, "Al-Fatihah")
        XCTAssertEqual(ayahs.count, 7)
        XCTAssertFalse(ayahs[0].text.isEmpty)
    }
    
    func testFetchInvalidSurahThrowsError() async {
        do {
            _ = try await dataSource.fetchSurahDetail(number: 115)
            XCTFail("Should throw error for invalid surah number")
        } catch let error as QuranAPIError {
            XCTAssertEqual(error, .invalidSurahNumber)
        } catch {
            XCTFail("Wrong error type thrown")
        }
    }
    
    func testFetchSurahWithTranslation() async throws {
        let ayahs = try await dataSource.fetchSurahWithTranslation(number: 1, translationId: 131)
        
        XCTAssertEqual(ayahs.count, 7)
        XCTAssertFalse(ayahs[0].text.isEmpty) // Arabic
        XCTAssertNotNil(ayahs[0].translation) // English
    }
    
    func testGetAudioURL() {
        let url = dataSource.getAudioURL(surahNumber: 1, reciterId: 7)
        
        XCTAssertTrue(url.contains("1.mp3"))
        XCTAssertTrue(url.starts(with: "https://"))
    }
    
    func testQuranAPIErrorDescriptions() {
        XCTAssertEqual(
            QuranAPIError.invalidSurahNumber.errorDescription,
            "Invalid surah number. Must be between 1 and 114."
        )
    }
}
```

### Verification Checkpoint 2:

```bash
make test
```

**Expected Output:**
```
Test Suite 'QuranAPIDataSourceTests' passed (6 tests)
Note: Some tests require network connection
```

---

## TASK 4.3: CACHING LAYER (Day 7 Afternoon - 2 hours)

### Step 1: Create Cache Manager

**Create `Sources/Data/DataSource/Cache/QuranCacheManager.swift`:**

```swift
import Foundation

final class QuranCacheManager {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let cacheDuration: TimeInterval = 30 * 24 * 60 * 60 // 30 days
    
    init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("QuranCache")
        
        // Create cache directory if needed
        try? fileManager.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
    }
    
    // MARK: - Surah List Cache
    
    func cacheSurahList(_ surahs: [Surah]) throws {
        let data = try JSONEncoder().encode(surahs)
        let url = cacheDirectory.appendingPathComponent("surah_list.json")
        try data.write(to: url)
    }
    
    func getCachedSurahList() -> [Surah]? {
        let url = cacheDirectory.appendingPathComponent("surah_list.json")
        
        guard let data = try? Data(contentsOf: url),
              let surahs = try? JSONDecoder().decode([Surah].self, from: data),
              !isCacheExpired(for: url) else {
            return nil
        }
        
        return surahs
    }
    
    // MARK: - Surah Detail Cache
    
    func cacheSurahDetail(number: Int, ayahs: [Ayah]) throws {
        let data = try JSONEncoder().encode(ayahs)
        let url = cacheDirectory.appendingPathComponent("surah_\(number).json")
        try data.write(to: url)
    }
    
    func getCachedSurahDetail(number: Int) -> [Ayah]? {
        let url = cacheDirectory.appendingPathComponent("surah_\(number).json")
        
        guard let data = try? Data(contentsOf: url),
              let ayahs = try? JSONDecoder().decode([Ayah].self, from: data),
              !isCacheExpired(for: url) else {
            return nil
        }
        
        return ayahs
    }
    
    // MARK: - Translation Cache
    
    func cacheTranslation(surahNumber: Int, translationId: Int, ayahs: [Ayah]) throws {
        let data = try JSONEncoder().encode(ayahs)
        let url = cacheDirectory.appendingPathComponent("surah_\(surahNumber)_trans_\(translationId).json")
        try data.write(to: url)
    }
    
    func getCachedTranslation(surahNumber: Int, translationId: Int) -> [Ayah]? {
        let url = cacheDirectory.appendingPathComponent("surah_\(surahNumber)_trans_\(translationId).json")
        
        guard let data = try? Data(contentsOf: url),
              let ayahs = try? JSONDecoder().decode([Ayah].self, from: data),
              !isCacheExpired(for: url) else {
            return nil
        }
        
        return ayahs
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
    }
    
    func clearExpiredCache() {
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.creationDateKey]
        ) else { return }
        
        for file in files {
            if isCacheExpired(for: file) {
                try? fileManager.removeItem(at: file)
            }
        }
    }
    
    private func isCacheExpired(for url: URL) -> Bool {
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let creationDate = attributes[.creationDate] as? Date else {
            return true
        }
        
        let age = Date().timeIntervalSince(creationDate)
        return age > cacheDuration
    }
}
```

### Step 2: Create Cache Tests

**Create `Tests/Data/DataSource/QuranCacheManagerTests.swift`:**

```swift
import XCTest
@testable import SurahFocus

final class QuranCacheManagerTests: XCTestCase {
    var cacheManager: QuranCacheManager!
    
    override func setUp() {
        cacheManager = QuranCacheManager()
        cacheManager.clearCache()
    }
    
    override func tearDown() {
        cacheManager.clearCache()
        cacheManager = nil
    }
    
    func testCacheSurahList() throws {
        let surahs = [
            Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationType: "Meccan")
        ]
        
        try cacheManager.cacheSurahList(surahs)
        
        let cached = cacheManager.getCachedSurahList()
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.count, 1)
        XCTAssertEqual(cached?.first?.englishName, "The Opening")
    }
    
    func testCacheSurahDetail() throws {
        let ayahs = [
            Ayah(number: 1, text: "بِسْمِ اللَّهِ", numberInSurah: 1)
        ]
        
        try cacheManager.cacheSurahDetail(number: 1, ayahs: ayahs)
        
        let cached = cacheManager.getCachedSurahDetail(number: 1)
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.count, 1)
    }
    
    func testGetCachedSurahDetailReturnsNilWhenNotCached() {
        let cached = cacheManager.getCachedSurahDetail(number: 99)
        
        XCTAssertNil(cached)
    }
    
    func testClearCacheRemovesAllData() throws {
        let surahs = [
            Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationType: "Meccan")
        ]
        try cacheManager.cacheSurahList(surahs)
        
        cacheManager.clearCache()
        
        let cached = cacheManager.getCachedSurahList()
        XCTAssertNil(cached)
    }
}
```

### Verification Checkpoint 3:

```bash
make test
```

**Expected Output:**
```
Test Suite 'QuranCacheManagerTests' passed (4 tests)
```

---

## TASK 4.4: QURAN REPOSITORY (Day 7 Afternoon - 2 hours)

### Step 1: Create QuranRepository Protocol & Implementation

**Create `Sources/Data/Repositories/QuranRepository.swift`:**

```swift
import Foundation

protocol QuranRepository {
    func getAllSurahs() async throws -> [Surah]
    func getSurahDetail(number: Int) async throws -> (surah: Surah, ayahs: [Ayah])
    func getSurahWithTranslation(number: Int) async throws -> [Ayah]
    func getAudioURL(surahNumber: Int, reciterId: Int) -> String
}

final class QuranRepositoryImpl: QuranRepository {
    private let apiDataSource: QuranAPIDataSource
    private let cacheManager: QuranCacheManager
    
    init(
        apiDataSource: QuranAPIDataSource = QuranAPIDataSourceImpl(),
        cacheManager: QuranCacheManager = QuranCacheManager()
    ) {
        self.apiDataSource = apiDataSource
        self.cacheManager = cacheManager
    }
    
    func getAllSurahs() async throws -> [Surah] {
        // Check cache first
        if let cached = cacheManager.getCachedSurahList() {
            return cached
        }
        
        // Fetch from API
        let surahs = try await apiDataSource.fetchAllSurahs()
        
        // Cache the result
        try? cacheManager.cacheSurahList(surahs)
        
        return surahs
    }
    
    func getSurahDetail(number: Int) async throws -> (surah: Surah, ayahs: [Ayah]) {
        // Check cache first
        if let cachedAyahs = cacheManager.getCachedSurahDetail(number: number) {
            // Need to get surah info from list
            let surahs = try await getAllSurahs()
            if let surah = surahs.first(where: { $0.number == number }) {
                return (surah, cachedAyahs)
            }
        }
        
        // Fetch from API
        let (surah, ayahs) = try await apiDataSource.fetchSurahDetail(number: number)
        
        // Cache the result
        try? cacheManager.cacheSurahDetail(number: number, ayahs: ayahs)
        
        return (surah, ayahs)
    }
    
    func getSurahWithTranslation(number: Int) async throws -> [Ayah] {
        let translationId = 131 // Sahih International
        
        // Check cache first
        if let cached = cacheManager.getCachedTranslation(surahNumber: number, translationId: translationId) {
            return cached
        }
        
        // Fetch from API
        let ayahs = try await apiDataSource.fetchSurahWithTranslation(
            number: number,
            translationId: translationId
        )
        
        // Cache the result
        try? cacheManager.cacheTranslation(
            surahNumber: number,
            translationId: translationId,
            ayahs: ayahs
        )
        
        return ayahs
    }
    
    func getAudioURL(surahNumber: Int, reciterId: Int) -> String {
        return apiDataSource.getAudioURL(surahNumber: surahNumber, reciterId: reciterId)
    }
}
```

### Step 2: Update DIContainer

**Update `Sources/Core/DataDependency/DIContainer.swift`:**

```swift
// Update the QuranRepository initialization:
lazy var quranRepository: QuranRepository = QuranRepositoryImpl(
    apiDataSource: QuranAPIDataSourceImpl(),
    cacheManager: QuranCacheManager()
)
```

### Step 3: Create Repository Tests

**Create `Tests/Data/Repositories/QuranRepositoryTests.swift`:**

```swift
import XCTest
@testable import SurahFocus

final class QuranRepositoryTests: XCTestCase {
    var repository: QuranRepository!
    var mockAPI: MockQuranAPIDataSource!
    var cacheManager: QuranCacheManager!
    
    override func setUp() {
        mockAPI = MockQuranAPIDataSource()
        cacheManager = QuranCacheManager()
        cacheManager.clearCache()
        repository = QuranRepositoryImpl(
            apiDataSource: mockAPI,
            cacheManager: cacheManager
        )
    }
    
    override func tearDown() {
        cacheManager.clearCache()
        repository = nil
        mockAPI = nil
        cacheManager = nil
    }
    
    func testGetAllSurahsFetchesFromAPIWhenNotCached() async throws {
        let mockSurahs = [
            Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationType: "Meccan")
        ]
        mockAPI.surahsToReturn = mockSurahs
        
        let surahs = try await repository.getAllSurahs()
        
        XCTAssertEqual(surahs.count, 1)
        XCTAssertTrue(mockAPI.didFetchAllSurahs)
    }
    
    func testGetAllSurahsReturnsCachedDataWhenAvailable() async throws {
        let mockSurahs = [
            Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationType: "Meccan")
        ]
        
        // Cache data
        try cacheManager.cacheSurahList(mockSurahs)
        
        // Fetch (should come from cache)
        let surahs = try await repository.getAllSurahs()
        
        XCTAssertEqual(surahs.count, 1)
        XCTAssertFalse(mockAPI.didFetchAllSurahs) // Should not call API
    }
    
    func testGetSurahDetailFetchesFromAPIWhenNotCached() async throws {
        let mockSurahs = [
            Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationType: "Meccan")
        ]
        let mockAyahs = [
            Ayah(number: 1, text: "بِسْمِ اللَّهِ", numberInSurah: 1)
        ]
        
        mockAPI.surahsToReturn = mockSurahs
        mockAPI.ayahsToReturn = mockAyahs
        
        let (surah, ayahs) = try await repository.getSurahDetail(number: 1)
        
        XCTAssertEqual(surah.number, 1)
        XCTAssertEqual(ayahs.count, 1)
        XCTAssertTrue(mockAPI.didFetchSurahDetail)
    }
    
    func testGetAudioURL() {
        let url = repository.getAudioURL(surahNumber: 1, reciterId: 7)
        
        XCTAssertFalse(url.isEmpty)
        XCTAssertTrue(url.contains("1.mp3"))
    }
}

// MARK: - Mock API Data Source

class MockQuranAPIDataSource: QuranAPIDataSource {
    var surahsToReturn: [Surah] = []
    var ayahsToReturn: [Ayah] = []
    var didFetchAllSurahs = false
    var didFetchSurahDetail = false
    
    func fetchAllSurahs() async throws -> [Surah] {
        didFetchAllSurahs = true
        return surahsToReturn
    }
    
    func fetchSurahDetail(number: Int) async throws -> (surah: Surah, ayahs: [Ayah]) {
        didFetchSurahDetail = true
        let surah = surahsToReturn.first(where: { $0.number == number }) ??
            Surah(number: number, name: "", englishName: "", englishNameTranslation: "", numberOfAyahs: 0, revelationType: "")
        return (surah, ayahsToReturn)
    }
    
    func fetchSurahWithTranslation(number: Int, translationId: Int) async throws -> [Ayah] {
        return ayahsToReturn
    }
    
    func getAudioURL(surahNumber: Int, reciterId: Int) -> String {
        return "https://cdn.islamic.network/quran/audio/128/ar.alafasy/\(surahNumber).mp3"
    }
}
```

### Verification Checkpoint 4:

```bash
make test
```

**Expected Output:**
```
Test Suite 'QuranRepositoryTests' passed (4 tests)
```

---

## TASK 4.5: QURAN SERVICE (Day 7 Evening - 1 hour)

### Step 1: Create QuranService

**Create `Sources/Domain/Services/QuranService.swift`:**

```swift
import Foundation

protocol QuranService {
    func loadAllSurahs() async throws -> [Surah]
    func loadSurahDetail(number: Int, withTranslation: Bool) async throws -> (surah: Surah, ayahs: [Ayah])
    func getAudioURL(for surah: Surah, reciterId: Int) -> String
    func searchSurahs(query: String, in surahs: [Surah]) -> [Surah]
}

final class QuranServiceImpl: QuranService {
    private let repository: QuranRepository
    
    init(repository: QuranRepository) {
        self.repository = repository
    }
    
    func loadAllSurahs() async throws -> [Surah] {
        return try await repository.getAllSurahs()
    }
    
    func loadSurahDetail(number: Int, withTranslation: Bool) async throws -> (surah: Surah, ayahs: [Ayah]) {
        if withTranslation {
            let ayahs = try await repository.getSurahWithTranslation(number: number)
            // Get surah info
            let allSurahs = try await repository.getAllSurahs()
            guard let surah = allSurahs.first(where: { $0.number == number }) else {
                throw QuranServiceError.surahNotFound
            }
            return (surah, ayahs)
        } else {
            return try await repository.getSurahDetail(number: number)
        }
    }
    
    func getAudioURL(for surah: Surah, reciterId: Int) -> String {
        return repository.getAudioURL(surahNumber: surah.number, reciterId: reciterId)
    }
    
    func searchSurahs(query: String, in surahs: [Surah]) -> [Surah] {
        guard !query.isEmpty else { return surahs }
        
        let lowercased = query.lowercased()
        
        return surahs.filter { surah in
            surah.englishName.lowercased().contains(lowercased) ||
            surah.englishNameTranslation.lowercased().contains(lowercased) ||
            "\(surah.number)".contains(lowercased)
        }
    }
}

enum QuranServiceError: Error, LocalizedError {
    case surahNotFound
    case loadFailed
    
    var errorDescription: String? {
        switch self {
        case .surahNotFound:
            return "Surah not found"
        case .loadFailed:
            return "Failed to load Quran data"
        }
    }
}
```

### Step 2: Update DIContainer

**Update `Sources/Core/DataDependency/DIContainer.swift`:**

```swift
// Update QuranService initialization:
lazy var quranService: QuranService = QuranServiceImpl(
    quranRepository: quranRepository
)
```

### Step 3: Create Service Tests

**Create `Tests/Domain/Services/QuranServiceTests.swift`:**

```swift
import XCTest
@testable import SurahFocus

@MainActor
final class QuranServiceTests: XCTestCase {
    var service: QuranService!
    var mockRepository: MockQuranRepository!
    
    override func setUp() {
        mockRepository = MockQuranRepository()
        service = QuranServiceImpl(repository: mockRepository)
    }
    
    override func tearDown() {
        service = nil
        mockRepository = nil
    }
    
    func testLoadAllSurahs() async throws {
        let mockSurahs = [
            Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationType: "Meccan")
        ]
        mockRepository.surahsToReturn = mockSurahs
        
        let surahs = try await service.loadAllSurahs()
        
        XCTAssertEqual(surahs.count, 1)
        XCTAssertEqual(surahs.first?.englishName, "The Opening")
    }
    
    func testLoadSurahDetailWithoutTranslation() async throws {
        let mockSurah = Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationType: "Meccan")
        let mockAyahs = [
            Ayah(number: 1, text: "بِسْمِ اللَّهِ", numberInSurah: 1)
        ]
        mockRepository.surahToReturn = mockSurah
        mockRepository.ayahsToReturn = mockAyahs
        
        let (surah, ayahs) = try await service.loadSurahDetail(number: 1, withTranslation: false)
        
        XCTAssertEqual(surah.number, 1)
        XCTAssertEqual(ayahs.count, 1)
    }
    
    func testSearchSurahs() async throws {
        let surahs = [
            Surah(number: 1, name: "Al-Fatihah", englishName: "Al-Fatihah", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationType: "Meccan"),
            Surah(number: 2, name: "Al-Baqarah", englishName: "Al-Baqarah", englishNameTranslation: "The Cow", numberOfAyahs: 286, revelationType: "Medinan")
        ]
        
        let results = service.searchSurahs(query: "opening", in: surahs)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.englishName, "Al-Fatihah")
    }
    
    func testSearchSurahsWithEmptyQueryReturnsAll() async throws {
        let surahs = [
            Surah(number: 1, name: "Al-Fatihah", englishName: "Al-Fatihah", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationType: "Meccan")
        ]
        
        let results = service.searchSurahs(query: "", in: surahs)
        
        XCTAssertEqual(results.count, 1)
    }
    
    func testGetAudioURL() {
        let surah = Surah(number: 1, name: "Al-Fatihah", englishName: "The Opening", englishNameTranslation: "The Opening", numberOfAyahs: 7, revelationType: "Meccan")
        
        let url = service.getAudioURL(for: surah, reciterId: 7)
        
        XCTAssertTrue(url.contains("1.mp3"))
    }
}

// MARK: - Mock Repository

class MockQuranRepository: QuranRepository {
    var surahsToReturn: [Surah] = []
    var surahToReturn: Surah?
    var ayahsToReturn: [Ayah] = []
    
    func getAllSurahs() async throws -> [Surah] {
        return surahsToReturn
    }
    
    func getSurahDetail(number: Int) async throws -> (surah: Surah, ayahs: [Ayah]) {
        guard let surah = surahToReturn else {
            throw QuranServiceError.surahNotFound
        }
        return (surah, ayahsToReturn)
    }
    
    func getSurahWithTranslation(number: Int) async throws -> [Ayah] {
        return ayahsToReturn
    }
    
    func getAudioURL(surahNumber: Int, reciterId: Int) -> String {
        return "https://cdn.islamic.network/quran/audio/128/ar.alafasy/\(surahNumber).mp3"
    }
}
```

### Verification Checkpoint 5:

```bash
make test
```

**Expected Output:**
```
Test Suite 'QuranServiceTests' passed (5 tests)
```

---

## FINAL BUILD & TEST

### Step 1: Run All Tests

```bash
make test
```

**Expected Output:**
```
Test Suite 'QuranAPIDTOsTests' passed (4 tests)
Test Suite 'QuranAPIDataSourceTests' passed (6 tests)
Test Suite 'QuranCacheManagerTests' passed (4 tests)
Test Suite 'QuranRepositoryTests' passed (4 tests)
Test Suite 'QuranServiceTests' passed (5 tests)
[... previous tests ...]

Test Suite 'SurahFocusTests' passed (93+ tests)
```

### Step 2: Integration Test on Device

**Test real API calls:**

1. Create temporary test view:

```swift
struct QuranAPITestView: View {
    @State private var surahs: [Surah] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            } else {
                List(surahs) { surah in
                    Text("\(surah.number). \(surah.englishName)")
                }
            }
        }
        .task {
            isLoading = true
            do {
                let service = DIContainer.shared.quranService
                surahs = try await service.loadAllSurahs()
            } catch {
                print("Error: \(error)")
            }
            isLoading = false
        }
    }
}
```

2. Run on device
3. Verify 114 surahs load
4. Check console for cache messages

### Step 3: Verify Caching

```bash
# In Xcode console, should see:
# "✅ Cached 114 surahs"
# On second launch:
# "✅ Loaded 114 surahs from cache"
```

---

## PHASE 4 COMPLETION CHECKLIST

### API DTOs
- [ ] SurahDTO created
- [ ] AyahDTO created
- [ ] ReciterDTO created
- [ ] Entity mappers implemented
- [ ] 4 DTO tests passing

### API Data Source
- [ ] QuranAPIDataSource protocol defined
- [ ] QuranAPIDataSourceImpl implemented
- [ ] Fetch all surahs working
- [ ] Fetch surah detail working
- [ ] Fetch with translation working
- [ ] Audio URL generation working
- [ ] 6 API tests passing

### Caching Layer
- [ ] QuranCacheManager implemented
- [ ] Surah list caching working
- [ ] Surah detail caching working
- [ ] Translation caching working
- [ ] Cache expiration (30 days) working
- [ ] 4 cache tests passing

### Repository Layer
- [ ] QuranRepository protocol defined
- [ ] QuranRepositoryImpl with cache-first strategy
- [ ] All repository methods implemented
- [ ] 4 repository tests passing

### Service Layer
- [ ] QuranService protocol defined
- [ ] QuranServiceImpl implemented
- [ ] Search functionality working
- [ ] 5 service tests passing

### Integration
- [ ] DIContainer updated with new components
- [ ] 93+ total tests passing
- [ ] Can fetch real data from API
- [ ] Cache persists between launches
- [ ] No network errors

### Verification Commands
```bash
# All tests pass
make test

# Build succeeds
make build

# Check cache directory
# Should see .json files in Library/Caches/QuranCache/
```

---

## TROUBLESHOOTING

### Issue: Network requests failing
**Solution:**
1. Check internet connection
2. Test API endpoint in browser: https://api.alquran.cloud/v1/surah
3. Verify firewall settings
4. Check if API is down (status page)

### Issue: Cache not persisting
**Solution:**
1. Check cache directory exists
2. Verify file write permissions
3. Check cache expiration logic
4. Log cache operations

### Issue: Tests failing due to network
**Solution:**
1. Run tests with network available
2. Or use mock data sources
3. Or skip integration tests temporarily

### Issue: JSON decoding errors
**Solution:**
1. Check API response format
2. Verify DTO matches API structure
3. Log raw JSON before decoding
4. Update DTOs if API changed

---

## NEXT PHASE PREVIEW

**Phase 5 will cover:**
- MainTabView with 3 tabs
- QuranTabView with surah list
- Search functionality
- SurahDetailView with ayah list
- Streak badge display
- All Quran UI components

**Prerequisites for Phase 5:**
- Phase 4 fully complete
- Can fetch 114 surahs from API
- Caching working
- 93+ tests passing

---

## TIME TRACKING

**Estimated vs Actual:**
- Task 4.1 (DTOs): 1 hour
- Task 4.2 (API Data Source): 2 hours
- Task 4.3 (Caching): 2 hours
- Task 4.4 (Repository): 2 hours
- Task 4.5 (Service): 1 hour
- **Total: 8 hours (1 day)**

**If behind schedule:**
- Skip translation caching (fetch live each time)
- Simplify cache to in-memory only
- Skip some unit tests (add later)

---

**🎯 PHASE 4 COMPLETE! Ready for Phase 5: Main Tabs + Quran Reading UI**

Commit your work:
```bash
git add .
git commit -m "✅ Phase 4 complete: Quran API + Caching + 93 tests passing"
git push
```

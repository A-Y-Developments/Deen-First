# PHASE 4: QURAN API INTEGRATION (quranapi.pages.dev)

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

This phase integrates the Quran API from quranapi.pages.dev:
1. Update domain entities to match API response structure
2. Create API DTOs matching quranapi.pages.dev responses
3. QuranAPIDataSource implementation
4. Caching strategy (text: 30 days, audio: stream only)
5. QuranRepository with cache layer
6. QuranService business logic
7. Integration tests with real API

**By end of Phase 4, you will have:**
- ✅ Can fetch all 114 surahs
- ✅ Can fetch surah details with ayahs (Arabic + English)
- ✅ Can stream audio for 5 reciters
- ✅ Text content cached for 30 days
- ✅ 85+ unit tests passing

---

## API REFERENCE (quranapi.pages.dev)

**Base URL:** `https://quranapi.pages.dev/api/`

### Available Endpoints

1. **Get Single Verse**: `/api/{surahNo}/{ayahNo}.json`
2. **Get Complete Chapter**: `/api/{surahNo}.json`
3. **Get Audio by Reciter**: `/api/audio/{reciterId}/{surahNo}_{ayahNo}.json`
4. **Get Surah List**: `/api/surah.json`

### Response Structure (Single Verse)

```json
{
  "surahName": "Al-Fatihah",
  "surahNameArabic": "سورة الفاتحة",
  "surahNameArabicLong": "سورة الفاتحة",
  "surahNameTranslation": "The Opening",
  "revelationPlace": "Mecca",
  "totalAyah": 7,
  "surahNo": 1,
  "ayahNo": 1,
  "audio": {
    "1": {"reciter": "Mishary Rashid Al Afasy", "url": "...", "originalUrl": "..."},
    "2": {"reciter": "Abu Bakr Al Shatri", "url": "...", "originalUrl": "..."},
    "3": {"reciter": "Nasser Al Qatami", "url": "...", "originalUrl": "..."},
    "4": {"reciter": "Yasser Al Dosari", "url": "...", "originalUrl": "..."},
    "5": {"reciter": "Hani Ar Rifai", "url": "...", "originalUrl": "..."}
  },
  "english": "In the name of Allah...",
  "arabic1": "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
  "arabic2": "بسم الله الرحمن الرحيم",
  "bengali": "...",
  "urdu": "..."
}
```

### Available Reciters

1. Mishary Rashid Al Afasy
2. Abu Bakr Al Shatri
3. Nasser Al Qatami
4. Yasser Al Dosari
5. Hani Ar Rifai

---

## TASK 4.1: UPDATE DOMAIN ENTITIES (Day 7 Morning - 30 min)

### File: surahfocus/Sources/Domain/Entities/surah.swift

**Add properties:**
- `surahNameArabic: String`
- `surahNameArabicLong: String`
- `revelationPlace: String` (rename from `revelationType`)

### File: surahfocus/Sources/Domain/Entities/ayah.swift

**Add properties:**
- `arabic1: String` (Uthmani script)
- `arabic2: String` (simplified script)
- `english: String` (translation)
- `audioUrls: [ReciterAudio]`
- `surahNo: Int`
- `surahName: String`

**Create new struct:**
```swift
struct ReciterAudio: Codable, Hashable {
    let reciterId: Int
    let reciterName: String
    let url: String
    let originalUrl: String
}
```

### File: surahfocus/Sources/Domain/Entities/reciter.swift

**Update to match API:**
- `id: Int` (1-5 for the 5 reciters)
- `name: String`
- `style: String?` (can be nil)

---

## TASK 4.2: CREATE API DTOS (Day 7 Morning - 1 hour)

### File: surahfocus/Sources/Data/DataSource/API/QuranAPIDTOs.swift

**Create DTOs matching API response structure:**

1. **SingleVerseResponse** - matches `/api/{surahNo}/{ayahNo}.json`
   - All fields directly (no `data` wrapper)
   - `surahName`, `surahNameArabic`, `surahNameArabicLong`
   - `surahNameTranslation`, `revelationPlace`, `totalAyah`
   - `surahNo`, `ayahNo`
   - `audio: [String: ReciterAudioDTO]` (dictionary with "1", "2", etc.)
   - `english`, `arabic1`, `arabic2`

2. **SurahListResponse** - matches `/api/surah.json`
   - Array of surah metadata

3. **SurahChapterResponse** - array of SingleVerseResponse
   - Matches `/api/{surahNo}.json`

4. **ReciterAudioDTO** - for audio dictionary parsing

5. **Mappers** - extensions with `toEntity()` methods
   - Map API fields to entity fields
   - Handle `audio` dictionary conversion to array

---

## TASK 4.3: QURAN API DATA SOURCE (Day 7 Morning - 2 hours)

### File: surahfocus/Sources/Data/DataSource/API/QuranAPIDataSource.swift

**Protocol:**
```swift
protocol QuranAPIDataSource {
    func fetchAllSurahs() async throws -> [Surah]
    func fetchSurah(number: Int) async throws -> (Surah, [Ayah])
    func fetchVerse(surahNo: Int, ayahNo: Int) async throws -> Ayah
    func fetchAudio(reciterId: Int, surahNo: Int, ayahNo: Int) async throws -> String
    func getReciters() -> [Reciter]
}
```

**Implementation:**
- Base URL: `https://quranapi.pages.dev/api/`
- Use existing HTTPClient
- Map responses correctly (no `data` wrapper)
- Handle audio dictionary parsing
- Error handling for invalid surah/ayah numbers

**Reciters:**
- Return static array of 5 reciters
- Map IDs 1-5 to names

---

## TASK 4.4: CACHE MANAGER (Day 7 Afternoon - 1.5 hours)

### File: surahfocus/Sources/Data/DataSource/Cache/QuranCacheManager.swift

**Cache Strategy:**
- Surah list: 30 days
- Surah chapters: 30 days
- Verse data: 30 days
- Audio: NO caching (stream only)

**Cache Keys:**
- `surah_list.json`
- `surah_{number}.json`
- `verse_{surah}_{ayah}.json`

**Methods:**
- `cacheSurahList(_:)`
- `getCachedSurahList()`
- `cacheSurah(number:ayohs:)`
- `getCachedSurah(number:)`
- `cacheVerse(surahNo:ayahNo:verse:)`
- `getCachedVerse(surahNo:ayahNo:)`
- `clearCache()`
- `clearExpiredCache()`

---

## TASK 4.5: QURAN REPOSITORY (Day 7 Afternoon - 1.5 hours)

### File: surahfocus/Sources/Data/Repositories/QuranRepository.swift

**Protocol:**
```swift
protocol QuranRepository {
    func getAllSurahs() async throws -> [Surah]
    func getSurah(number: Int) async throws -> (Surah, [Ayah])
    func getVerse(surahNo: Int, ayahNo: Int) async throws -> Ayah
    func getAudioURL(reciterId: Int, surahNo: Int, ayahNo: Int) async throws -> String
    func getReciters() -> [Reciter]
}
```

**Implementation:**
- Cache-first strategy
- Fallback to API on cache miss
- Stream audio URLs directly (no cache)
- Handle errors gracefully

---

## TASK 4.6: QURAN SERVICE (Day 7 Evening - 1 hour)

### File: surahfocus/Sources/Domain/Services/QuranService.swift

**Protocol:**
```swift
protocol QuranService {
    func loadAllSurahs() async throws -> [Surah]
    func loadSurah(number: Int) async throws -> (Surah, [Ayah])
    func loadVerse(surahNo: Int, ayahNo: Int) async throws -> Ayah
    func getAudioStreamURL(reciterId: Int, surahNo: Int, ayahNo: Int) async throws -> URL
    func searchSurahs(query: String, in: [Surah]) -> [Surah]
    func getAvailableReciters() -> [Reciter]
}
```

**Business Logic:**
- Search by English name, translation, or number
- Audio stream URL construction
- Data validation
- Error mapping to user-friendly messages

---

## TASK 4.7: UPDATE DIContainer (Day 7 Evening - 30 min)

### File: surahfocus/Sources/Core/DataDependency/DIContainer.swift

**Add registrations:**
```swift
lazy var quranAPIDataSource: QuranAPIDataSource = QuranAPIDataSourceImpl()
lazy var quranCacheManager: QuranCacheManager = QuranCacheManager()
lazy var quranRepository: QuranRepository = QuranRepositoryImpl(
    apiDataSource: quranAPIDataSource,
    cacheManager: quranCacheManager
)
lazy var quranService: QuranService = QuranServiceImpl(
    repository: quranRepository
)
```

---

## TESTS TO CREATE

### Tests/Data/DataSource/QuranAPIDTOsTests.swift
- Test SingleVerseResponse decoding
- Test audio dictionary parsing
- Test entity mappers
- Test field name mappings

### Tests/Data/DataSource/QuranAPIDataSourceTests.swift
- Test fetch all surahs (integration)
- Test fetch surah with ayahs (integration)
- Test fetch single verse (integration)
- Test fetch audio URL (integration)
- Test invalid surah/ayah errors
- Test reciter list

### Tests/Data/DataSource/QuranCacheManagerTests.swift
- Test surah list caching
- Test surah chapter caching
- Test verse caching
- Test cache expiration
- Test cache clearing

### Tests/Data/Repositories/QuranRepositoryTests.swift
- Test cache-first strategy
- Test API fallback
- Test audio URL generation
- Test error handling

### Tests/Domain/Services/QuranServiceTests.swift
- Test search functionality
- Test data loading
- Test audio URL construction
- Test business logic

---

## VERIFICATION CHECKPOINTS

### Checkpoint 1 (After DTOs)
```bash
make test
# Expect: QuranAPIDTOsTests passing
```

### Checkpoint 2 (After API DataSource)
```bash
make test
# Expect: QuranAPIDTOsTests + QuranAPIDataSourceTests passing
```

### Checkpoint 3 (After Cache)
```bash
make test
# Expect: Previous + QuranCacheManagerTests passing
```

### Checkpoint 4 (After Repository)
```bash
make test
# Expect: Previous + QuranRepositoryTests passing
```

### Checkpoint 5 (After Service)
```bash
make test
# Expect: All tests passing (85+ total)
```

### Final Integration Test
- Run on device
- Fetch all 114 surahs
- Load surah detail
- Stream audio
- Verify cache persists

---

## FILES TO MODIFY

### Domain Layer
- `surahfocus/Sources/Domain/Entities/surah.swift` - add new fields
- `surahfocus/Sources/Domain/Entities/ayah.swift` - add Arabic variants, audio
- `surahfocus/Sources/Domain/Entities/reciter.swift` - update for API mapping
- `surahfocus/Sources/Domain/Services/QuranService.swift` - create

### Data Layer
- `surahfocus/Sources/Data/DataSource/API/QuranAPIDTOs.swift` - create
- `surahfocus/Sources/Data/DataSource/API/QuranAPIDataSource.swift` - create
- `surahfocus/Sources/Data/DataSource/Cache/QuranCacheManager.swift` - create
- `surahfocus/Sources/Data/Repositories/QuranRepository.swift` - create

### Core Layer
- `surahfocus/Sources/Core/DataDependency/DIContainer.swift` - update

### Tests
- `Tests/Data/DataSource/QuranAPIDTOsTests.swift` - create
- `Tests/Data/DataSource/QuranAPIDataSourceTests.swift` - create
- `Tests/Data/DataSource/QuranCacheManagerTests.swift` - create
- `Tests/Data/Repositories/QuranRepositoryTests.swift` - create
- `Tests/Domain/Services/QuranServiceTests.swift` - create

---

## CRITICAL IMPLEMENTATION NOTES

### Audio Handling
- 5 reciters available (IDs 1-5)
- Audio URLs are direct MP3 links
- Use AVPlayer for streaming
- No audio caching (stream only)

### Arabic Text
- `arabic1`: Uthmani script (standard)
- `arabic2`: Simplified script
- Store both, use `arabic1` by default

### Translation
- Map `english` field to entity
- Ignore `bengali` and `urdu` for now

### Response Structure
- No `data` wrapper (unlike alquran.cloud)
- Direct field access
- Audio is dictionary keyed by string numbers

### Error Handling
- Invalid surah number (1-114)
- Invalid ayah number
- Network errors
- JSON decoding errors

---

## PHASE 4 COMPLETION CHECKLIST

### Entity Updates
- [ ] Surah entity updated with Arabic names and revelationPlace
- [ ] Ayah entity updated with Arabic variants, audio, context
- [ ] ReciterAudio struct created
- [ ] Reciter entity updated

### API Integration
- [ ] QuranAPIDTOs created and tested
- [ ] QuranAPIDataSource implemented
- [ ] All endpoints working
- [ ] Audio streaming working

### Caching
- [ ] QuranCacheManager implemented
- [ ] 30-day expiration working
- [ ] Cache persistence verified

### Repository & Service
- [ ] QuranRepository with cache-first strategy
- [ ] QuranService with business logic
- [ ] Search functionality working

### Testing
- [ ] DTO tests passing
- [ ] API integration tests passing
- [ ] Cache tests passing
- [ ] Repository tests passing
- [ ] Service tests passing
- [ ] 85+ total tests passing

### Integration
- [ ] DIContainer updated
- [ ] Can fetch 114 surahs from real API
- [ ] Can load surah with ayahs
- [ ] Can stream audio
- [ ] Cache persists between app launches

---

## UNRESOLVED QUESTIONS

1. Should we add user preference for Arabic script type (Uthmani vs Simplified)?
2. Do we need offline mode support for previously viewed surahs?
3. Should we add reciter download quality options?
4. Do we need to handle Bismillah repetition (except Al-Fatihah and At-Tawbah)?
5. Should we add surah bookmarking/favorites in this phase?

---

## TIME ESTIMATE

- Entity updates: 30 min
- DTOs + Tests: 1 hour
- API DataSource + Tests: 2 hours
- Cache + Tests: 1.5 hours
- Repository + Tests: 1.5 hours
- Service + Tests: 1 hour
- DIContainer + Integration: 30 min
- **Total: ~8 hours**

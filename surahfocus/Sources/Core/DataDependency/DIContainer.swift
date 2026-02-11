import Foundation
import SwiftData

final class DIContainer {
    static let shared = DIContainer()

    let modelContainer: ModelContainer

    // Data Sources
    lazy var localDataSource: LocalDataSource = LocalDataSource(container: modelContainer)
    lazy var quranAPIDataSource: QuranAPIDataSource = QuranAPIDataSourceImpl(httpClient: .shared)
    lazy var quranCacheManager: QuranCacheManager = QuranCacheManager()

    // Repositories
    lazy var userRepository: UserRepository = UserRepositoryImpl(localDataSource: localDataSource)
    lazy var sessionRepository: SessionRepository = SessionRepositoryImpl(localDataSource: localDataSource)
    lazy var quranRepository: QuranRepository = QuranRepositoryImpl(
        apiDataSource: quranAPIDataSource,
        cacheManager: quranCacheManager
    )
    lazy var screenTimeRepository: ScreenTimeRepository = ScreenTimeRepositoryImpl(localDataSource: localDataSource)

    // Services - Now using real implementations
    lazy var authService: AuthService = AuthServiceImpl(userRepository: userRepository)
    lazy var subscriptionService: SubscriptionService = SubscriptionServiceImpl(userRepository: userRepository)
    lazy var quranService: QuranService = QuranServiceImpl(repository: quranRepository)
    lazy var screenTimeService: ScreenTimeService = ScreenTimeServiceImpl(screenTimeRepository: screenTimeRepository)
    lazy var sessionService: SessionService = SessionServiceImpl(
        sessionRepository: sessionRepository,
        userRepository: userRepository,
        screenTimeService: screenTimeService
    )

    @MainActor
    var mainContext: ModelContext {
        return modelContainer.mainContext
    }

    @MainActor
    var audioPlayerService: AudioPlayerService {
        return AudioPlayerServiceImpl()
    }

    @MainActor
    var ayahAudioPlayerService: AyahAudioPlayerService {
        return AyahAudioPlayerServiceImpl(audioPlayer: audioPlayerService)
    }

    @MainActor
    var audioDownloadService: AudioDownloadService {
        return AudioDownloadServiceImpl()
    }

    private init() {
        do {
            let schema = Schema([
                User.self,
                Session.self,
                BlockedApp.self
            ])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                cloudKitDatabase: .none
            )
            self.modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: SurahFocusMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            // If migration fails, try with in-memory only for development
            do {
                let schema = Schema([
                    User.self,
                    Session.self,
                    BlockedApp.self
                ])
                let config = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
                self.modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [config]
                )
                print("Using in-memory storage due to migration error: \(error)")
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }

    // For testing with in-memory container
    static func makeTestContainer() -> DIContainer {
        let schema = Schema([
            User.self,
            Session.self,
            BlockedApp.self
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        guard let container = try? ModelContainer(for: schema, configurations: [config]) else {
            fatalError("Failed to create test container")
        }

        return DIContainer(testContainer: container)
    }

    private init(testContainer: ModelContainer) {
        self.modelContainer = testContainer
    }
}


// MARK: - Migration Plan

enum SurahFocusMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SurahFocusSchemaV1.self, SurahFocusSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [
            MigrationStage.lightweight(
                fromVersion: SurahFocusSchemaV1.self,
                toVersion: SurahFocusSchemaV2.self
            )
        ]
    }
}

// MARK: - Schema V1 (Original)

enum SurahFocusSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [UserV1.self, Session.self, BlockedApp.self]
    }

    @Model
    final class UserV1 {
        @Attribute(.unique) var id: UUID
        var appleUserId: String
        var email: String?
        var name: String?
        var isPremium: Bool
        var subscriptionExpiryDate: Date?
        var currentStreak: Int
        var longestStreak: Int
        var createdAt: Date
        var lastActiveDate: Date?

        init(
            appleUserId: String,
            email: String? = nil,
            name: String? = nil
        ) {
            self.id = UUID()
            self.appleUserId = appleUserId
            self.email = email
            self.name = name
            self.isPremium = false
            self.subscriptionExpiryDate = nil
            self.currentStreak = 0
            self.longestStreak = 0
            self.createdAt = Date()
            self.lastActiveDate = nil
        }
    }
}

// MARK: - Schema V2 (With hasCompletedOnboarding)

enum SurahFocusSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [User.self, Session.self, BlockedApp.self]
    }
}

import Foundation
import SwiftData
import UserNotifications

final class DIContainer {
    static let shared = DIContainer()

    let modelContainer: ModelContainer

    // Data Sources
    lazy var localDataSource: LocalDataSource = LocalDataSource(container: modelContainer)
    lazy var quranAPIDataSource: QuranAPIDataSource = QuranAPIDataSourceImpl(httpClient: .shared)
    lazy var alQuranAPIDataSource: AlQuranAPIDataSource = AlQuranAPIDataSourceImpl(httpClient: .shared)

    // Repositories
    lazy var userRepository: UserRepository = UserRepositoryImpl(localDataSource: localDataSource)
    lazy var sessionRepository: SessionRepository = SessionRepositoryImpl(
        localDataSource: localDataSource)
    lazy var quranRepository: QuranRepository = QuranRepositoryImpl(
        apiDataSource: quranAPIDataSource,
        alQuranDataSource: alQuranAPIDataSource
    )
    lazy var screenTimeRulesRepository: ScreenTimeRulesRepository = ScreenTimeRulesRepositoryImpl()

    // Managed Settings & Device Activity
    @MainActor
    lazy var managedSettings: ManagedSettingsWrapper = ManagedSettingsWrapper()

    @MainActor
    lazy var deviceActivityManager: DeviceActivityManager = DeviceActivityManagerImpl(
        managedSettings: managedSettings)

    // Services
    lazy var authService: AuthService = AuthServiceImpl(userRepository: userRepository)
    lazy var subscriptionService: SubscriptionService = SubscriptionServiceImpl()
    lazy var quranService: QuranService = QuranServiceImpl(repository: quranRepository)

    lazy var quranPreferencesService: QuranPreferencesServiceImpl = QuranPreferencesServiceImpl()
    lazy var notificationSchedulingService: NotificationSchedulingService = NotificationSchedulingServiceImpl()

    @MainActor
    lazy var screenTimeRulesService: ScreenTimeRulesService = ScreenTimeRulesServiceImpl(
        repository: screenTimeRulesRepository,
        deviceActivityManager: deviceActivityManager,
        notificationSchedulingService: notificationSchedulingService
    )

    lazy var sessionService: SessionService = SessionServiceImpl(
        sessionRepository: sessionRepository,
        userRepository: userRepository,
        screenTimeRulesService: MainActor.assumeIsolated { screenTimeRulesService }
    )

    lazy var notificationPermissionService: NotificationPermissionService = NotificationPermissionServiceImpl()

    @MainActor
    lazy var pendingChangeService: PendingChangeService = {
        let svc = PendingChangeServiceImpl(
            localDataSource: localDataSource,
            screenTimeRulesService: screenTimeRulesService,
            screenTimeRulesRepository: screenTimeRulesRepository,
            notificationSchedulingService: notificationSchedulingService
        )
        // Break the circular dependency: inject PendingChangeService back into ScreenTimeRulesService
        // so gated operations (editAppLimitRule, deleteRule, etc.) can queue pending changes.
        (screenTimeRulesService as? ScreenTimeRulesServiceImpl)?.pendingChangeService = svc
        return svc
    }()

    @MainActor
    lazy var ayahPoolService: AyahPoolService = AyahPoolServiceImpl(localDataSource: localDataSource)

    @MainActor
    lazy var audioPlayerService: AudioPlayerService = AudioPlayerServiceImpl()

    @MainActor
    lazy var ayahAudioPlayerService: AyahAudioPlayerServiceImpl = AyahAudioPlayerServiceImpl(
        audioPlayer: audioPlayerService)

    @MainActor
    var mainContext: ModelContext {
        return modelContainer.mainContext
    }

    private init() {
        do {
            let schema = Schema([
                User.self,
                Session.self,
                PendingRuleChange.self,
                AyahPoolItem.self,
            ])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                cloudKitDatabase: .none
            )
            self.modelContainer = try ModelContainer(
                for: schema,
                configurations: [config]
            )
        } catch {
            do {
                let schema = Schema([
                    User.self,
                    Session.self,
                    PendingRuleChange.self,
                    AyahPoolItem.self,
                ])
                let config = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
                self.modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [config]
                )
                print("⚠️ Using in-memory storage due to error: \(error)")
            } catch {
                fatalError("❌ Failed to create ModelContainer: \(error)")
            }
        }
    }

    static func makeTestContainer() -> DIContainer {
        let schema = Schema([
            User.self,
            Session.self,
            PendingRuleChange.self,
            AyahPoolItem.self,
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

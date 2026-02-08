import ProjectDescription

let companyId = Environment.companyId.getString(default: "com.aydev")
let teamId = Environment.teamId.getString(default: "32T8HNVYGX")
let baseBundleId = Environment.baseBundleId.getString(default: "com.aydev.surahfocus")
let revenueCatApiKey = Environment.revenueCatApiKey.getString(
    default: "test_GigTjmiydMdJecOcMpeoxAtxtyi")

let project = Project(
    name: "SurahFocus",
    targets: [
        // Main App Target
        .target(
            name: "SurahFocus",
            destinations: .iOS,
            product: .app,
            bundleId: baseBundleId,
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleShortVersionString": "1.0.0",
                "CFBundleDisplayName": "Surah Focus",
                "CFBundleVersion": "1",
                "UISupportedInterfaceOrientations": [
                    "UIInterfaceOrientationPortrait"
                ],
                "UISupportedInterfaceOrientations~ipad": [
                    "UIInterfaceOrientationPortrait",
                    "UIInterfaceOrientationPortraitUpsideDown",
                    "UIInterfaceOrientationLandscapeLeft",
                    "UIInterfaceOrientationLandscapeRight",
                ],
                "ITSAppUsesNonExemptEncryption": false,
                "UILaunchScreen": [:],
                "NSFamilyControlsUsageDescription":
                    "Surah Focus needs permission to block distracting apps during your Quran focus sessions.",
                "UIBackgroundModes": ["audio"],
            ]),
            sources: ["surahfocus/Sources/**"],
            resources: ["surahfocus/Resources/**"],
            entitlements: "surahfocus/Sources/SurahFocus.entitlements",
            dependencies: [
                .external(name: "RevenueCat"),
                .external(name: "Alamofire")
            ],
            settings: .settings(
                configurations: [
                    .debug(
                        name: "Debug",
                        settings: [
                            "CODE_SIGN_IDENTITY": .string("Apple Development"),
                            "CODE_SIGN_STYLE": .string("Automatic"),
                            "DEVELOPMENT_TEAM": .string(teamId),
                            "IPHONEOS_DEPLOYMENT_TARGET": .string("17.0"),
                        ]
                    ),
                    .release(
                        name: "Release",
                        settings: [
                            "CODE_SIGN_IDENTITY": .string("Apple Development"),
                            "CODE_SIGN_STYLE": .string("Automatic"),
                            "DEVELOPMENT_TEAM": .string(teamId),
                            "IPHONEOS_DEPLOYMENT_TARGET": .string("17.0"),
                        ]
                    ),
                ]
            )
        ),

        // ScreenTimeMonitor Extension
        .target(
            name: "ScreenTimeMonitor",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "\(baseBundleId).ScreenTimeMonitor",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.device-activity.monitor",
                    "NSExtensionPrincipalClass": "DeviceActivityMonitorExtension",
                ]
            ]),
            sources: ["ScreenTimeMonitor/**"],
            dependencies: []
        ),

        // Shield Extension
        .target(
            name: "Shield",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "\(baseBundleId).Shield",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.shield-configuration",
                    "NSExtensionPrincipalClass": "ShieldConfigurationExtension",
                ]
            ]),
            sources: ["Shield/**"],
            dependencies: []
        ),

        // Test Target
        .target(
            name: "SurahFocusTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(baseBundleId).Tests",
            deploymentTargets: .iOS("17.0"),
            sources: ["surahfocus/Tests/**"],
            dependencies: [
                .target(name: "SurahFocus")
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "SurahFocus",
            buildAction: .buildAction(targets: ["SurahFocus"]),
            testAction: .targets(["SurahFocusTests"]),
            runAction: .runAction(
                configuration: "Debug",
                arguments: .arguments(
                    environmentVariables: [
                        "TUIST_REVENUECAT_API_KEY": .environmentVariable(value: revenueCatApiKey, isEnabled: true),
                    ]
                )
            )
        )
    ]
)

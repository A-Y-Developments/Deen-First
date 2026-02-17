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
            destinations: [.iPhone],
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
                .external(name: "Alamofire"),
                .external(name: "BottomSheet"),
                .target(name: "ScreenTimeMonitor"),
                .target(name: "Shield")
            ],
            settings: .settings(
                base: [
                    "OTHER_LDFLAGS": .string("$(inherited) -framework FamilyControls -framework DeviceActivity -framework ManagedSettings")
                ],
                configurations: [
                    .debug(
                        name: "Debug",
                        settings: [
                            "CODE_SIGN_IDENTITY": .string("Apple Development"),
                            "CODE_SIGN_STYLE": .string("Automatic"),
                            "DEVELOPMENT_TEAM": .string(teamId),
                            "IPHONEOS_DEPLOYMENT_TARGET": .string("17.0")
                        ]
                    ),
                    .release(
                        name: "Release",
                        settings: [
                            "CODE_SIGN_IDENTITY": .string("Apple Development"),
                            "CODE_SIGN_STYLE": .string("Automatic"),
                            "DEVELOPMENT_TEAM": .string(teamId),
                            "IPHONEOS_DEPLOYMENT_TARGET": .string("17.0")
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
                    "NSExtensionPointIdentifier": "com.apple.deviceactivity.monitor-extension",
                    "NSExtensionPrincipalClass": "$(PRODUCT_MODULE_NAME).DeviceActivityMonitorExtension",
                ]
            ]),
            sources: ["ScreenTimeMonitor/**"],
            entitlements: .file(path: "ScreenTimeMonitor/ScreenTimeMonitor.entitlements"),
            dependencies: [
                .sdk(name: "DeviceActivity", type: .framework),
                .sdk(name: "ManagedSettings", type: .framework),
                .sdk(name: "FamilyControls", type: .framework)
            ],
            settings: .settings(
                base: [
                    "CODE_SIGN_IDENTITY": .string("Apple Development"),
                    "CODE_SIGN_STYLE": .string("Automatic"),
                    "DEVELOPMENT_TEAM": .string(teamId),
                    "PRODUCT_MODULE_NAME": .string("ScreenTimeMonitor")
                ],
                configurations: [
                    .debug(
                        name: "Debug",
                        settings: [
                            "CODE_SIGN_IDENTITY": .string("Apple Development"),
                            "CODE_SIGN_STYLE": .string("Automatic"),
                            "DEVELOPMENT_TEAM": .string(teamId),
                            "IPHONEOS_DEPLOYMENT_TARGET": .string("17.0")
                        ]
                    ),
                    .release(
                        name: "Release",
                        settings: [
                            "CODE_SIGN_IDENTITY": .string("Apple Development"),
                            "CODE_SIGN_STYLE": .string("Automatic"),
                            "DEVELOPMENT_TEAM": .string(teamId),
                            "IPHONEOS_DEPLOYMENT_TARGET": .string("17.0")
                        ]
                    ),
                ]
            )
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
                    "NSExtensionPointIdentifier": "com.apple.ManagedSettingsUI.shield-configuration-service",
                    "NSExtensionPrincipalClass": "$(PRODUCT_MODULE_NAME).ShieldConfigurationExtension",
                ]
            ]),
            sources: ["Shield/**"],
            entitlements: .file(path: "Shield/Shield.entitlements"),
            dependencies: [
                .sdk(name: "ManagedSettings", type: .framework),
                .sdk(name: "ManagedSettingsUI", type: .framework),
                .sdk(name: "FamilyControls", type: .framework)
            ],
            settings: .settings(
                base: [
                    "CODE_SIGN_IDENTITY": .string("Apple Development"),
                    "CODE_SIGN_STYLE": .string("Automatic"),
                    "DEVELOPMENT_TEAM": .string(teamId),
                    "PRODUCT_MODULE_NAME": .string("Shield")
                ],
                configurations: [
                    .debug(
                        name: "Debug",
                        settings: [
                            "CODE_SIGN_IDENTITY": .string("Apple Development"),
                            "CODE_SIGN_STYLE": .string("Automatic"),
                            "DEVELOPMENT_TEAM": .string(teamId),
                            "IPHONEOS_DEPLOYMENT_TARGET": .string("17.0")
                        ]
                    ),
                    .release(
                        name: "Release",
                        settings: [
                            "CODE_SIGN_IDENTITY": .string("Apple Development"),
                            "CODE_SIGN_STYLE": .string("Automatic"),
                            "DEVELOPMENT_TEAM": .string(teamId),
                            "IPHONEOS_DEPLOYMENT_TARGET": .string("17.0")
                        ]
                    ),
                ]
            )
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
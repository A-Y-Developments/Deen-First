import ProjectDescription

let companyId = Environment.companyId.getString(default: "")
let teamId = Environment.teamId.getString(default: "")
let baseBundleId = Environment.baseBundleId.getString(default: "")
let revenueCatApiKeyDebug = Environment.revenuecatApiKey.getString(default: "")
let revenueCatApiKeyProd  = Environment.revenuecatProdKey.getString(default: "")

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
                "CFBundleDisplayName": "Deen First",
                "CFBundleVersion": "1",
                "UISupportedInterfaceOrientations": [
                    "UIInterfaceOrientationPortrait"
                ],
                "ITSAppUsesNonExemptEncryption": false,
                "UILaunchScreen": [:],
                "NSFamilyControlsUsageDescription":
                    "Deen First needs permission to block distracting apps during your Quran focus sessions.",
                "UIBackgroundModes": ["audio"],
                "RevenueCatAPIKey": "$(REVENUECAT_API_KEY)",
                "com.apple.developer.ubiquity-kvstore-identifier": "$(TeamIdentifierPrefix)$(CFBundleIdentifier)",
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
                            "IPHONEOS_DEPLOYMENT_TARGET": .string("17.0"),
                            "REVENUECAT_API_KEY": .string(revenueCatApiKeyDebug),
                        ]
                    ),
                    .release(
                        name: "Release",
                        settings: [
                            "CODE_SIGN_IDENTITY": .string("Apple Distribution"),
                            "CODE_SIGN_STYLE": .string("Manual"),
                            "DEVELOPMENT_TEAM": .string(teamId),
                            "IPHONEOS_DEPLOYMENT_TARGET": .string("17.0"),
                            "PROVISIONING_PROFILE_SPECIFIER": .string("SurahFocus Distribution"),
                            "REVENUECAT_API_KEY": .string(revenueCatApiKeyProd),
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
                "CFBundleDisplayName": "ScreenTimeMonitor",
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
                            "CODE_SIGN_IDENTITY": .string("Apple Distribution"),
                            "CODE_SIGN_STYLE": .string("Manual"),
                            "DEVELOPMENT_TEAM": .string(teamId),
                            "IPHONEOS_DEPLOYMENT_TARGET": .string("17.0"),
                            "PROVISIONING_PROFILE_SPECIFIER": .string("SurahFocus ScreenTimeMonitor Distribution")
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
                "CFBundleDisplayName": "Shield",
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
            ],
            settings: .settings(
                base: [
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
                            "CODE_SIGN_IDENTITY": .string("Apple Distribution"),
                            "CODE_SIGN_STYLE": .string("Manual"),
                            "DEVELOPMENT_TEAM": .string(teamId),
                            "IPHONEOS_DEPLOYMENT_TARGET": .string("17.0"),
                            "PROVISIONING_PROFILE_SPECIFIER": .string("SurahFocus Shield Distribution")
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
                configuration: "Debug"
            )
        )
    ]
)
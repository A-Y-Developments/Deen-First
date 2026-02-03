import ProjectDescription

// Get COMPANY_ID from environment variable, fallback to "app.adit" if not set
let companyId = Environment.companyId.getString()
let teamId = Environment.teamId.getString()

let project = Project(
    name: "surahfocus",
    targets: [
        .target(
            name: "surahfocus",
            destinations: .iOS,
            product: .app,
            bundleId: "\(companyId).surahfocus",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "CFBundleDisplayName": "Surah Focus",
                    "LSApplicationCategoryType": "public.app-category.entertainment",
                    "CFBundleShortVersionString": "1.0.0",
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
                    "ITSAppUsesNonExemptEncryption": false
                ]
            ),
            sources: ["surahfocus/Sources/**"],
            resources: ["surahfocus/Resources/**"],
            entitlements: "surahfocus/surahfocus.entitlements",
            dependencies: [
                .external(name: "Alamofire"),
                .external(name: "RevenueCat"),
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
                    )
                ]
            )
        ),
        .target(
            name: "surahfocusTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(companyId).surahfocusTests",
            infoPlist: .default,
            sources: ["surahfocus/Tests/**"],
            resources: [],
            dependencies: [.target(name: "surahfocus")],
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
                    )
                ]
            )
        ),
    ]
)

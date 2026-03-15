// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: [:]
    )
#endif

let package = Package(
    name: "DeenFirst",
    dependencies: [
        .package(url: "https://github.com/RevenueCat/purchases-ios.git", from: "5.57.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.10.0"),
        .package(url: "https://github.com/lucaszischka/BottomSheet.git", from: "3.1.1"),
    ]
)

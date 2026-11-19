// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "AakuQuest",
    platforms: [.macOS(.v13)],
    targets: [.executableTarget(name: "AakuQuest", path: "Sources/AakuQuest")]
)

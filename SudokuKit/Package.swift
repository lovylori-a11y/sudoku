// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "SudokuKit",
    products: [
        .library(name: "SudokuKit", targets: ["SudokuKit"]),
    ],
    targets: [
        .target(
            name: "SudokuKit"
        ),
        .testTarget(
            name: "SudokuKitTests",
            dependencies: ["SudokuKit"],
            resources: [
                .copy("Fixtures/js-fixtures.json"),
            ]
        ),
    ]
)

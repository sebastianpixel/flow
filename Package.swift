// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Flow",
    platforms: [
        .macOS(.v10_12)
    ],
    products: [
        Product.executable(name: "flow", targets: ["Flow"])
    ],
    dependencies: [
        .package(name: "CommandLineKit", url: "https://github.com/sebastianpixel/swift-commandlinekit", .branch("master")),
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.44.14"),
        .package(url: "https://github.com/orta/Komondor", from: "1.0.4"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "Flow",
            dependencies: ["Tool"]
        ),
        .target(
            name: "Tool",
            dependencies: ["Procedure"]
        ),
        .target(
            name: "Procedure",
            dependencies: ["UI", "Request", "Yams"]
        ),
        .target(
            name: "UI",
            dependencies: ["Environment"]
        ),
        .target(
            name: "Request",
            dependencies: ["Environment"]
        ),
        .target(
            name: "Environment",
            dependencies: ["Fixture"]
        ),
        .testTarget(
            name: "EnvironmentTests",
            dependencies: ["Environment"]
        ),
        .target(name: "Model"),
        .testTarget(
            name: "ModelTests",
            dependencies: ["Fixture"]
        ),
        .target(
            name: "Fixture",
            dependencies: ["Model", "Utils"]
        ),
        .target(
            name: "Utils",
            dependencies: ["CommandLineKit"]
        )
    ],
    swiftLanguageVersions: [.v5]
)

#if canImport(PackageConfig)
import PackageConfig

// When someone has run `git commit`, first run SwiftFormat.
// If there are any modifications then cancel the commit
// so changes can be reviewed.
// https://github.com/nicholascross/Injectable/blob/master/Package.swift
private let autoCorrect = #"""
git --no-pager diff --staged --name-only --diff-filter=ACM | xargs git diff | md5 > .pre_format_hash
swift run swiftformat . \
    --disable strongifiedSelf,trailingClosures,blankLinesAtStartOfScope \
    --commas inline \
    --xcodeindentation enabled \
    --ifdef no-indent \
    --swiftversion 5.3 \
    --header strip \
    --wraparguments before-first \
    --wrapcollections before-first \
    --stripunusedargs closure-only

git --no-pager diff --staged --name-only --diff-filter=ACM | xargs git diff | md5 > .post_format_hash
diff .pre_format_hash .post_format_hash > /dev/null || {
    echo "Staged files modified during commit"
    rm .pre_format_hash .post_format_hash
    exit 1
}
rm .pre_format_hash .post_format_hash
"""#

private let generateReadme = #"""
if git --no-pager diff --staged --name-only | grep --silent --extended-regexp '(main|GenerateReadme)\.swift'; then
    swift run flow generate-readme
    if git --no-pager diff --name-only | grep --silent "README.md"; then
        git add README.md
    fi
fi
"""#

let config = PackageConfiguration([
    "komondor": [
        "pre-push": [
            "swift test",
            "swift build -c release"
        ],
        "pre-commit": [
            autoCorrect,
            generateReadme
        ]
    ]
]).write()
#endif

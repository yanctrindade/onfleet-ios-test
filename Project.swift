import ProjectDescription

let project = Project(
    name: "PhoneBook",
    targets: [
        .target(
            name: "PhoneBook",
            destinations: .iOS,
            product: .app,
            bundleId: "com.onfleet.interview.PhoneBook",
            infoPlist: .extendingDefault(with: [
                // Scene Configuration
                "UIApplicationSceneManifest": [
                    "UIApplicationSupportsMultipleScenes": true,
                    "UISceneConfigurations": [
                        "UIWindowSceneSessionRoleApplication": [
                            [
                                "UISceneConfigurationName": "Default Configuration",
                                "UISceneDelegateClassName": "PhoneBook.SceneDelegate",
                                "UISceneStoryboardFile": "Main"
                            ]
                        ]
                    ]
                ],
                
                // Other common Info.plist entries
                "CFBundleShortVersionString": "1.0",
                "CFBundleVersion": "1",
                "UILaunchStoryboardName": "LaunchScreen",
                "UISupportedInterfaceOrientations": [
                    "UIInterfaceOrientationPortrait",
                ]
            ]),
            sources: ["PhoneBook/Sources/**"],
            resources: ["PhoneBook/Resources/**"],
            dependencies: [
                .external(name: "ComposableArchitecture"),
                .external(name: "Fakery")
            ]
        ),
        .target(
            name: "UnitTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.onfleet.interview.PhoneBook.UnitTests",
            infoPlist: .default,
            sources: ["PhoneBook/Tests/UnitTests/**"],
            resources: [],
            dependencies: [
                .target(name: "PhoneBook"),
                .external(name: "ComposableArchitecture")
            ]
        ),
    ]
)

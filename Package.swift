// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// This Package.swift is a Work in Progress. We intend to keep it functional
// on the master branch, but it is rapidly evolving and may have occasional
// breakages. Please report any issues at
// https://github.com/firebase/firebase-ios-sdk/issues/new/choose.

import PackageDescription

let package = Package(
  name: "Firebase",
  platforms: [.iOS(.v9), .macOS(.v10_11), .tvOS(.v10)],
  products: [
    .library(
      name: "Firebase",
      targets: ["Firebase"]
    ),
    .library(
      name: "FirebaseCore",
      targets: ["FirebaseCore"]
    ),
    .library(
      name: "FirebaseAnalytics",
      targets: ["FirebaseAnalyticsWrapper"]
    ),
    .library(
      name: "FirebaseAuth",
      targets: ["FirebaseAuth"]
    ),
    .library(
      name: "FirebaseCrashlytics",
      targets: ["FirebaseCrashlytics"]
    ),
    .library(
      name: "FirebaseDatabase",
      targets: ["FirebaseDatabase"]
    ),
    .library(
      name: "FirebaseDynamicLinks",
      targets: ["FirebaseDynamicLinks"]
    ),
    .library(
      name: "FirebaseFirestore",
      targets: ["FirebaseFirestore"]
    ),
    .library(
      name: "FirebaseFirestoreSwift",
      targets: ["FirebaseFirestoreSwift"]
    ),
    .library(
      name: "FirebaseFunctions",
      targets: ["FirebaseFunctions"]
    ),
    .library(
      name: "FirebaseInAppMessaging-Beta",
      targets: ["FirebaseInAppMessaging"]
    ),
    .library(
      name: "FirebaseInstallations",
      targets: ["FirebaseInstallations"]
    ),
    // .library(
    //   name: "FirebaseInstanceID",
    //   targets: ["FirebaseInstanceID"]
    // ),
    .library(
      name: "FirebaseRemoteConfig",
      targets: ["FirebaseRemoteConfig"]
    ),
    .library(
      name: "FirebaseStorage",
      targets: ["FirebaseStorage"]
    ),
    .library(
      name: "FirebaseStorageSwift",
      targets: ["FirebaseStorageSwift"]
    ),

    // Not intended for public consumption, but needed for FirebaseUI.
    .library(
      name: "GoogleUtilities_UserDefaults",
      targets: ["GoogleUtilities_UserDefaults"]
    ),
  ],
  dependencies: [
    .package(name: "Promises", url: "https://github.com/google/promises.git", "1.2.8" ..< "1.3.0"),
    .package(
      name: "GTMSessionFetcher",
      url: "https://github.com/google/gtm-session-fetcher.git",
      "1.4.0" ..< "2.0.0"
    ),
    .package(
      name: "nanopb",
      url: "https://github.com/nanopb/nanopb.git",
      // This revision adds SPM enablement to the 0.3.9.6 release tag.
      .revision("3cfa21200eea012d8765239ad4c50d8a36c283f1")
    ),
    .package(
      name: "abseil",
      url: "https://github.com/firebase/abseil-cpp.git",
      .revision("d30bd7751ce343a05fca6413de0dec062163e5e9")
    ),
    .package(
      name: "gRPC",
      url: "https://github.com/firebase/grpc.git",
      .revision("cae939a8823bbc39912aa2990cf95e29ace381b3")
    ),
    .package(
      name: "OCMock",
      url: "https://github.com/firebase/ocmock.git",
      .revision("7291762d3551c5c7e31c49cce40a0e391a52e889")
    ),
    .package(
      name: "leveldb",
      url: "https://github.com/firebase/leveldb.git",
      .revision("3f046978ecffd57ea6eb9a0897cc8a3b45b44df8")
    ),
    // Branches need a force update with a run with the revision set like below.
    //   .package(url: "https://github.com/paulb777/nanopb.git", .revision("564392bd87bd093c308a3aaed3997466efb95f74"))
  ],
  targets: [
    .target(
      name: "Firebase",
      path: "CoreOnly/Sources",
      publicHeadersPath: "./"
    ),
    .target(
      name: "FirebaseCore",
      dependencies: [
        "FirebaseCoreDiagnostics",
        "GoogleUtilities_Environment",
        "GoogleUtilities_Logger",
      ],
      path: "FirebaseCore/Sources",
      publicHeadersPath: "Public",
      cSettings: [
        .headerSearchPath("../.."),
        .define("FIRCore_VERSION", to: "0.0.1"), // TODO: Fix version
        .define("Firebase_VERSION", to: "0.0.1"), // TODO: Fix version
        // TODO: - Add support for cflags cSetting so that we can set the -fno-autolink option
      ]
    ),
    .testTarget(
      name: "CoreUnit",
      dependencies: ["FirebaseCore", "OCMock"],
      path: "FirebaseCore/Tests/Unit",
      exclude: ["Resources/GoogleService-Info.plist"],
      cSettings: [
        .headerSearchPath("../../.."),
      ]
    ),
    .target(
      name: "FirebaseCoreDiagnostics",
      dependencies: [
        "GoogleDataTransport",
        "GoogleUtilities_Environment",
        "GoogleUtilities_Logger",
        .product(name: "nanopb", package: "nanopb"),
      ],
      path: "Firebase/CoreDiagnostics/FIRCDLibrary",
      publicHeadersPath: ".",
      cSettings: [
        .headerSearchPath("../../.."),
        .define("PB_FIELD_32BIT", to: "1"),
        .define("PB_NO_PACKED_STRUCTS", to: "1"),
        .define("PB_ENABLE_MALLOC", to: "1"),
      ]
    ),
    .target(
      name: "FirebaseABTesting",
      dependencies: ["FirebaseCore"],
      path: "FirebaseABTesting/Sources",
      publicHeadersPath: "Public",
      cSettings: [
        .headerSearchPath("../../"),
        .define("FIRABTesting_VERSION", to: "0.0.1"), // TODO: Fix version
      ]
    ),
    .testTarget(
      name: "ABTestingUnit",
      dependencies: ["FirebaseABTesting", "OCMock"],
      path: "FirebaseABTesting/Tests/Unit",
      resources: [.process("Resources")],
      cSettings: [
        .headerSearchPath("../../.."),
      ]
    ),
    .target(
      name: "FirebaseAnalyticsWrapper",
      dependencies: [
        "FirebaseAnalytics",
        "FIRAnalyticsConnector",
        "GoogleAppMeasurement",
        "FirebaseCore",
        "FirebaseInstallations",
        "GoogleUtilities_AppDelegateSwizzler",
        "GoogleUtilities_MethodSwizzler",
        "GoogleUtilities_NSData",
        "GoogleUtilities_Network",
        .product(name: "nanopb", package: "nanopb"),
      ],
      path: "FirebaseAnalyticsWrapper",
      publicHeadersPath: "Public",
      linkerSettings: [
        .linkedLibrary("sqlite3"),
        .linkedLibrary("c++"),
        .linkedLibrary("z"),
        .linkedFramework("StoreKit"),
      ]
    ),
    .binaryTarget(
      name: "FirebaseAnalytics",
      url: "https://dl.google.com/firebase/ios/swiftpm/6.31.0/FirebaseAnalytics.zip",
      checksum: "533fae2d17c7224bf6f43485bff74e44c5f2fcdf4b56992167a6c5dbc43e5fdb"
    ),
    .binaryTarget(
      name: "FIRAnalyticsConnector",
      url: "https://dl.google.com/firebase/ios/swiftpm/6.31.0/FIRAnalyticsConnector.zip",
      checksum: "6b194824b7705ede04195364a2c0f2a70bdc6da274fb28ce7aa39853b3796e0d"
    ),
    .binaryTarget(
      name: "GoogleAppMeasurement",
      url: "https://dl.google.com/firebase/ios/swiftpm/6.31.0/GoogleAppMeasurement.zip",
      checksum: "f71ab5ca97f8763c67ab052ee083f21a0464867369e2223c0973fce38b677075"
    ),
    .target(
      name: "FirebaseAuth",
      dependencies: ["FirebaseCore",
                     "GoogleUtilities_Environment",
                     "GoogleUtilities_AppDelegateSwizzler",
                     .product(name: "GTMSessionFetcherCore", package: "GTMSessionFetcher")],
      path: "FirebaseAuth/Sources",
      publicHeadersPath: "Public",
      cSettings: [
        .headerSearchPath("../../"),
        .define("FIRAuth_VERSION", to: "0.0.1"), // TODO: Fix version
        .define("FIRAuth_MINOR_VERSION", to: "1.1"), // TODO: Fix version
      ]
    ),
    .testTarget(
      name: "AuthUnit",
      dependencies: ["FirebaseAuth", "OCMock"],
      path: "FirebaseAuth/Tests/Unit",
      exclude: [
        "FIRAuthKeychainServicesTests.m", // TODO: figure out SPM keychain testing
        "FIRAuthTests.m",
        "FIRUserTests.m",
      ],
      cSettings: [
        .headerSearchPath("../../.."),
      ]
    ),
    .target(
      name: "FirebaseCrashlytics",
      dependencies: ["FirebaseCore", "FirebaseInstallations", "GoogleDataTransport",
                     .product(name: "FBLPromises", package: "Promises"),
                     .product(name: "nanopb", package: "nanopb")],
      path: "Crashlytics",
      exclude: [
        "run",
        "CHANGELOG.md",
        "LICENSE",
        "README.md",
        "Data/",
        "Protos/",
        "ProtoSupport/",
        "UnitTests/",
        "generate_project.sh",
        "upload-symbols",
        "third_party/libunwind/LICENSE",
      ],
      sources: [
        "Crashlytics/",
        "Protogen/",
        "Shared/",
        "third_party/libunwind/dwarf.h",
      ],
      publicHeadersPath: "Crashlytics/Public",
      cSettings: [
        .headerSearchPath(".."),
        .define("DISPLAY_VERSION", to: "0.0.1"), // TODO: Fix version
        .define("CLS_SDK_NAME", to: "Crashlytics iOS SDK", .when(platforms: .some([.iOS]))),
        .define("CLS_SDK_NAME", to: "Crashlytics macOS SDK", .when(platforms: .some([.macOS]))),
        .define("CLS_SDK_NAME", to: "Crashlytics tvOS SDK", .when(platforms: .some([.tvOS]))),
        .define("PB_FIELD_32BIT", to: "1"),
        .define("PB_NO_PACKED_STRUCTS", to: "1"),
        .define("PB_ENABLE_MALLOC", to: "1"),
      ]
    ),
    .target(
      name: "FirebaseDatabase",
      dependencies: [
        "FirebaseCore",
        "leveldb",
      ],
      path: "FirebaseDatabase/Sources",
      exclude: [
        "third_party/Wrap-leveldb/LICENSE",
        "third_party/SocketRocket/LICENSE",
        "third_party/FImmutableSortedDictionary/LICENSE",
        "third_party/SocketRocket/aa2297808c225710e267afece4439c256f6efdb3",
      ],
      publicHeadersPath: "Public",
      cSettings: [
        .headerSearchPath("../../"),
        .define("FIRDatabase_VERSION", to: "0.0.1"), // TODO: Fix version
      ]
    ),
    .testTarget(
      name: "DatabaseUnit",
      dependencies: ["FirebaseDatabase", "OCMock", "SharedTestUtilities"],
      path: "FirebaseDatabase/Tests/",
      exclude: [
        "Integration/",
      ],
      resources: [.process("Resources")],
      cSettings: [
        .headerSearchPath("../.."),
      ]
    ),

    .target(
      name: "FirebaseDynamicLinks",
      dependencies: ["FirebaseCore"],
      path: "FirebaseDynamicLinks/Sources",
      publicHeadersPath: "Public",
      cSettings: [
        .headerSearchPath("../../"),
        .define("FIRDynamicLinks3P", to: "1"),
        .define("GIN_SCION_LOGGING", to: "1"),
        .define("FIRDynamicLinks_VERSION", to: "0.0.1"), // TODO: Fix version
      ]
    ),

    .target(
      name: "FirebaseFirestore",
      dependencies: [
        "FirebaseCore",
        "leveldb",
        .product(name: "nanopb", package: "nanopb"),
        .product(name: "abseil", package: "abseil"),
        .product(name: "gRPC-cpp", package: "gRPC"),
      ],
      path: "Firestore",
      exclude: [
        "CHANGELOG.md",
        "CMakeLists.txt",
        "Example/",
        "Protos/CMakeLists.txt",
        "Protos/Podfile",
        "Protos/README.md",
        "Protos/build_protos.py",
        "Protos/cpp/",
        "Protos/lib/",
        "Protos/nanopb_cpp_generator.py",
        "Protos/protos/",
        "README.md",
        "Source/CMakeLists.txt",
        "Swift/",
        "core/CMakeLists.txt",
        "core/src/util/config_detected.h.in",
        "core/test/",
        "fuzzing/",
        "test.sh",
        "third_party/",

        // Exclude alternate implementations for other platforms
        "core/src/api/input_validation_std.cc",
        "core/src/remote/connectivity_monitor_noop.cc",
        "core/src/util/filesystem_win.cc",
        "core/src/util/hard_assert_stdio.cc",
        "core/src/util/log_stdio.cc",
        "core/src/util/secure_random_openssl.cc",
      ],
      sources: [
        "Source/",
        "Protos/nanopb/",
        "core/include/",
        "core/src",
      ],
      publicHeadersPath: "Source/Public",
      cSettings: [
        .headerSearchPath("../"),
        .headerSearchPath("Source/Public/FirebaseFirestore"),
        .headerSearchPath("Protos/nanopb"),

        .define("PB_FIELD_32BIT", to: "1"),
        .define("PB_NO_PACKED_STRUCTS", to: "1"),
        .define("PB_ENABLE_MALLOC", to: "1"),
        .define("FIRFirestore_VERSION", to: "0.0.1"), // TODO: Fix version
      ]
    ),
    .target(
      name: "FirebaseFirestoreSwift",
      dependencies: ["FirebaseFirestore"],
      path: "Firestore",
      exclude: [
        "CHANGELOG.md",
        "CMakeLists.txt",
        "Example/",
        "Protos/",
        "README.md",
        "Source/",
        "core/",
        "fuzzing/",
        "test.sh",
        "Swift/CHANGELOG.md",
        "Swift/README.md",
        "Swift/Tests/",
        "third_party/FirestoreEncoder/LICENSE",
        "third_party/FirestoreEncoder/METADATA",
      ],
      sources: [
        "Swift/Source/",
        "third_party/FirestoreEncoder/",
      ]
    ),

    .target(
      name: "FirebaseFunctions",
      dependencies: [
        "FirebaseCore",
        .product(name: "GTMSessionFetcherCore", package: "GTMSessionFetcher"),
      ],
      path: "Functions/FirebaseFunctions",
      publicHeadersPath: "Public",
      cSettings: [
        .headerSearchPath("../../"),
        .define("FIRFunctions_VERSION", to: "0.0.1"), // TODO: Fix version
      ]
    ),

    .target(
      name: "FirebaseInAppMessaging",
      dependencies: [
        "FirebaseCore",
        "FirebaseInstallations",
        "FirebaseABTesting",
        "GoogleUtilities_Environment",
        .product(name: "nanopb", package: "nanopb"),
      ],
      path: "FirebaseInAppMessaging/Sources",
      exclude: [
        "DefaultUI/CHANGELOG.md",
        "DefaultUI/README.md",
      ],
      resources: [.process("Resources")],
      publicHeadersPath: "Public",
      cSettings: [
        .headerSearchPath("../../"),
        .define("FIRInAppMessaging_LIB_VERSION", to: "0.0.1"), // TODO: Fix version
        .define("PB_FIELD_32BIT", to: "1"),
        .define("PB_NO_PACKED_STRUCTS", to: "1"),
        .define("PB_ENABLE_MALLOC", to: "1"),
      ]
    ),

    // .target(
    //   name: "FirebaseInstanceID",
    //   dependencies: ["FirebaseCore", "FirebaseInstallations",
    //                  "GoogleUtilities_Environment", "GoogleUtilities_UserDefaults"],
    //   path: "Firebase/InstanceID",
    //   publicHeadersPath: "Public",
    //   cSettings: [
    //     .headerSearchPath("../../"),
    //     .define("FIRInstanceID_LIB_VERSION", to: "0.0.1"), // TODO: Fix version
    //   ]
    // ),
    .target(
      name: "FirebaseInstallations",
      dependencies: ["FirebaseCore", .product(name: "FBLPromises", package: "Promises"),
                     "GoogleUtilities_Environment", "GoogleUtilities_UserDefaults"],
      path: "FirebaseInstallations/Source/Library",
      publicHeadersPath: "Public",
      cSettings: [
        .headerSearchPath("../../../"),
      ]
    ),
    .target(
      name: "SharedTestUtilities",
      dependencies: ["FirebaseCore"],
      path: "SharedTestUtilities",
      publicHeadersPath: "./",
      cSettings: [
        .headerSearchPath("../"),
      ]
    ),
    .target(
      name: "FirebaseRemoteConfig",
      dependencies: [
        "FirebaseCore",
        "FirebaseABTesting",
        "FirebaseInstallations",
        "GoogleUtilities_NSData",
      ],
      path: "FirebaseRemoteConfig/Sources",
      publicHeadersPath: "Public",
      cSettings: [
        .headerSearchPath("../../"),
        .define("FIRRemoteConfig_VERSION", to: "0.0.1"), // TODO: Fix version
      ]
    ),
    .testTarget(
      name: "RemoteConfigUnit",
      dependencies: ["FirebaseRemoteConfig", "OCMock"],
      path: "FirebaseRemoteConfig/Tests/Unit",
      exclude: [
        // Need to be evaluated/ported to RC V2.
        "RCNConfigAnalyticsTest.m",
        "RCNConfigSettingsTest.m",
        "RCNConfigTest.m",
        "RCNRemoteConfig+FIRAppTest.m",
        "RCNThrottlingTests.m",
      ],
      resources: [
        .process("SecondApp-GoogleService-Info.plist"),
        .process("Defaults-testInfo.plist"),
        .process("TestABTPayload.txt"),
      ],
      cSettings: [
        .headerSearchPath("../../.."),
      ]
    ),
    .target(
      name: "FirebaseStorage",
      dependencies: [
        "FirebaseCore",
        .product(name: "GTMSessionFetcherCore", package: "GTMSessionFetcher"),
      ],
      path: "FirebaseStorage/Sources",
      publicHeadersPath: "Public",
      cSettings: [
        .headerSearchPath("../../"),
        .define("FIRStorage_VERSION", to: "0.0.1"), // TODO: Fix version
      ]
    ),
    .testTarget(
      name: "StorageUnit",
      dependencies: ["FirebaseStorage", "OCMock", "SharedTestUtilities"],
      path: "FirebaseStorage/Tests/Unit",
      cSettings: [
        .headerSearchPath("../../.."),
      ]
    ),
    .target(
      name: "FirebaseStorageSwift",
      dependencies: ["FirebaseStorage"],
      path: "FirebaseStorageSwift/Sources"
    ),
    .target(
      name: "GoogleDataTransport",
      dependencies: [
        .product(name: "nanopb", package: "nanopb"),
      ],
      path: "GoogleDataTransport",
      exclude: [
        "CHANGELOG.md",
        "README.md",
        "generate_project.sh",
        "GDTCCTWatchOSTestApp/",
        "GDTWatchOSTestApp/",
        "GDTCCTTestApp/",
        "GDTTestApp/",
        "GDTCCTTests/",
        "GDTCORTests/",
        "ProtoSupport/",
      ],
      sources: [
        "GDTCORLibrary",
        "GDTCCTLibrary",
      ],
      publicHeadersPath: "GDTCORLibrary/Public",
      cSettings: [
        .headerSearchPath("../"),
        .define("GDTCOR_VERSION", to: "0.0.1"),
        .define("PB_FIELD_32BIT", to: "1"),
        .define("PB_NO_PACKED_STRUCTS", to: "1"),
        .define("PB_ENABLE_MALLOC", to: "1"),
      ]
    ),
    .testTarget(
      name: "swift-test",
      dependencies: [
        "FirebaseAuth",
        "FirebaseABTesting",
        "Firebase",
        "FirebaseCrashlytics",
        "FirebaseCore",
        "FirebaseDatabase",
        "FirebaseDynamicLinks",
        "FirebaseFirestore",
        "FirebaseFirestoreSwift",
        "FirebaseFunctions",
        "FirebaseInAppMessaging",
        "FirebaseInstallations",
        // "FirebaseInstanceID",
        "FirebaseRemoteConfig",
        "FirebaseStorage",
        "FirebaseStorageSwift",
        "GoogleDataTransport",
        "GoogleUtilities_AppDelegateSwizzler",
        "GoogleUtilities_Environment",
        // "GoogleUtilities_ISASwizzler", // Build needs to disable ARC.
        "GoogleUtilities_Logger",
        "GoogleUtilities_MethodSwizzler",
        "GoogleUtilities_Network",
        "GoogleUtilities_NSData",
        "GoogleUtilities_Reachability",
        "GoogleUtilities_UserDefaults",
        .product(name: "nanopb", package: "nanopb"),
      ],
      path: "SwiftPMTests/swift-test"
    ),
    .testTarget(
      name: "objc-import-test",
      dependencies: [
        "FirebaseAuth",
        "FirebaseABTesting",
        "Firebase",
        "FirebaseCrashlytics",
        "FirebaseCore",
        "FirebaseDatabase",
        "FirebaseDynamicLinks",
        "FirebaseFirestore",
        "FirebaseFunctions",
        "FirebaseInAppMessaging",
        "FirebaseInstallations",
        "FirebaseRemoteConfig",
        "FirebaseStorage",
      ],
      path: "SwiftPMTests/objc-import-test"
    ),
    .target(
      name: "GoogleUtilities_AppDelegateSwizzler",
      dependencies: ["GoogleUtilities_Environment", "GoogleUtilities_Logger",
                     "GoogleUtilities_Network"],
      path: "GoogleUtilities",
      exclude: [
        "CHANGELOG.md",
        "CMakeLists.txt",
        "LICENSE",
        "README.md",
        "AppDelegateSwizzler/README.md",
        "Environment/",
        "Network/",
        "ISASwizzler/",
        "Logger/",
        "MethodSwizzler/",
        "NSData+zlib/",
        "Reachability",
        "SwizzlerTestHelpers/",
        "Tests",
        "UserDefaults/",
      ],
      sources: [
        "AppDelegateSwizzler/",
        "SceneDelegateSwizzler/",
        "Common/*.h",
      ],
      publicHeadersPath: "AppDelegateSwizzler/Public",
      cSettings: [
        .headerSearchPath("../"),
      ]
    ),
    .target(
      name: "GoogleUtilities_Environment",
      dependencies: [.product(name: "FBLPromises", package: "Promises")],
      path: "GoogleUtilities/Environment",
      exclude: ["third_party/LICENSE"],
      publicHeadersPath: "Private",
      cSettings: [
        .headerSearchPath("../../"),
      ]
    ),

    .target(
      name: "GoogleUtilities_Logger",
      dependencies: ["GoogleUtilities_Environment"],
      path: "GoogleUtilities/Logger",
      publicHeadersPath: "Public",
      cSettings: [
        .headerSearchPath("../../"),
      ]
    ),

    // TODO: ISA_Swizzler requires building without ARC.

    .target(
      name: "GoogleUtilities_MethodSwizzler",
      dependencies: ["GoogleUtilities_Logger"],
      path: "GoogleUtilities/MethodSwizzler",
      publicHeadersPath: "Private",
      cSettings: [
        .headerSearchPath("../../"),
      ]
    ),
    .target(
      name: "GoogleUtilities_Network",
      dependencies: ["GoogleUtilities_Logger", "GoogleUtilities_NSData",
                     "GoogleUtilities_Reachability"],
      path: "GoogleUtilities/Network",
      publicHeadersPath: "Public",
      cSettings: [
        .headerSearchPath("../.."),
      ]
    ),
    .target(
      name: "GoogleUtilities_NSData",
      path: "GoogleUtilities/NSData+zlib",
      publicHeadersPath: "Public",
      cSettings: [
        .headerSearchPath("../.."),
      ],
      linkerSettings: [
        .linkedLibrary("z"),
      ]
    ),
    .target(
      name: "GoogleUtilities_Reachability",
      dependencies: ["GoogleUtilities_Logger"],
      path: "GoogleUtilities/Reachability",
      publicHeadersPath: "Private",
      cSettings: [
        .headerSearchPath("../../"),
      ]
    ),
    .target(
      name: "GoogleUtilities_UserDefaults",
      dependencies: ["GoogleUtilities_Logger"],
      path: "GoogleUtilities/UserDefaults",
      publicHeadersPath: "Private",
      cSettings: [
        .headerSearchPath("../../"),
      ]
    ),
    // TODO: - need to port Network/third_party/GTMHTTPServer.m to ARC.
    // .testTarget(
    //   name: "UtilitiesUnit",
    //   dependencies: [
    //     "OCMock",
    //     "GoogleUtilities_AppDelegateSwizzler",
    //     "GoogleUtilities_Environment",
    //     // "GoogleUtilities_ISASwizzler", // Build needs to disable ARC.
    //     "GoogleUtilities_Logger",
    //     "GoogleUtilities_MethodSwizzler",
    //     "GoogleUtilities_Network",
    //     "GoogleUtilities_NSData",
    //     "GoogleUtilities_Reachability",
    //     "GoogleUtilities_UserDefaults",
    //   ],
    //   path: "GoogleUtilities/Tests/Unit",
    //   exclude: [
    //     "Network/third_party/LICENSE",
    //     "Network/third_party/GTMHTTPServer.m", // Requires disabling ARC
    //   ],
    //   cSettings: [
    //     .headerSearchPath("../../.."),
    //   ]
    // ),
  ],
  cLanguageStandard: .c99,
  cxxLanguageStandard: CXXLanguageStandard.gnucxx14
)

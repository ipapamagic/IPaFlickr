// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IPaFlickr",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "IPaFlickr",
            targets: ["IPaFlickr"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url:"https://github.com/ipapamagic/IPaLog.git",from: "3.1.0"),
        .package(url:"https://github.com/ipapamagic/IPaSecurity.git",from: "4.1.0"),
        .package(url:"https://github.com/ipapamagic/IPaKeyChain.git",from: "2.4.0"),
        .package(url:"https://github.com/ipapamagic/IPaURLResourceUI.git",from: "5.4.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "IPaFlickr",
            dependencies: [.product(name: "IPaSecurity", package: "IPaSecurity"),.product(name: "IPaLog", package: "IPaLog"),.product(name: "IPaKeyChain", package: "IPaKeyChain")]),
        .testTarget(
            name: "IPaFlickrTests",
            dependencies: ["IPaFlickr"]),
    ]
)

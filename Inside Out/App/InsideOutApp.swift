import SwiftUI
import SwiftData

@main
struct InsideOutApp: App {
    var body: some Scene {
        WindowGroup {
            AppContainerView()
        }
        .modelContainer(AppModelContainer.shared)
    }
}

@MainActor
enum AppModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema(versionedSchema: InsideOutSchemaV1.self)
        let storeURL = URL.applicationSupportDirectory
            .appending(path: "InsideOut.store", directoryHint: .notDirectory)

        do {
            return try makeContainer(schema: schema, storeURL: storeURL)
        } catch {
            fatalError("Unable to create app SwiftData container with migration support: \(error)")
        }
    }()

    private static func makeContainer(schema: Schema, storeURL: URL) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        return try ModelContainer(
            for: schema,
            migrationPlan: InsideOutMigrationPlan.self,
            configurations: [configuration]
        )
    }
}

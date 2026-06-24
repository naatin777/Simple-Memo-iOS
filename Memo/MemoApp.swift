import SwiftUI
import SwiftData

@main
struct MemoApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema: Schema = Schema([
            Item.self,
            ChatMessage.self
        ])
        let isUITesting = CommandLine.arguments.contains("-ui-testing")

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isUITesting
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

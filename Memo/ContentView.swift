import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        MemoListViewControllerRepresentable(modelContext: modelContext)
                  .ignoresSafeArea()
    }
}

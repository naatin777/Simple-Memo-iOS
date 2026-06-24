import SwiftUI
import SwiftData

struct MemoListViewControllerRepresentable: UIViewControllerRepresentable {
    let modelContext: ModelContext
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let viewModel = MemoListViewModel(modelContext: modelContext)
        let memoListViewController = MemoListViewController(viewModel: viewModel)
        
        return UINavigationController(rootViewController: memoListViewController)
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        
    }
}

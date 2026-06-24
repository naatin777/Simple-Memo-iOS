import UIKit
import SwiftData

@MainActor
final class MemoListDataSource: UITableViewDiffableDataSource<MemoListSection, Item.ID> {
    var canMoveItem: ((Item.ID) -> Bool)?
    var moveItem: ((IndexPath, IndexPath) -> Void)?
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        guard let itemID = itemIdentifier(for: indexPath) else {
            return false
        }
        
        return canMoveItem?(itemID) ?? false
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        moveItem?(sourceIndexPath, destinationIndexPath)
    }
}

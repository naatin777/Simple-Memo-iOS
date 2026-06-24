import UIKit
import SwiftData
import Combine

nonisolated enum ChatSection: Hashable, Sendable {
    case main
}

@MainActor
final class ChatViewController: UIViewController {
    private typealias DataSource = UITableViewDiffableDataSource<ChatSection, ChatMessage.ID>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<ChatSection, ChatMessage.ID>
    
    private let item: Item
    
    private let viewModel: ChatViewModel
    
    private let tableView = UITableView()
    private var dataSource: DataSource?
    private var cancellables: Set<AnyCancellable> = []
    
    private let inputContainerView = UIView()
    private let inputTextView = UITextView()
    private let placeholderLabel = UILabel()
    private let sendButton = UIButton(type: .system)
    
    private var inputTextViewHeightConstraint: NSLayoutConstraint?
    private var inputContainerBottomConstraint: NSLayoutConstraint?
    
    init(item: Item, modelContext: ModelContext) {
        self.item = item
        self.viewModel = ChatViewModel(modelContext: modelContext, item: item)
        super.init(nibName: nil, bundle: nil)
        title = item.title
    }
    
    init(item: Item, viewModel: ChatViewModel) {
        self.item = item
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        title = item.title
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        setupInputArea()
        setupTableView()
        setupNavigationBar()
        configureDataSource()
        observeViewModel()
        observeKeyboard()
        updateUI(animated: false)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension ChatViewController {
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "pencil"),
            primaryAction: UIAction { [weak self] _ in
                self?.presentEditTitleAlert()
            }
        )
    }
    
    func makeEditTitleAlert() -> UIAlertController {
        let alert = UIAlertController(
            title: String(localized: .editTitle),
            message: nil,
            preferredStyle: .alert
        )

        alert.addTextField { [weak self] textField in
            textField.text = self?.title
            textField.placeholder = String(localized: .title)
        }

        let cancelAction = UIAlertAction(title: String(localized: .cancel), style: .cancel)
        let saveAction = UIAlertAction(title: String(localized: .save), style: .default) { [weak self, weak alert] _ in
            guard
                let self,
                let newTitle = alert?.textFields?.first?.text
            else { return }

            viewModel.updateTitle(newTitle)
            title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        return alert
    }
    
    func presentEditTitleAlert() {
        present(makeEditTitleAlert(), animated: true)
    }
    
    func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.keyboardDismissMode = .interactive
        tableView.verticalScrollIndicatorInsets = tableView.contentInset

        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(didTapTableView)
        )
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
        
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor)
        ])
    }

    @objc
    func didTapTableView() {
        view.endEditing(true)
    }
    
    func configureDataSource() {
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.reuseIdentifier)

        dataSource = DataSource(tableView: tableView) { [weak self] tableView, indexPath, messageID in
            guard
                let self: ChatViewController,
                let message: ChatMessage = self.viewModel.message(for: messageID),
                let cell: ChatMessageCell = tableView.dequeueReusableCell(withIdentifier: ChatMessageCell.reuseIdentifier, for: indexPath) as? ChatMessageCell
            else {
                return UITableViewCell()
            }
            
            cell.configure(message: message, isOutgoing: true)
            return cell
        }
    }

    func observeViewModel() {
        viewModel.$messages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateUI(animated: true)
            }
            .store(in: &cancellables)
    }

    func updateUI(animated: Bool = true) {
        var snapshot: ChatViewController.Snapshot = Snapshot()
        snapshot.appendSections([.main])

        let messageIDs: [UUID] = viewModel.messages.map(\.id)
        snapshot.appendItems(messageIDs, toSection: .main)

        dataSource?.apply(snapshot, animatingDifferences: animated) { [weak self] in
            self?.scrollToBottom()
        }
    }
    
    func scrollToBottom() {
        guard !viewModel.messages.isEmpty else {
            return
        }

        let lastRow: Int = viewModel.messages.count - 1
        let indexPath: IndexPath = IndexPath(row: lastRow, section: 0)

        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
}

private extension ChatViewController {
    func observeKeyboard() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }
    
    @objc
    func keyboardWillChangeFrame(_ notification: Notification) {
        guard
            let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let curveRawValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else {
            return
        }

        let keyboardFrameInView = view.convert(keyboardFrame, from: nil)
        let keyboardOverlap = view.bounds.maxY - keyboardFrameInView.minY

        let bottomPadding: CGFloat = 0

        if keyboardOverlap > 0 {
            inputContainerBottomConstraint?.constant =
                -keyboardOverlap + view.safeAreaInsets.bottom - bottomPadding
        } else {
            inputContainerBottomConstraint?.constant = -bottomPadding
        }

        let options = UIView.AnimationOptions(rawValue: curveRawValue << 16)

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: options
        ) {
            self.view.layoutIfNeeded()
        }
    }
}

private extension ChatViewController {
    func setupInputArea() {
        inputContainerView.translatesAutoresizingMaskIntoConstraints = false
        inputTextView.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        
        inputTextView.accessibilityIdentifier = "chat.inputTextView"
        placeholderLabel.accessibilityIdentifier = "chat.placeholderLabel"
        sendButton.accessibilityIdentifier = "chat.sendButton"

        inputContainerView.backgroundColor = .systemBackground

        inputTextView.delegate = self
        inputTextView.backgroundColor = .secondarySystemBackground
        inputTextView.layer.cornerRadius = 18
        inputTextView.clipsToBounds = true
        inputTextView.font = .systemFont(ofSize: 17)
        inputTextView.textContainerInset = UIEdgeInsets(
            top: 8,
            left: 10,
            bottom: 8,
            right: 10
        )
        inputTextView.textContainer.lineFragmentPadding = 0
        inputTextView.isScrollEnabled = false

        placeholderLabel.text = String(localized: .message)
        placeholderLabel.textColor = .placeholderText
        placeholderLabel.font = .systemFont(ofSize: 17)

        sendButton.setTitle(String(localized: .send), for: .normal)
        sendButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        sendButton.addAction(
            UIAction { [weak self] _ in
                self?.sendButtonTapped()
            },
            for: .touchUpInside
        )

        view.addSubview(inputContainerView)
        inputContainerView.addSubview(inputTextView)
        inputTextView.addSubview(placeholderLabel)
        inputContainerView.addSubview(sendButton)

        let bottomConstraint = inputContainerView.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -8
        )
        inputContainerBottomConstraint = bottomConstraint

        let heightConstraint = inputTextView.heightAnchor.constraint(
            equalToConstant: 40
        )
        inputTextViewHeightConstraint = heightConstraint

        NSLayoutConstraint.activate([
            inputContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomConstraint,

            inputTextView.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 8),
            inputTextView.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor, constant: 16),
            inputTextView.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -8),
            heightConstraint,

            placeholderLabel.leadingAnchor.constraint(equalTo: inputTextView.leadingAnchor, constant: 10),
            placeholderLabel.topAnchor.constraint(equalTo: inputTextView.topAnchor, constant: 8),

            sendButton.leadingAnchor.constraint(equalTo: inputTextView.trailingAnchor, constant: 10),
            sendButton.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor, constant: -16),
            sendButton.bottomAnchor.constraint(equalTo: inputTextView.bottomAnchor, constant: -4),
            sendButton.widthAnchor.constraint(equalToConstant: 52)
        ])
    }
    
    func updateInputTextViewHeight() {
        let fittingSize = CGSize(
            width: inputTextView.bounds.width,
            height: CGFloat.greatestFiniteMagnitude
        )

        let calculatedSize = inputTextView.sizeThatFits(fittingSize)

        let minHeight: CGFloat = 40
        let maxHeight: CGFloat = 120

        let newHeight = min(
            max(calculatedSize.height, minHeight),
            maxHeight
        )

        inputTextViewHeightConstraint?.constant = newHeight
        inputTextView.isScrollEnabled = calculatedSize.height > maxHeight

        UIView.animate(withDuration: 0.15) {
            self.view.layoutIfNeeded()
        }
    }
    
    func sendButtonTapped() {
        viewModel.sendText(inputTextView.text ?? "", Date())
        inputTextView.text = ""
        placeholderLabel.isHidden = false
        updateInputTextViewHeight()
    }
}

extension ChatViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        updateInputTextViewHeight()
    }
}

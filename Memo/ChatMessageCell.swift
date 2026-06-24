import UIKit

final class ChatMessageCell: UITableViewCell {
    static let reuseIdentifier = "ChatMessageCell"

    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    private let stackView = UIStackView()

    private var stackLeadingConstraint: NSLayoutConstraint!
    private var stackTrailingConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(message: ChatMessage, isOutgoing: Bool) {
        messageLabel.text = message.text
        timeLabel.text = message.createdAt.formatted(
            date: .omitted,
            time: .shortened
        )

        if isOutgoing {
            stackLeadingConstraint.isActive = false
            stackTrailingConstraint.isActive = true

            bubbleView.backgroundColor = .systemBlue
            messageLabel.textColor = .white
            timeLabel.textAlignment = .right
        } else {
            stackTrailingConstraint.isActive = false
            stackLeadingConstraint.isActive = true

            bubbleView.backgroundColor = .secondarySystemBackground
            messageLabel.textColor = .label
            timeLabel.textAlignment = .left
        }
    }
}

private extension ChatMessageCell {
    func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        bubbleView.layer.cornerRadius = 18
        bubbleView.clipsToBounds = true

        messageLabel.numberOfLines = 0
        messageLabel.font = .systemFont(ofSize: 17)

        timeLabel.font = .systemFont(ofSize: 12)
        timeLabel.textColor = .secondaryLabel

        stackView.axis = .vertical
        stackView.spacing = 4

        contentView.addSubview(stackView)
        stackView.addArrangedSubview(bubbleView)
        stackView.addArrangedSubview(timeLabel)
        bubbleView.addSubview(messageLabel)

        stackLeadingConstraint = stackView.leadingAnchor.constraint(
            equalTo: contentView.leadingAnchor,
            constant: 16
        )

        stackTrailingConstraint = stackView.trailingAnchor.constraint(
            equalTo: contentView.trailingAnchor,
            constant: -16
        )
        
        let maxWidthConstraint = stackView.widthAnchor.constraint(
            lessThanOrEqualTo: contentView.widthAnchor,
            multiplier: 0.75
        )
        maxWidthConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            maxWidthConstraint,

            bubbleView.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),

            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10)
        ])

        stackTrailingConstraint.isActive = true
    }
}

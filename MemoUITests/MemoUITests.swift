import XCTest

enum UITestL10n {
    static func string(_ key: String) -> String {
        let preferredLanguages = Locale.preferredLanguages
        let locale = Locale(identifier: preferredLanguages.first ?? "ja")

        switch (key, locale.language.languageCode?.identifier) {
        case ("add", "ja"):
            return "追加"
        case ("cancel", "ja"):
            return "キャンセル"
        case ("save", "ja"):
            return "保存"
        default:
            return key
        }
    }

    static let add = string("add")
    static let cancel = string("cancel")
    static let save = string("save")
}

final class MemoUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
    }

    func testCreateMemoOpenChatAndSendMessage() throws {
        let addButton = app.buttons["memoList.addButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 2))
        addButton.tap()

        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 2))

        let textField = alert.textFields.firstMatch
        XCTAssertTrue(textField.exists)
        textField.tap()
        textField.typeText("E2E Memo")

        alert.buttons[UITestL10n.add].tap()

        let memoCell = app.tables.cells.staticTexts["E2E Memo"]
        XCTAssertTrue(memoCell.waitForExistence(timeout: 2))
        memoCell.tap()

        let inputTextView = app.textViews["chat.inputTextView"]
        XCTAssertTrue(inputTextView.waitForExistence(timeout: 2))
        inputTextView.tap()
        inputTextView.typeText("Hello from E2E")

        app.buttons["chat.sendButton"].tap()

        let message = app.staticTexts["Hello from E2E"]
        XCTAssertTrue(message.waitForExistence(timeout: 2))

        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertTrue(memoCell.waitForExistence(timeout: 2))
    }
}

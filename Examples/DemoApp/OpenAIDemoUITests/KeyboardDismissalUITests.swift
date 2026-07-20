import XCTest

final class KeyboardDismissalUITests: XCTestCase {
  @MainActor
  func testKeyboardCanBeDismissedFromCredentialChatAndLabInputs() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launch()

    verifyCredentialInput(in: app)
    verifyChatComposer(in: app)
    verifyLabPrompt(named: "Function tools", in: app)
    verifyLabPrompt(named: "Guided generation", in: app)
    verifyLabPrompt(named: "Dynamic profiles", in: app)
  }

  @MainActor
  private func verifyCredentialInput(in app: XCUIApplication) {
    app.tabBars.buttons["Settings"].tap()

    let apiKeyField = app.secureTextFields["sk-proj-…"]
    XCTAssertTrue(apiKeyField.waitForExistence(timeout: 3))
    apiKeyField.tap()
    apiKeyField.typeText("sk-test-keyboard-dismissal")
    XCTAssertFalse(app.buttons["Hide keyboard"].exists)
    dismissKeyboardWithReturnKey(in: app)
  }

  @MainActor
  private func verifyChatComposer(in app: XCUIApplication) {
    app.tabBars.buttons["Chat"].tap()
    app.buttons["New conversation"].tap()

    let thread = app.staticTexts["New conversation"].firstMatch
    XCTAssertTrue(thread.waitForExistence(timeout: 3))
    thread.tap()

    let composer = app.textFields["Message OpenAI"]
    XCTAssertTrue(composer.waitForExistence(timeout: 3))
    composer.tap()
    XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: 3))
    XCTAssertFalse(app.buttons["Hide keyboard"].exists)

    app.buttons["Choose model"].tap()
    XCTAssertTrue(app.navigationBars["Conversation Model"].waitForExistence(timeout: 3))
    XCTAssertTrue(app.keyboards.element.waitForNonExistence(timeout: 3))
    app.buttons["Cancel"].tap()

    XCTAssertFalse(app.tabBars.element.exists)
    app.navigationBars.buttons.element(boundBy: 0).tap()
  }

  @MainActor
  private func verifyLabPrompt(
    named labName: String,
    in app: XCUIApplication
  ) {
    app.tabBars.buttons["Labs"].tap()
    app.buttons[labName].tap()

    let prompt = app.textFields.firstMatch
    XCTAssertTrue(prompt.waitForExistence(timeout: 3))
    prompt.tap()
    XCTAssertFalse(app.buttons["Hide keyboard"].exists)
    dismissKeyboardInteractively(in: app)

    XCTAssertFalse(app.tabBars.element.exists)
    app.navigationBars.buttons.element(boundBy: 0).tap()
  }

  @MainActor
  private func dismissKeyboardWithReturnKey(in app: XCUIApplication) {
    XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: 3))

    let doneKey = app.keyboards.buttons["Done"]
    if doneKey.exists {
      doneKey.tap()
    } else {
      let returnKey = app.keyboards.buttons["return"]
      XCTAssertTrue(returnKey.waitForExistence(timeout: 3))
      returnKey.tap()
    }

    XCTAssertTrue(app.keyboards.element.waitForNonExistence(timeout: 3))
  }

  @MainActor
  private func dismissKeyboardInteractively(in app: XCUIApplication) {
    XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: 3))

    let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
    let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
    start.press(forDuration: 0.1, thenDragTo: end)

    XCTAssertTrue(app.keyboards.element.waitForNonExistence(timeout: 3))
  }
}

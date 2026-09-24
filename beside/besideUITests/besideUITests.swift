import XCTest

final class besideUITests: XCTestCase {

    private let tabs: [(title: String, tab: String, screen: String)] = [
        ("Me", "tab.me", "screen.me"),
        ("Partner", "tab.partner", "screen.partner"),
        ("Us", "tab.us", "screen.us"),
        ("Connection", "tab.connection", "screen.connection"),
        ("More", "tab.more", "screen.more"),
    ]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testTabShellSwitchesPlaceholders() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = screen(app, "tab.bar")
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        for tab in tabs {
            let button = screen(app, tab.tab)
            XCTAssertTrue(button.waitForExistence(timeout: 2), "Missing tab button for \(tab.title)")
            XCTAssertEqual(button.label, tab.title)
        }

        let me = screen(app, "screen.me")
        XCTAssertTrue(me.waitForExistence(timeout: 3))
        assertOnlyScreen(app, "screen.me")

        for tab in [tabs[1], tabs[2], tabs[3], tabs[4], tabs[0]] {
            screen(app, tab.tab).tap()
            XCTAssertTrue(
                screen(app, tab.screen).waitForExistence(timeout: 5),
                "Expected \(tab.screen) after tapping \(tab.title)"
            )
            assertOnlyScreen(app, tab.screen)
        }
    }

    @MainActor
    func testMeMoodShareUpdatesCurrentPanel() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(screen(app, "screen.me").waitForExistence(timeout: 5))
        XCTAssertTrue(screen(app, "week.mood.strip").waitForExistence(timeout: 2))
        XCTAssertTrue(screen(app, "current.mood.panel").exists)

        let calm = app.descendants(matching: .any)["mood.calm"]
        XCTAssertTrue(calm.waitForExistence(timeout: 2))
        calm.tap()

        let wish = app.descendants(matching: .any)["wish.calm.0"]
        XCTAssertTrue(wish.waitForExistence(timeout: 2))
        wish.tap()

        let share = app.descendants(matching: .any)["share.button"]
        XCTAssertTrue(share.waitForExistence(timeout: 2))
        share.tap()

        let sent = app.descendants(matching: .any)["share.sent"]
        XCTAssertTrue(sent.waitForExistence(timeout: 5))

        let panel = screen(app, "current.mood.panel")
        XCTAssertTrue(panel.waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.staticTexts["Calm & Balanced"].waitForExistence(timeout: 5)
                || panel.staticTexts["Calm & Balanced"].exists
        )
        XCTAssertTrue(
            app.staticTexts["Let's just sit together in silence."].waitForExistence(timeout: 2)
                || panel.staticTexts["Let's just sit together in silence."].exists
        )
        XCTAssertTrue(screen(app, "week.mood.strip").exists)
    }

    @MainActor
    func testPartnerShowsFigmaBlocks() throws {
        let app = XCUIApplication()
        app.launch()

        screen(app, "tab.partner").tap()
        XCTAssertTrue(screen(app, "screen.partner").waitForExistence(timeout: 5))
        XCTAssertTrue(screen(app, "partner.current.mood").waitForExistence(timeout: 3))
        XCTAssertTrue(screen(app, "partner.care.suggestions").exists)
        XCTAssertTrue(screen(app, "partner.week.strip").exists)
        XCTAssertTrue(screen(app, "partner.reaction.open").exists)
        XCTAssertTrue(
            app.staticTexts["Your partner's mood"].waitForExistence(timeout: 2)
                || screen(app, "screen.partner").staticTexts["Your partner's mood"].exists
        )
        XCTAssertTrue(
            app.staticTexts["Small ways to show you care"].exists
                || screen(app, "partner.care.suggestions").exists
        )
    }

    @MainActor
    func testUsShowsHomeShell() throws {
        let app = XCUIApplication()
        app.launch()

        screen(app, "tab.us").tap()
        XCTAssertTrue(screen(app, "screen.us").waitForExistence(timeout: 5))
        XCTAssertTrue(screen(app, "us.hero").waitForExistence(timeout: 3))
        XCTAssertTrue(screen(app, "us.daily.progress").exists)
        XCTAssertTrue(screen(app, "us.level").exists)
        XCTAssertTrue(screen(app, "us.entry.tiles").exists)
        XCTAssertTrue(screen(app, "us.memories").exists)
        XCTAssertTrue(
            app.staticTexts["Anna & Alex"].waitForExistence(timeout: 2)
                || screen(app, "us.couple.names").exists
        )
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'together for'")).firstMatch.exists
                || screen(app, "us.time.together").exists
        )
        // Feature flows are stubs in us-shell — tiles present, no crash on tap.
        screen(app, "us.tile.dates").tap()
        XCTAssertTrue(screen(app, "us.hero").exists)
    }

        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    private func screen(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func assertOnlyScreen(_ app: XCUIApplication, _ visible: String) {
        for tab in tabs {
            if tab.screen == visible {
                XCTAssertTrue(screen(app, tab.screen).exists)
            } else {
                XCTAssertFalse(screen(app, tab.screen).exists)
            }
        }
    }
}

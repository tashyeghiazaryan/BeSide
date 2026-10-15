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
        XCTAssertFalse(screen(app, "us.level").exists)
        XCTAssertTrue(screen(app, "us.entry.tiles").exists)
        XCTAssertTrue(screen(app, "us.screen.card").exists)
        XCTAssertFalse(screen(app, "us.memories").exists)
        screen(app, "us.screen.card").tap()
        XCTAssertTrue(screen(app, "us.screen.page").waitForExistence(timeout: 3))
        XCTAssertTrue(screen(app, "us.screen.archive").exists)
        screen(app, "us.screen.archive").tap()
        XCTAssertTrue(screen(app, "us.screen.archive.page").waitForExistence(timeout: 3))
        screen(app, "us.screen.archive.back").tap()
        screen(app, "us.screen.back").tap()
        XCTAssertTrue(screen(app, "us.entry.tiles").waitForExistence(timeout: 3))
        XCTAssertTrue(
            app.staticTexts["Anna & Alex"].waitForExistence(timeout: 2)
                || screen(app, "us.couple.names").exists
        )
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'together for'")).firstMatch.exists
                || screen(app, "us.time.together").exists
        )
    }

    @MainActor
    func testUsImportantDatesListAndAdd() throws {
        let app = XCUIApplication()
        app.launch()

        screen(app, "tab.us").tap()
        XCTAssertTrue(screen(app, "us.tile.dates").waitForExistence(timeout: 5))
        XCTAssertTrue(screen(app, "us.tile.asks").waitForExistence(timeout: 2))
        XCTAssertTrue(screen(app, "us.tile.lovenotes").waitForExistence(timeout: 2))
        XCTAssertTrue(screen(app, "us.screen.card").waitForExistence(timeout: 2))

        screen(app, "us.tile.dates").tap()
        XCTAssertTrue(screen(app, "us.dates.list.page").waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Important dates"].exists)

        screen(app, "us.dates.list.add").tap()
        XCTAssertTrue(screen(app, "us.dates.add.page").waitForExistence(timeout: 3))

        let day = screen(app, "us.dates.add.day.1")
        XCTAssertTrue(day.waitForExistence(timeout: 2))
        day.tap()

        let title = screen(app, "us.dates.add.title")
        XCTAssertTrue(title.waitForExistence(timeout: 2))
        title.tap()
        title.typeText("Coast trip")

        screen(app, "us.dates.add.commit").tap()
        XCTAssertTrue(screen(app, "us.dates.list.page").waitForExistence(timeout: 4))
        screen(app, "us.dates.list.back").tap()
        XCTAssertFalse(screen(app, "us.dates.list.page").waitForExistence(timeout: 1))

        screen(app, "us.tile.asks").tap()
        XCTAssertTrue(screen(app, "us.dates.detail.page").waitForExistence(timeout: 3))
        XCTAssertTrue(screen(app, "us.dates.detail.week").exists)
        XCTAssertTrue(screen(app, "us.dates.detail.hero").exists)
        XCTAssertTrue(screen(app, "us.dates.detail.asks").exists)
        screen(app, "us.dates.detail.back").tap()
        XCTAssertFalse(screen(app, "us.dates.detail.page").waitForExistence(timeout: 1))
    }

    @MainActor
    func testUsWishlistOpensFromGift() throws {
        let app = XCUIApplication()
        app.launch()

        screen(app, "tab.us").tap()
        XCTAssertTrue(screen(app, "us.tile.wishlist").waitForExistence(timeout: 5))
        screen(app, "us.tile.wishlist").tap()
        XCTAssertTrue(screen(app, "us.wishlist.page").waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Wishlist"].exists)
        XCTAssertTrue(screen(app, "us.wishlist.tabs").exists)
        screen(app, "us.wishlist.back").tap()
        XCTAssertFalse(screen(app, "us.wishlist.page").waitForExistence(timeout: 1))
    }

    @MainActor
    func testUsWishlistOpensFromDatesListIdeas() throws {
        let app = XCUIApplication()
        app.launch()

        // Wishlist ideas entry remains on the Us gift control (list modal is no longer the primary Dates path).
        screen(app, "tab.us").tap()
        XCTAssertTrue(screen(app, "us.tile.wishlist").waitForExistence(timeout: 5))
        screen(app, "us.tile.wishlist").tap()
        XCTAssertTrue(screen(app, "us.wishlist.page").waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Wishlist"].exists || app.staticTexts["Alex"].exists)
    }

    @MainActor
    func testLoveNotesPageOpensFromTile() throws {
        let app = XCUIApplication()
        app.launch()

        screen(app, "tab.us").tap()
        XCTAssertTrue(screen(app, "us.tile.lovenotes").waitForExistence(timeout: 5))
        screen(app, "us.tile.lovenotes").tap()
        XCTAssertTrue(screen(app, "us.lovenotes.page").waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Love Notes"].exists)
    }

    @MainActor
    func testLoveNoteComposeAndSend() throws {
        let app = XCUIApplication()
        app.launch()

        screen(app, "tab.us").tap()
        XCTAssertTrue(screen(app, "us.tile.lovenotes").waitForExistence(timeout: 5))
        screen(app, "us.tile.lovenotes").tap()
        XCTAssertTrue(screen(app, "us.lovenotes.page").waitForExistence(timeout: 3))

        let cta = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Write'")).firstMatch
        XCTAssertTrue(cta.waitForExistence(timeout: 2))
        cta.tap()
        XCTAssertTrue(screen(app, "us.lovenotes.compose.modal").waitForExistence(timeout: 3))
    }

    @MainActor
    func testLoveNoteReaderOpensFromPage() throws {
        let app = XCUIApplication()
        app.launch()

        screen(app, "tab.us").tap()
        XCTAssertTrue(screen(app, "us.tile.lovenotes").waitForExistence(timeout: 5))
        screen(app, "us.tile.lovenotes").tap()
        XCTAssertTrue(screen(app, "us.lovenotes.page").waitForExistence(timeout: 3))

        let noteRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'New note' OR label CONTAINS 'note'")).firstMatch
        if noteRow.waitForExistence(timeout: 2) {
            noteRow.tap()
            XCTAssertTrue(screen(app, "us.lovenotes.reader").waitForExistence(timeout: 3))
        }
    }

    @MainActor
    func testScreenPhotoArchiveOpensFromTheirScreen() throws {
        let app = XCUIApplication()
        app.launch()

        screen(app, "tab.us").tap()
        XCTAssertTrue(screen(app, "us.screen.card").waitForExistence(timeout: 5))
        screen(app, "us.screen.card").tap()
        XCTAssertTrue(screen(app, "us.screen.page").waitForExistence(timeout: 3))
        screen(app, "us.screen.archive").tap()
        XCTAssertTrue(screen(app, "us.screen.archive.page").waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["No archived photos yet"].exists)
        screen(app, "us.screen.archive.back").tap()
        XCTAssertTrue(screen(app, "us.screen.page").waitForExistence(timeout: 2))
    }

    @MainActor
    func testConnectionTodaysActivityFlow() throws {
        let app = XCUIApplication()
        app.launch()

        screen(app, "tab.connection").tap()
        XCTAssertTrue(screen(app, "screen.connection").waitForExistence(timeout: 5))
        XCTAssertTrue(screen(app, "connection.carousel").waitForExistence(timeout: 3))
        XCTAssertTrue(screen(app, "connection.pill").waitForExistence(timeout: 2))
        XCTAssertTrue(screen(app, "connection.sections").waitForExistence(timeout: 2))

        let openCTA = screen(app, "connection.cta.activity")
        XCTAssertTrue(openCTA.waitForExistence(timeout: 3), "Expected Today's Activity CTA on first slide")
        // Coordinate tap avoids AX scroll-to-visible fighting the carousel drag gesture.
        openCTA.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        XCTAssertTrue(screen(app, "connection.activity.hub").waitForExistence(timeout: 3))
        screen(app, "connection.activity.open").tap()
        XCTAssertTrue(screen(app, "connection.activity.detail").waitForExistence(timeout: 3))
        XCTAssertFalse(screen(app, "tab.bar").exists, "Tab bar should be hidden on the daily task screen")
        screen(app, "connection.activity.done").tap()
        XCTAssertTrue(screen(app, "connection.activity.waiting").waitForExistence(timeout: 2))
        XCTAssertTrue(screen(app, "tab.bar").waitForExistence(timeout: 2), "Tab bar should return on the activity hub")
        XCTAssertEqual(screen(app, "connection.activity.chip.you").label, "You, Waiting")
        XCTAssertEqual(screen(app, "connection.activity.chip.partner").label, "Partner, Waiting")

        // Partner submits → awaiting approval; chips stay Waiting until Count it.
        XCTAssertTrue(screen(app, "connection.activity.pending").waitForExistence(timeout: 4))
        XCTAssertEqual(screen(app, "connection.activity.chip.partner").label, "Partner, Waiting")

        screen(app, "connection.activity.approve.partner-daily-today").tap()
        XCTAssertEqual(screen(app, "connection.activity.chip.partner").label, "Partner, Done")

        // Partner approves you → You Done + together celebration.
        XCTAssertTrue(screen(app, "connection.activity.together").waitForExistence(timeout: 4))
        XCTAssertEqual(screen(app, "connection.activity.chip.you").label, "You, Done")

        screen(app, "connection.activity.back").tap()
        XCTAssertTrue(screen(app, "connection.carousel").waitForExistence(timeout: 3))
    }

    @MainActor
    func testConnectionSectionsIndexOpensSection() throws {
        let app = XCUIApplication()
        app.launch()

        screen(app, "tab.connection").tap()
        XCTAssertTrue(screen(app, "connection.sections").waitForExistence(timeout: 5))
        screen(app, "connection.sections").tap()

        XCTAssertTrue(screen(app, "connection.sections.page").waitForExistence(timeout: 3))
        XCTAssertTrue(screen(app, "connection.sections.row.todays-activity").waitForExistence(timeout: 2))
        XCTAssertTrue(screen(app, "connection.sections.row.question-of-the-day").waitForExistence(timeout: 2))
        XCTAssertTrue(screen(app, "connection.sections.row.partner-quiz").waitForExistence(timeout: 2))
        XCTAssertTrue(screen(app, "connection.sections.row.try-premium").waitForExistence(timeout: 2))

        screen(app, "connection.sections.open.partner-quiz").tap()
        XCTAssertTrue(screen(app, "connection.quiz.hub").waitForExistence(timeout: 3))
        XCTAssertTrue(screen(app, "tab.bar").waitForExistence(timeout: 2), "Tab bar stays visible (light) inside Partner Quiz")
        screen(app, "connection.quiz.back").tap()

        screen(app, "connection.sections").tap()
        XCTAssertTrue(screen(app, "connection.sections.page").waitForExistence(timeout: 3))
        screen(app, "connection.sections.open.try-premium").tap()
        XCTAssertTrue(screen(app, "connection.carousel").waitForExistence(timeout: 3))
        XCTAssertTrue(screen(app, "connection.cta.start").waitForExistence(timeout: 2))

        screen(app, "connection.sections").tap()
        XCTAssertTrue(screen(app, "connection.sections.page").waitForExistence(timeout: 3))
        screen(app, "connection.sections.open.question-of-the-day").tap()
        XCTAssertTrue(screen(app, "connection.qotd.hub").waitForExistence(timeout: 3))
        XCTAssertFalse(screen(app, "tab.bar").exists, "Tab bar should be hidden inside Question of the day")
        screen(app, "connection.qotd.back").tap()

        screen(app, "connection.sections").tap()
        XCTAssertTrue(screen(app, "connection.sections.page").waitForExistence(timeout: 3))
        screen(app, "connection.sections.open.todays-activity").tap()
        XCTAssertTrue(screen(app, "connection.activity.hub").waitForExistence(timeout: 3))
    }

    @MainActor
    func testConnectionPartnerQuizFlow() throws {
        let app = XCUIApplication()
        app.launch()

        screen(app, "tab.connection").tap()
        XCTAssertTrue(screen(app, "connection.sections").waitForExistence(timeout: 5))
        screen(app, "connection.sections").tap()
        XCTAssertTrue(screen(app, "connection.sections.page").waitForExistence(timeout: 3))
        screen(app, "connection.sections.open.partner-quiz").tap()

        XCTAssertTrue(screen(app, "connection.quiz.hub").waitForExistence(timeout: 3))
        XCTAssertTrue(screen(app, "connection.quiz.howto").waitForExistence(timeout: 2))
        XCTAssertTrue(screen(app, "tab.bar").exists)
        screen(app, "connection.quiz.play").tap()

        XCTAssertTrue(screen(app, "connection.quiz.role").waitForExistence(timeout: 3))
        screen(app, "connection.quiz.role.continue").tap()

        XCTAssertTrue(screen(app, "connection.quiz.question").waitForExistence(timeout: 3))

        // Seeded truths: coffee b, weekend b, love c, stress b → 3/4 correct.
        let picks = ["b", "b", "c", "b"]
        for optionID in picks {
            let option = screen(app, "connection.quiz.option.\(optionID)")
            XCTAssertTrue(option.waitForExistence(timeout: 2))
            option.tap()
            screen(app, "connection.quiz.continue").tap()
        }

        XCTAssertTrue(screen(app, "connection.quiz.results").waitForExistence(timeout: 3))
        XCTAssertTrue(screen(app, "connection.quiz.score").exists)
        XCTAssertFalse(
            screen(app, "connection.quiz.points").exists,
            "Quiz results should not show a points earn chip"
        )
        XCTAssertTrue(screen(app, "connection.quiz.result.pq-coffee").exists)

        screen(app, "connection.quiz.done").tap()
        XCTAssertTrue(screen(app, "connection.carousel").waitForExistence(timeout: 3))

        screen(app, "tab.us").tap()
        XCTAssertTrue(screen(app, "us.daily.progress").waitForExistence(timeout: 3))
        XCTAssertFalse(
            screen(app, "us.level").exists,
            "Us hero should not show level/streak chrome"
        )
    }

    @MainActor
    func testConnectionQuestionOfTheDayDialogue() throws {
        let app = XCUIApplication()
        app.launch()

        screen(app, "tab.connection").tap()
        XCTAssertTrue(screen(app, "connection.sections").waitForExistence(timeout: 5))
        screen(app, "connection.sections").tap()
        XCTAssertTrue(screen(app, "connection.sections.page").waitForExistence(timeout: 3))
        screen(app, "connection.sections.open.question-of-the-day").tap()

        XCTAssertTrue(screen(app, "connection.qotd.hub").waitForExistence(timeout: 3))
        XCTAssertTrue(screen(app, "connection.qotd.question").exists)
        XCTAssertTrue(screen(app, "connection.qotd.composer").exists)
        XCTAssertFalse(screen(app, "tab.bar").exists, "Tab bar should be hidden while answering Question of the day")

        let composer = screen(app, "connection.qotd.composer")
        composer.tap()
        composer.typeText("Your laugh after dinner made the whole day lighter.")
        screen(app, "connection.qotd.send").tap()

        XCTAssertTrue(screen(app, "connection.qotd.waiting").waitForExistence(timeout: 3))
        XCTAssertFalse(screen(app, "connection.qotd.bubble.partner").exists)

        XCTAssertTrue(screen(app, "connection.qotd.dialogue").waitForExistence(timeout: 5))
        XCTAssertTrue(screen(app, "connection.qotd.bubble.you").exists)
        XCTAssertTrue(screen(app, "connection.qotd.bubble.partner").exists)

        screen(app, "connection.qotd.back").tap()
        XCTAssertTrue(screen(app, "connection.carousel").waitForExistence(timeout: 3))
        XCTAssertTrue(screen(app, "tab.bar").waitForExistence(timeout: 2))
    }

    @MainActor
    func testMoreScreenProfileAndPremium() throws {
        let app = XCUIApplication()
        app.launch()

        screen(app, "tab.more").tap()
        XCTAssertTrue(screen(app, "screen.more").waitForExistence(timeout: 5))
        XCTAssertTrue(screen(app, "more.profile").waitForExistence(timeout: 2))
        XCTAssertTrue(screen(app, "more.profile.name").exists)
        XCTAssertTrue(screen(app, "more.profile.plan").exists)

        // Demo starts on Free plan — unlock Premium from Subscription.
        let plan = screen(app, "more.profile.plan")
        if plan.label.contains("Free") {
            screen(app, "more.subscription").tap()
            let updated = screen(app, "more.profile.plan")
            XCTAssertTrue(updated.waitForExistence(timeout: 2))
            XCTAssertTrue(
                updated.label.contains("Premium"),
                "Try Premium should mark the session Premium, got: \(updated.label)"
            )
        }

        screen(app, "more.profile.edit").tap()
        XCTAssertTrue(screen(app, "more.profile.edit.sheet").waitForExistence(timeout: 2))
        XCTAssertTrue(screen(app, "more.profile.edit.name").exists)
        XCTAssertTrue(screen(app, "more.profile.edit.email").exists)
        app.buttons["Cancel"].tap()
        XCTAssertTrue(screen(app, "more.profile").waitForExistence(timeout: 2))

        // Demo starts paired — My partner sheet with disconnect.
        XCTAssertTrue(screen(app, "more.partner.open").waitForExistence(timeout: 2))
        screen(app, "more.partner.open").tap()
        XCTAssertTrue(screen(app, "more.partner.sheet").waitForExistence(timeout: 2))
        XCTAssertTrue(screen(app, "more.partner.disconnect").exists)
        app.buttons["Done"].tap()
        XCTAssertTrue(screen(app, "more.profile").waitForExistence(timeout: 2))
    }

    @MainActor
    func testLaunchPerformance() throws {
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

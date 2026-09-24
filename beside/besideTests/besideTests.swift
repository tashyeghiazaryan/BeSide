import Testing
@testable import beside

struct besideTests {

    @Test func moodCatalogHasSixMoodsAndCalmWishes() {
        #expect(MoodCatalog.all.count == 6)
        #expect(MoodCatalog.wishes(for: "calm").count == 3)
        #expect(MoodCatalog.mood(id: "calm")?.name == "Calm & Balanced")
    }

    @Test @MainActor func sessionStoreSeedsWeekHistory() {
        let store = MeSessionStore()
        #expect(!store.history.isEmpty)
        #expect(store.weekBuckets().count == 7)
        #expect(store.weekBuckets().last?.isToday == true)
    }
}

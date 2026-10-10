import Foundation

extension MeSessionStore {
    var isLiveBackend: Bool { liveGateway != nil }

    func attachLiveBackend(_ gateway: CoupleBackendGateway) async {
        liveGateway = gateway
        syncError = nil
        do {
            let snapshot = try await gateway.loadSnapshot()
            applyLiveSnapshot(snapshot)
            startLivePolling()
        } catch {
            syncError = error.localizedDescription
        }
    }

    func updateLiveContext(_ context: CoupleContext) {
        liveGateway?.updateContext(context)
        applyCoupleContext(context)
        if context.isPaired, liveGateway != nil {
            Task { await refreshFromLiveBackend() }
        }
    }

    func detachLiveBackend() {
        livePollTask?.cancel()
        livePollTask = nil
        liveGateway = nil
        syncError = nil
    }

    func refreshFromLiveBackend() async {
        guard let liveGateway else { return }
        do {
            let snapshot = try await liveGateway.loadSnapshot()
            applyLiveSnapshot(snapshot)
            syncError = nil
        } catch {
            syncError = error.localizedDescription
        }
    }

    func applyLiveSnapshot(_ snapshot: CoupleBackendGateway.Snapshot) {
        history = snapshot.myShares
        if let latest = snapshot.partnerShares.first {
            partnerCurrentMood = latest
            partnerHistory = snapshot.partnerShares
        } else if partnerHistory.isEmpty == false {
            // keep previous until partner shares
        } else {
            // placeholder empty partner mood — keep seed only if never loaded
        }
        if !snapshot.partnerShares.isEmpty {
            partnerHistory = snapshot.partnerShares
            if let first = snapshot.partnerShares.first {
                partnerCurrentMood = first
            }
        }
        importantDates = snapshot.importantDates
        myWishlist = snapshot.myWishlist
        partnerWishlist = snapshot.partnerWishlist
        wishlistHistory = snapshot.wishlistHistory
        loveNotes = snapshot.loveNotes
        sharedMemories = snapshot.sharedMemories
        usLongTermLevel = snapshot.level
        usLongTermPoints = snapshot.points
        usStreakDays = snapshot.streak
        if let start = snapshot.relationshipStart {
            relationshipStartDate = start
        }
        questionOfTheDayPrompt = snapshot.qotdPrompt
        meQuestionAnswer = snapshot.meQuestionAnswer
        partnerQuestionAnswer = snapshot.partnerQuestionAnswer
        meDailySubmittedToday = snapshot.meDailySubmitted
        partnerDailySubmittedToday = snapshot.partnerDailySubmitted
        meActivityDoneToday = snapshot.meActivityDone
        partnerActivityDoneToday = snapshot.partnerActivityDone
        connectionPendingAnswers = snapshot.pendingAnswers
        connectionDailyPhase = snapshot.dailyPhase
        myReactionToPartner = snapshot.myReactionToPartner
        myNoteToPartner = snapshot.myNoteToPartner
        refreshNotificationSources()
    }

    private func startLivePolling() {
        livePollTask?.cancel()
        livePollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(4))
                guard let self, self.liveGateway != nil else { return }
                await self.refreshFromLiveBackend()
            }
        }
    }
}

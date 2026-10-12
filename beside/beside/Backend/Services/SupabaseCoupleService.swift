import Foundation
import Supabase

enum CoupleServiceError: LocalizedError {
    case notConfigured
    case underlying(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Supabase is not configured."
        case .underlying(let message): return message
        }
    }
}

final class SupabaseCoupleService: CoupleService, @unchecked Sendable {
    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func fetchContext() async throws -> CoupleContext {
        struct Row: Decodable {
            let user_id: UUID
            let couple_id: UUID?
            let partner_user_id: UUID?
            let display_name: String?
            let partner_display_name: String?
            let invite_code: String?
        }

        do {
            let rows: [Row] = try await client
                .rpc("fetch_couple_context")
                .execute()
                .value
            guard let row = rows.first else {
                throw CoupleServiceError.underlying("No profile context.")
            }
            return CoupleContext(
                userId: row.user_id,
                coupleId: row.couple_id,
                partnerUserId: row.partner_user_id,
                displayName: row.display_name?.nilIfEmpty ?? "Partner",
                partnerDisplayName: row.partner_display_name?.nilIfEmpty,
                inviteCode: row.invite_code
            )
        } catch let error as CoupleServiceError {
            throw error
        } catch {
            throw CoupleServiceError.underlying(error.localizedDescription)
        }
    }

    func createCouple(displayName: String) async throws -> (CoupleContext, inviteCode: String) {
        struct Row: Decodable {
            let couple_id: UUID
            let invite_code: String
            let display_name: String?
        }

        do {
            let rows: [Row] = try await client
                .rpc("create_couple_with_invite", params: ["p_display_name": displayName])
                .execute()
                .value
            guard let row = rows.first else {
                throw CoupleServiceError.underlying("Could not create couple.")
            }
            let userId = try await requireUserId()
            let context = CoupleContext(
                userId: userId,
                coupleId: row.couple_id,
                partnerUserId: nil,
                displayName: row.display_name?.nilIfEmpty ?? displayName.nilIfEmpty ?? "Partner",
                partnerDisplayName: nil,
                inviteCode: row.invite_code
            )
            return (context, row.invite_code)
        } catch let error as CoupleServiceError {
            throw error
        } catch {
            throw CoupleServiceError.underlying(error.localizedDescription)
        }
    }

    func joinCouple(code: String) async throws -> CoupleContext {
        struct Row: Decodable {
            let couple_id: UUID
            let partner_user_id: UUID?
            let display_name: String?
            let partner_display_name: String?
        }

        do {
            let rows: [Row] = try await client
                .rpc(
                    "join_couple_with_code",
                    params: [
                        "p_code": code,
                        "p_display_name": "",
                    ]
                )
                .execute()
                .value
            guard let row = rows.first else {
                throw CoupleServiceError.underlying("Could not join couple.")
            }
            let userId = try await requireUserId()
            return CoupleContext(
                userId: userId,
                coupleId: row.couple_id,
                partnerUserId: row.partner_user_id,
                displayName: row.display_name?.nilIfEmpty ?? "Partner",
                partnerDisplayName: row.partner_display_name?.nilIfEmpty,
                inviteCode: nil
            )
        } catch let error as CoupleServiceError {
            throw error
        } catch {
            throw CoupleServiceError.underlying(error.localizedDescription)
        }
    }

    func updateDisplayName(_ displayName: String) async throws {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw CoupleServiceError.underlying("Name can’t be empty.")
        }
        do {
            try await client
                .rpc("ensure_profile", params: ["p_display_name": trimmed])
                .execute()
        } catch {
            throw CoupleServiceError.underlying(error.localizedDescription)
        }
    }

    func leaveCouple() async throws {
        do {
            try await client.rpc("leave_couple").execute()
        } catch {
            throw CoupleServiceError.underlying(error.localizedDescription)
        }
    }

    func setRelationshipStart(_ date: Date) async throws {
        let day = Self.dayString(date)
        do {
            try await client
                .rpc("set_relationship_start", params: ["p_date": day])
                .execute()
        } catch {
            throw CoupleServiceError.underlying(error.localizedDescription)
        }
    }

    private func requireUserId() async throws -> UUID {
        do {
            return try await client.auth.session.user.id
        } catch {
            throw CoupleServiceError.underlying("Not signed in.")
        }
    }

    private static func dayString(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}

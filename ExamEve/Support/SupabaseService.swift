import Foundation
import UIKit
import Supabase

enum SB {
    static let client = SupabaseClient(
        supabaseURL: URL(string: AppConfig.supabaseURL)!,
        supabaseKey: AppConfig.supabaseKey
    )
}

enum AppError: LocalizedError {
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .notSignedIn: return "로그인이 필요해요."
        }
    }
}

/// Supabase 영문 에러를 사용자에게 보여줄 한국어 문구로 변환
func koreanMessage(for error: Error) -> String {
    let raw = error.localizedDescription
    if raw.localizedCaseInsensitiveContains("Invalid login credentials") {
        return "이메일 또는 비밀번호가 올바르지 않아요."
    }
    if raw.localizedCaseInsensitiveContains("User already registered") {
        return "이미 가입된 이메일이에요."
    }
    if raw.localizedCaseInsensitiveContains("Password should be at least") {
        return "비밀번호는 6자 이상이어야 해요."
    }
    if raw.localizedCaseInsensitiveContains("Email not confirmed") {
        return "이메일 인증이 아직 완료되지 않았어요."
    }
    if raw.localizedCaseInsensitiveContains("Token has expired")
        || raw.localizedCaseInsensitiveContains("expired") {
        return "코드가 만료됐어요. 코드를 다시 요청해주세요."
    }
    if raw.localizedCaseInsensitiveContains("Token is invalid")
        || raw.localizedCaseInsensitiveContains("invalid token")
        || raw.localizedCaseInsensitiveContains("OTP") {
        return "코드가 올바르지 않아요. 다시 확인해주세요."
    }
    if raw.localizedCaseInsensitiveContains("invalid format")
        || raw.localizedCaseInsensitiveContains("validate email") {
        return "이메일 형식이 올바르지 않아요."
    }
    if raw.localizedCaseInsensitiveContains("rate limit")
        || raw.localizedCaseInsensitiveContains("too many") {
        return "요청이 너무 많아요. 잠시 후 다시 시도해주세요."
    }
    return raw
}

enum DataService {
    static var uid: UUID? { SB.client.auth.currentSession?.user.id }

    // MARK: - 프로필 / 학교

    static func fetchProfile(userId: UUID) async throws -> Profile? {
        let rows: [Profile] = try await SB.client.from("profiles")
            .select("id, nickname, school_id, avatar_url, avatar_color, schools(id, name, region)")
            .eq("id", value: userId)
            .execute().value
        return rows.first
    }

    // MARK: - 학습 세션

    static func recordStudySession(durationSeconds: Int, mode: String) async throws {
        guard let uid, durationSeconds >= 5 else { return }
        struct SessionInsert: Encodable {
            let user_id: UUID
            let mode: String
            let duration_seconds: Int
        }
        try await SB.client.from("study_sessions")
            .insert(SessionInsert(user_id: uid, mode: mode, duration_seconds: durationSeconds))
            .execute()
    }

    static func fetchMonthlySessions(year: Int, month: Int) async throws -> [StudySession] {
        guard let uid else { return [] }
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = 1
        let start = Calendar.current.date(from: comps)!
        let end   = Calendar.current.date(byAdding: .month, value: 1, to: start)!
        let fmt = ISO8601DateFormatter()
        return try await SB.client.from("study_sessions")
            .select()
            .eq("user_id", value: uid)
            .gte("studied_at", value: fmt.string(from: start))
            .lt("studied_at",  value: fmt.string(from: end))
            .execute().value
    }

    static func updateAvatarColor(_ colorKey: String) async throws {
        guard let uid else { throw AppError.notSignedIn }
        let payload: [String: AnyJSON] = [
            "avatar_color": .string(colorKey),
            "avatar_url": .null,
        ]
        try await SB.client.from("profiles").update(payload).eq("id", value: uid).execute()
    }

    static func uploadAvatar(_ image: UIImage) async throws {
        guard let uid else { throw AppError.notSignedIn }
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let path = "\(uid.uuidString).jpg"
        try await SB.client.storage
            .from("avatars")
            .upload(path, data: data, options: FileOptions(contentType: "image/jpeg", upsert: true))
        let url = try SB.client.storage.from("avatars").getPublicURL(path: path)
        let payload: [String: AnyJSON] = ["avatar_url": .string(url.absoluteString)]
        try await SB.client.from("profiles").update(payload).eq("id", value: uid).execute()
    }

    static func createProfile(nickname: String, schoolId: UUID?) async throws {
        guard let uid else { throw AppError.notSignedIn }
        let payload: [String: AnyJSON] = [
            "id": .string(uid.uuidString),
            "nickname": .string(nickname),
            "school_id": schoolId.map { .string($0.uuidString) } ?? .null,
        ]
        try await SB.client.from("profiles").insert(payload).execute()
    }

    static func updateNickname(_ nickname: String) async throws {
        guard let uid else { throw AppError.notSignedIn }
        try await SB.client.from("profiles")
            .update(["nickname": nickname])
            .eq("id", value: uid)
            .execute()
    }

    static func updateSchool(_ schoolId: UUID?) async throws {
        guard let uid else { throw AppError.notSignedIn }
        let payload: [String: AnyJSON] = [
            "school_id": schoolId.map { .string($0.uuidString) } ?? .null
        ]
        try await SB.client.from("profiles").update(payload).eq("id", value: uid).execute()
    }

    static func fetchAllSubjects() async throws -> [Subject] {
        try await SB.client.from("subjects")
            .select()
            .execute().value
    }

    static func searchSchools(query: String) async throws -> [School] {
        struct SearchResult: Codable {
            let id: UUID
            let name: String
            let region: String
        }
        struct RpcParams: Encodable {
            let q: String
            let lim: Int
        }
        let rows: [SearchResult] = try await SB.client
            .rpc("search_schools", params: RpcParams(q: query, lim: 20))
            .execute().value
        return rows.map { School(id: $0.id, name: $0.name, region: $0.region) }
    }

    // MARK: - 덱

    static func myDecks() async throws -> [Deck] {
        guard let uid else { return [] }
        return try await SB.client.from("decks")
            .select("*, cards(count), subjects(id, category, type, name)")
            .eq("user_id", value: uid)
            .order("created_at", ascending: false)
            .execute().value
    }

    static func fetchDeck(id: UUID) async throws -> Deck? {
        let rows: [Deck] = try await SB.client.from("decks")
            .select("*, cards(count), subjects(id, category, type, name)")
            .eq("id", value: id)
            .execute().value
        return rows.first
    }

    static func publicDecks() async throws -> [Deck] {
        try await SB.client.from("decks")
            .select("*, cards(count), profiles(nickname), subjects(id, category, type, name)")
            .eq("is_shared_public", value: true)
            .order("created_at", ascending: false)
            .limit(200)
            .execute().value
    }

    static func schoolDecks(schoolId: UUID) async throws -> [Deck] {
        try await SB.client.from("decks")
            .select("*, cards(count), profiles(nickname), subjects(id, category, type, name)")
            .eq("is_shared_school", value: true)
            .eq("school_id", value: schoolId)
            .order("created_at", ascending: false)
            .limit(200)
            .execute().value
    }

    static func createDeck(name: String, subject: String, subjectId: UUID?, unit: String, cards: [(concept: String, meaning: String)]) async throws -> Deck {
        guard let uid else { throw AppError.notSignedIn }
        struct DeckInsert: Encodable {
            let user_id: UUID
            let name: String
            let subject: String
            let subject_id: UUID?
            let unit: String
        }
        let deck: Deck = try await SB.client.from("decks")
            .insert(DeckInsert(user_id: uid, name: name, subject: subject, subject_id: subjectId, unit: unit))
            .select("*, cards(count), subjects(id, category, type, name)")
            .single()
            .execute().value
        if !cards.isEmpty {
            let payloads = cards.enumerated().map { index, card in
                CardInsert(deck_id: deck.id, concept: card.concept, meaning: card.meaning, order: index)
            }
            try await SB.client.from("cards").insert(payloads).execute()
        }
        return deck
    }

    static func updateDeckInfo(id: UUID, name: String, subject: String, subjectId: UUID?, unit: String) async throws {
        let payload: [String: AnyJSON] = [
            "name": .string(name),
            "subject": .string(subject),
            "subject_id": subjectId.map { .string($0.uuidString) } ?? .null,
            "unit": .string(unit),
        ]
        try await SB.client.from("decks")
            .update(payload)
            .eq("id", value: id)
            .execute()
    }

    static func deleteDeck(id: UUID) async throws {
        try await SB.client.from("decks").delete().eq("id", value: id).execute()
    }

    static func setSharing(deckId: UUID, isPublic: Bool, isSchool: Bool, schoolId: UUID?) async throws {
        let payload: [String: AnyJSON] = [
            "is_shared_public": .bool(isPublic),
            "is_shared_school": .bool(isSchool),
            "school_id": (isSchool ? schoolId : nil).map { .string($0.uuidString) } ?? .null,
        ]
        try await SB.client.from("decks").update(payload).eq("id", value: deckId).execute()
    }

    static func downloadDeck(id: UUID) async throws -> UUID {
        try await SB.client.rpc("download_deck", params: ["p_deck_id": id.uuidString])
            .execute().value
    }

    // MARK: - 카드

    struct CardInsert: Encodable {
        let deck_id: UUID
        let concept: String
        let meaning: String
        let order: Int
    }

    static func cards(deckId: UUID) async throws -> [Card] {
        try await SB.client.from("cards")
            .select()
            .eq("deck_id", value: deckId)
            .order("order", ascending: true)
            .execute().value
    }

    static func insertCard(deckId: UUID, concept: String, meaning: String, order: Int) async throws {
        try await SB.client.from("cards")
            .insert(CardInsert(deck_id: deckId, concept: concept, meaning: meaning, order: order))
            .execute()
    }

    static func insertCards(_ cards: [CardInsert]) async throws {
        guard !cards.isEmpty else { return }
        try await SB.client.from("cards").insert(cards).execute()
    }

    static func deleteCards(ids: [UUID]) async throws {
        guard !ids.isEmpty else { return }
        try await SB.client.from("cards")
            .delete()
            .in("id", values: ids.map(\.uuidString))
            .execute()
    }

    static func updateCard(id: UUID, concept: String, meaning: String, order: Int) async throws {
        let payload: [String: AnyJSON] = [
            "concept": .string(concept),
            "meaning": .string(meaning),
            "order": .integer(order),
        ]
        try await SB.client.from("cards").update(payload).eq("id", value: id).execute()
    }

    static func deleteCard(id: UUID) async throws {
        try await SB.client.from("cards").delete().eq("id", value: id).execute()
    }

    // MARK: - 오답

    static func wrongEntries(deckId: UUID) async throws -> [WrongAnswerEntry] {
        guard let uid else { return [] }
        return try await SB.client.from("wrong_answers")
            .select("id, card_id, mode, cards!inner(*)")
            .eq("user_id", value: uid)
            .eq("cards.deck_id", value: deckId)
            .execute().value
    }

    static func recordWrong(cardId: UUID, mode: String) async throws {
        guard let uid else { return }
        struct WrongUpsert: Encodable {
            let user_id: UUID
            let card_id: UUID
            let mode: String
        }
        try await SB.client.from("wrong_answers")
            .upsert(WrongUpsert(user_id: uid, card_id: cardId, mode: mode), onConflict: "user_id,card_id")
            .execute()
    }

    static func removeWrong(cardId: UUID) async throws {
        guard let uid else { return }
        try await SB.client.from("wrong_answers")
            .delete()
            .eq("user_id", value: uid)
            .eq("card_id", value: cardId)
            .execute()
    }

    static func clearWrong(cardIds: [UUID]) async throws {
        guard let uid, !cardIds.isEmpty else { return }
        try await SB.client.from("wrong_answers")
            .delete()
            .eq("user_id", value: uid)
            .in("card_id", values: cardIds.map(\.uuidString))
            .execute()
    }
}

import Foundation

struct School: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    var region: String = ""
}

struct Subject: Codable, Identifiable, Hashable {
    let id: UUID
    let category: String
    let type: String
    let name: String
}

struct Profile: Codable, Identifiable, Hashable {
    let id: UUID
    var nickname: String
    var schoolId: UUID?
    var school: School?
    var avatarUrl: String?
    var avatarColor: String?

    enum CodingKeys: String, CodingKey {
        case id, nickname
        case schoolId = "school_id"
        case school = "schools"
        case avatarUrl = "avatar_url"
        case avatarColor = "avatar_color"
    }
}

struct Card: Codable, Identifiable, Hashable {
    let id: UUID
    let deckId: UUID
    var concept: String
    var meaning: String
    var position: Int?

    enum CodingKeys: String, CodingKey {
        case id, concept, meaning
        case deckId = "deck_id"
        case position = "order"
    }
}

struct CountWrapper: Codable, Hashable {
    let count: Int
}

struct NicknameWrapper: Codable, Hashable {
    let nickname: String
}

struct Deck: Codable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    var name: String
    var subject: String
    var unit: String
    var subjectId: UUID?
    var subjectInfo: Subject?
    var isSharedPublic: Bool
    var isSharedSchool: Bool
    var schoolId: UUID?
    var downloadedCount: Int
    var sourceDeckId: UUID?
    var cards: [CountWrapper]?
    var profiles: NicknameWrapper?

    var cardCount: Int { cards?.first?.count ?? 0 }
    var ownerNickname: String { profiles?.nickname ?? "" }
    var isShared: Bool { isSharedPublic || isSharedSchool }
    var isDownloaded: Bool { sourceDeckId != nil }

    enum CodingKeys: String, CodingKey {
        case id, name, subject, unit, cards, profiles
        case userId = "user_id"
        case subjectId = "subject_id"
        case subjectInfo = "subjects"
        case isSharedPublic = "is_shared_public"
        case isSharedSchool = "is_shared_school"
        case schoolId = "school_id"
        case downloadedCount = "downloaded_count"
        case sourceDeckId = "source_deck_id"
    }
}

struct StudySession: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let mode: String
    let durationSeconds: Int
    let studiedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, mode
        case userId = "user_id"
        case durationSeconds = "duration_seconds"
        case studiedAt = "studied_at"
    }
}

struct WrongAnswerEntry: Codable, Identifiable, Hashable {
    let id: UUID
    let cardId: UUID
    let mode: String
    let card: Card

    var modeLabel: String { mode == "test" ? "테스트" : "리콜" }

    enum CodingKeys: String, CodingKey {
        case id, mode
        case cardId = "card_id"
        case card = "cards"
    }
}

// iOS Models.swift와 동일한 데이터 모델 (snake_case DB → camelCase 매핑은 data.ts에서 처리)

export interface School {
  id: string
  name: string
  region: string
}

export interface Subject {
  id: string
  category: string
  type: string
  name: string
}

export interface Profile {
  id: string
  nickname: string
  schoolId: string | null
  school: School | null
  avatarUrl: string | null
  avatarColor: string | null
}

export interface Card {
  id: string
  deckId: string
  concept: string
  meaning: string
  position: number | null
}

export interface Deck {
  id: string
  userId: string
  name: string
  subject: string
  unit: string
  subjectId: string | null
  subjectInfo: Subject | null
  isSharedPublic: boolean
  isSharedSchool: boolean
  schoolId: string | null
  downloadedCount: number
  sourceDeckId: string | null
  cardCount: number
  ownerNickname: string
}

export const deckIsShared = (d: Deck) => d.isSharedPublic || d.isSharedSchool
export const deckIsDownloaded = (d: Deck) => d.sourceDeckId != null

export interface StudySession {
  id: string
  userId: string
  mode: string
  durationSeconds: number
  studiedAt: string
}

export interface WrongAnswerEntry {
  id: string
  cardId: string
  mode: string
  card: Card
  modeLabel: string
}

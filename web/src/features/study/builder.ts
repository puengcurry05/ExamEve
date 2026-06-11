import type { Card } from '../../lib/types'

export type QuestionKind = 'recall' | 'spell'

export interface StudyQuestion {
  id: string
  card: Card
  kind: QuestionKind
  options: string[]
  answerIndex: number
}

export interface QuestionResult {
  question: StudyQuestion
  correct: boolean
  userAnswer: string
}

let qSeq = 0
const qid = () => `q${qSeq++}`

function shuffle<T>(arr: T[]): T[] {
  const a = [...arr]
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[a[i], a[j]] = [a[j], a[i]]
  }
  return a
}

// 같은 덱 내 다른 카드 개념으로 4지선다 구성. 부족하면 의미/플레이스홀더로 채움.
export function recallOptions(card: Card, cards: Card[]): { options: string[]; answerIndex: number } {
  const seen = new Set<string>([card.concept])
  const conceptPool = shuffle(
    cards.filter((c) => c.id !== card.id && !seen.has(c.concept) && (seen.add(c.concept), true)).map((c) => c.concept)
  )
  const meaningPool = shuffle(
    cards.filter((c) => c.id !== card.id && !seen.has(c.meaning) && (seen.add(c.meaning), true)).map((c) => c.meaning)
  )
  const distractors = [...conceptPool, ...meaningPool].slice(0, 3)
  while (distractors.length < 3) distractors.push(`보기 ${distractors.length + 1}`)

  const options = shuffle([...distractors, card.concept])
  const answerIndex = options.indexOf(card.concept)
  return { options, answerIndex: answerIndex < 0 ? 0 : answerIndex }
}

export function recallQuestions(cards: Card[]): StudyQuestion[] {
  return shuffle(cards).map((card) => {
    const { options, answerIndex } = recallOptions(card, cards)
    return { id: qid(), card, kind: 'recall', options, answerIndex }
  })
}

export function spellQuestions(cards: Card[]): StudyQuestion[] {
  return shuffle(cards).map((card) => ({ id: qid(), card, kind: 'spell', options: [], answerIndex: 0 }))
}

export function testQuestions(cards: Card[], count: number): StudyQuestion[] {
  return shuffle(cards)
    .slice(0, count)
    .map((card) => {
      if (Math.random() < 0.5) {
        const { options, answerIndex } = recallOptions(card, cards)
        return { id: qid(), card, kind: 'recall', options, answerIndex } as StudyQuestion
      }
      return { id: qid(), card, kind: 'spell', options: [], answerIndex: 0 } as StudyQuestion
    })
}

export function normalize(text: string): string {
  return text.toLowerCase().split(/\s+/).filter(Boolean).join(' ')
}

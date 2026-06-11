import { supabase } from './supabase'
import type {
  Card,
  Deck,
  Profile,
  School,
  StudySession,
  Subject,
  WrongAnswerEntry,
} from './types'

// ── 현재 사용자 ──────────────────────────────────────────
export async function currentUid(): Promise<string | null> {
  const { data } = await supabase.auth.getSession()
  return data.session?.user.id ?? null
}

// ── 매퍼 (snake_case row → camelCase 모델) ───────────────

function mapSchool(row: any): School | null {
  if (!row) return null
  return { id: row.id, name: row.name, region: row.region ?? '' }
}

function mapSubject(row: any): Subject | null {
  if (!row) return null
  return { id: row.id, category: row.category, type: row.type, name: row.name }
}

function mapProfile(row: any): Profile {
  return {
    id: row.id,
    nickname: row.nickname,
    schoolId: row.school_id ?? null,
    school: mapSchool(row.schools),
    avatarUrl: row.avatar_url ?? null,
    avatarColor: row.avatar_color ?? null,
  }
}

function mapCard(row: any): Card {
  return {
    id: row.id,
    deckId: row.deck_id,
    concept: row.concept,
    meaning: row.meaning,
    position: row.order ?? null,
  }
}

function mapDeck(row: any): Deck {
  const cardCount = Array.isArray(row.cards) ? row.cards[0]?.count ?? 0 : 0
  return {
    id: row.id,
    userId: row.user_id,
    name: row.name,
    subject: row.subject ?? '',
    unit: row.unit ?? '',
    subjectId: row.subject_id ?? null,
    subjectInfo: mapSubject(row.subjects),
    isSharedPublic: row.is_shared_public ?? false,
    isSharedSchool: row.is_shared_school ?? false,
    schoolId: row.school_id ?? null,
    downloadedCount: row.downloaded_count ?? 0,
    sourceDeckId: row.source_deck_id ?? null,
    cardCount,
    ownerNickname: row.profiles?.nickname ?? '',
  }
}

function mapWrong(row: any): WrongAnswerEntry {
  return {
    id: row.id,
    cardId: row.card_id,
    mode: row.mode,
    card: mapCard(row.cards),
    modeLabel: row.mode === 'test' ? '테스트' : '리콜',
  }
}

// ── 프로필 / 학교 ────────────────────────────────────────

export async function fetchProfile(userId: string): Promise<Profile | null> {
  const { data, error } = await supabase
    .from('profiles')
    .select('id, nickname, school_id, avatar_url, avatar_color, schools(id, name, region)')
    .eq('id', userId)
  if (error) throw error
  const row = data?.[0]
  return row ? mapProfile(row) : null
}

export async function createProfile(nickname: string, schoolId: string | null): Promise<void> {
  const uid = await currentUid()
  if (!uid) throw new Error('로그인이 필요해요.')
  const { error } = await supabase
    .from('profiles')
    .insert({ id: uid, nickname, school_id: schoolId })
  if (error) throw error
}

export async function updateNickname(nickname: string): Promise<void> {
  const uid = await currentUid()
  if (!uid) throw new Error('로그인이 필요해요.')
  const { error } = await supabase.from('profiles').update({ nickname }).eq('id', uid)
  if (error) throw error
}

export async function updateSchool(schoolId: string | null): Promise<void> {
  const uid = await currentUid()
  if (!uid) throw new Error('로그인이 필요해요.')
  const { error } = await supabase.from('profiles').update({ school_id: schoolId }).eq('id', uid)
  if (error) throw error
}

export async function updateAvatarColor(colorKey: string): Promise<void> {
  const uid = await currentUid()
  if (!uid) throw new Error('로그인이 필요해요.')
  const { error } = await supabase
    .from('profiles')
    .update({ avatar_color: colorKey, avatar_url: null })
    .eq('id', uid)
  if (error) throw error
}

export async function uploadAvatar(file: File): Promise<void> {
  const uid = await currentUid()
  if (!uid) throw new Error('로그인이 필요해요.')
  const path = `${uid}.jpg`
  const { error: upErr } = await supabase.storage
    .from('avatars')
    .upload(path, file, { contentType: file.type || 'image/jpeg', upsert: true })
  if (upErr) throw upErr
  const { data } = supabase.storage.from('avatars').getPublicUrl(path)
  // 캐시 무효화를 위해 timestamp 쿼리 추가
  const url = `${data.publicUrl}?t=${Date.now()}`
  const { error } = await supabase.from('profiles').update({ avatar_url: url }).eq('id', uid)
  if (error) throw error
}

export async function fetchAllSubjects(): Promise<Subject[]> {
  const { data, error } = await supabase.from('subjects').select()
  if (error) throw error
  return (data ?? []).map(mapSubject).filter((s): s is Subject => s !== null)
}

export async function searchSchools(query: string): Promise<School[]> {
  const { data, error } = await supabase.rpc('search_schools', { q: query, lim: 20 })
  if (error) throw error
  return (data ?? []).map((r: any) => ({ id: r.id, name: r.name, region: r.region }))
}

// ── 학습 세션 ────────────────────────────────────────────

export async function recordStudySession(durationSeconds: number, mode: string): Promise<void> {
  const uid = await currentUid()
  if (!uid || durationSeconds < 5) return
  const { error } = await supabase
    .from('study_sessions')
    .insert({ user_id: uid, mode, duration_seconds: durationSeconds })
  if (error) throw error
}

export async function fetchMonthlySessions(year: number, month: number): Promise<StudySession[]> {
  const uid = await currentUid()
  if (!uid) return []
  const start = new Date(year, month - 1, 1)
  const end = new Date(year, month, 1)
  const { data, error } = await supabase
    .from('study_sessions')
    .select()
    .eq('user_id', uid)
    .gte('studied_at', start.toISOString())
    .lt('studied_at', end.toISOString())
  if (error) throw error
  return (data ?? []).map((r: any) => ({
    id: r.id,
    userId: r.user_id,
    mode: r.mode,
    durationSeconds: r.duration_seconds,
    studiedAt: r.studied_at,
  }))
}

// ── 덱 ───────────────────────────────────────────────────

const DECK_SELECT_MINE = '*, cards(count), subjects(id, category, type, name)'
const DECK_SELECT_PUBLIC = '*, cards(count), profiles(nickname), subjects(id, category, type, name)'

export async function myDecks(): Promise<Deck[]> {
  const uid = await currentUid()
  if (!uid) return []
  const { data, error } = await supabase
    .from('decks')
    .select(DECK_SELECT_MINE)
    .eq('user_id', uid)
    .order('created_at', { ascending: false })
  if (error) throw error
  return (data ?? []).map(mapDeck)
}

export async function fetchDeck(id: string): Promise<Deck | null> {
  const { data, error } = await supabase.from('decks').select(DECK_SELECT_MINE).eq('id', id)
  if (error) throw error
  const row = data?.[0]
  return row ? mapDeck(row) : null
}

export async function publicDecks(): Promise<Deck[]> {
  const { data, error } = await supabase
    .from('decks')
    .select(DECK_SELECT_PUBLIC)
    .eq('is_shared_public', true)
    .order('created_at', { ascending: false })
    .limit(200)
  if (error) throw error
  return (data ?? []).map(mapDeck)
}

export async function schoolDecks(schoolId: string): Promise<Deck[]> {
  const { data, error } = await supabase
    .from('decks')
    .select(DECK_SELECT_PUBLIC)
    .eq('is_shared_school', true)
    .eq('school_id', schoolId)
    .order('created_at', { ascending: false })
    .limit(200)
  if (error) throw error
  return (data ?? []).map(mapDeck)
}

export async function createDeck(args: {
  name: string
  subject: string
  subjectId: string | null
  unit: string
  cards: { concept: string; meaning: string }[]
}): Promise<Deck> {
  const uid = await currentUid()
  if (!uid) throw new Error('로그인이 필요해요.')
  const { data, error } = await supabase
    .from('decks')
    .insert({
      user_id: uid,
      name: args.name,
      subject: args.subject,
      subject_id: args.subjectId,
      unit: args.unit,
    })
    .select(DECK_SELECT_MINE)
    .single()
  if (error) throw error
  const deck = mapDeck(data)
  if (args.cards.length > 0) {
    const payload = args.cards.map((c, i) => ({
      deck_id: deck.id,
      concept: c.concept,
      meaning: c.meaning,
      order: i,
    }))
    const { error: cardErr } = await supabase.from('cards').insert(payload)
    if (cardErr) throw cardErr
  }
  return deck
}

export async function updateDeckInfo(args: {
  id: string
  name: string
  subject: string
  subjectId: string | null
  unit: string
}): Promise<void> {
  const { error } = await supabase
    .from('decks')
    .update({
      name: args.name,
      subject: args.subject,
      subject_id: args.subjectId,
      unit: args.unit,
    })
    .eq('id', args.id)
  if (error) throw error
}

export async function deleteDeck(id: string): Promise<void> {
  const { error } = await supabase.from('decks').delete().eq('id', id)
  if (error) throw error
}

export async function setSharing(args: {
  deckId: string
  isPublic: boolean
  isSchool: boolean
  schoolId: string | null
}): Promise<void> {
  const { error } = await supabase
    .from('decks')
    .update({
      is_shared_public: args.isPublic,
      is_shared_school: args.isSchool,
      school_id: args.isSchool ? args.schoolId : null,
    })
    .eq('id', args.deckId)
  if (error) throw error
}

export async function downloadDeck(id: string): Promise<string> {
  const { data, error } = await supabase.rpc('download_deck', { p_deck_id: id })
  if (error) throw error
  return data as string
}

// ── 카드 ─────────────────────────────────────────────────

export async function cards(deckId: string): Promise<Card[]> {
  const { data, error } = await supabase
    .from('cards')
    .select()
    .eq('deck_id', deckId)
    .order('order', { ascending: true })
  if (error) throw error
  return (data ?? []).map(mapCard)
}

export async function insertCards(
  rows: { deckId: string; concept: string; meaning: string; order: number }[]
): Promise<void> {
  if (rows.length === 0) return
  const payload = rows.map((r) => ({
    deck_id: r.deckId,
    concept: r.concept,
    meaning: r.meaning,
    order: r.order,
  }))
  const { error } = await supabase.from('cards').insert(payload)
  if (error) throw error
}

export async function updateCard(
  id: string,
  concept: string,
  meaning: string,
  order: number
): Promise<void> {
  const { error } = await supabase.from('cards').update({ concept, meaning, order }).eq('id', id)
  if (error) throw error
}

export async function deleteCards(ids: string[]): Promise<void> {
  if (ids.length === 0) return
  const { error } = await supabase.from('cards').delete().in('id', ids)
  if (error) throw error
}

// ── 오답 ─────────────────────────────────────────────────

export async function wrongEntries(deckId: string): Promise<WrongAnswerEntry[]> {
  const uid = await currentUid()
  if (!uid) return []
  const { data, error } = await supabase
    .from('wrong_answers')
    .select('id, card_id, mode, cards!inner(*)')
    .eq('user_id', uid)
    .eq('cards.deck_id', deckId)
  if (error) throw error
  return (data ?? []).map(mapWrong)
}

export async function recordWrong(cardId: string, mode: string): Promise<void> {
  const uid = await currentUid()
  if (!uid) return
  const { error } = await supabase
    .from('wrong_answers')
    .upsert({ user_id: uid, card_id: cardId, mode }, { onConflict: 'user_id,card_id' })
  if (error) throw error
}

export async function removeWrong(cardId: string): Promise<void> {
  const uid = await currentUid()
  if (!uid) return
  const { error } = await supabase
    .from('wrong_answers')
    .delete()
    .eq('user_id', uid)
    .eq('card_id', cardId)
  if (error) throw error
}

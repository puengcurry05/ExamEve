import { useMemo, useState } from 'react'
import { Plus, Trash2, ChevronUp, ChevronDown } from 'lucide-react'
import {
  createDeck,
  updateDeckInfo,
  insertCards,
  updateCard,
  deleteCards,
} from '../../lib/data'
import { koreanMessage } from '../../lib/korean'
import type { Card, Deck, Subject } from '../../lib/types'
import { PrimaryButton } from '../../components/ui'
import SubjectPickerField from './SubjectPickerField'

export type EditorMode = { kind: 'create' } | { kind: 'edit'; deck: Deck; cards: Card[] }

interface EditableCard {
  key: string
  existingId?: string
  concept: string
  meaning: string
}

let keySeq = 0
const newCard = (): EditableCard => ({ key: `c${keySeq++}`, concept: '', meaning: '' })

export default function DeckEditorModal({
  mode,
  onClose,
  onSaved,
}: {
  mode: EditorMode
  onClose: () => void
  onSaved: () => void
}) {
  const isEdit = mode.kind === 'edit'

  const [name, setName] = useState(isEdit ? mode.deck.name : '')
  const [subject, setSubject] = useState<Subject | null>(isEdit ? mode.deck.subjectInfo : null)
  const [unit, setUnit] = useState(isEdit ? mode.deck.unit : '')
  const [cards, setCards] = useState<EditableCard[]>(() => {
    if (isEdit && mode.cards.length > 0) {
      return mode.cards.map((c) => ({
        key: `c${keySeq++}`,
        existingId: c.id,
        concept: c.concept,
        meaning: c.meaning,
      }))
    }
    return [newCard(), newCard()]
  })
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [dirty, setDirty] = useState(false)

  const isCardValid = (c: EditableCard) => c.concept.trim() !== '' && c.meaning.trim() !== ''
  const validCount = useMemo(() => cards.filter(isCardValid).length, [cards])
  const saveDisabled = name.trim() === '' || validCount === 0

  function touch() {
    if (!dirty) setDirty(true)
  }

  function updateCardField(key: string, field: 'concept' | 'meaning', value: string) {
    touch()
    setCards((cs) => cs.map((c) => (c.key === key ? { ...c, [field]: value } : c)))
  }

  function move(index: number, dir: -1 | 1) {
    const target = index + dir
    if (target < 0 || target >= cards.length) return
    touch()
    setCards((cs) => {
      const next = [...cs]
      ;[next[index], next[target]] = [next[target], next[index]]
      return next
    })
  }

  function removeCard(key: string) {
    touch()
    setCards((cs) => cs.filter((c) => c.key !== key))
  }

  function tryClose() {
    if (dirty) {
      if (window.confirm('변경 내용을 버릴까요?')) onClose()
    } else {
      onClose()
    }
  }

  async function save() {
    setBusy(true)
    setError(null)
    const trimmedName = name.trim()
    const valid = cards.filter(isCardValid)
    try {
      if (mode.kind === 'create') {
        await createDeck({
          name: trimmedName,
          subject: subject?.name ?? '',
          subjectId: subject?.id ?? null,
          unit: unit.trim(),
          cards: valid.map((c) => ({ concept: c.concept.trim(), meaning: c.meaning.trim() })),
        })
      } else {
        const { deck, cards: original } = mode
        await updateDeckInfo({
          id: deck.id,
          name: trimmedName,
          subject: subject?.name ?? '',
          subjectId: subject?.id ?? null,
          unit: unit.trim(),
        })
        const keptIds = new Set(valid.map((c) => c.existingId).filter(Boolean) as string[])
        const originalById = new Map(original.map((c) => [c.id, c]))

        const idsToDelete = original.filter((c) => !keptIds.has(c.id)).map((c) => c.id)
        await deleteCards(idsToDelete)

        const toInsert = valid
          .map((c, i) => ({ c, i }))
          .filter(({ c }) => !c.existingId)
          .map(({ c, i }) => ({
            deckId: deck.id,
            concept: c.concept.trim(),
            meaning: c.meaning.trim(),
            order: i,
          }))
        await insertCards(toInsert)

        const updates: Promise<void>[] = []
        valid.forEach((c, i) => {
          if (!c.existingId) return
          const orig = originalById.get(c.existingId)
          const concept = c.concept.trim()
          const meaning = c.meaning.trim()
          if (orig && (orig.concept !== concept || orig.meaning !== meaning || (orig.position ?? -1) !== i)) {
            updates.push(updateCard(c.existingId, concept, meaning, i))
          }
        })
        await Promise.all(updates)
      }
      onSaved()
    } catch (e) {
      setError(koreanMessage(e))
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 bg-black/30 flex items-end justify-center" onClick={tryClose}>
      <div
        className="w-full max-w-[480px] h-[92vh] bg-appbg rounded-t-2xl flex flex-col"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between px-4 py-3 border-b border-black/5 bg-appbg rounded-t-2xl">
          <button onClick={tryClose} className="text-primary">
            취소
          </button>
          <span className="font-bold">{isEdit ? '덱 편집' : '새 덱 만들기'}</span>
          <button
            onClick={() => void save()}
            disabled={saveDisabled || busy}
            className={`font-bold ${saveDisabled || busy ? 'text-gray-300' : 'text-primary'}`}
          >
            {isEdit ? '저장' : '만들기'}
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-4 flex flex-col gap-6">
          {/* 덱 정보 */}
          <section className="flex flex-col gap-3">
            <h2 className="font-semibold">덱 정보</h2>
            <input
              className="input-field"
              placeholder="덱 이름 (예: 영단어 1과)"
              value={name}
              onChange={(e) => {
                touch()
                setName(e.target.value)
              }}
            />
            <SubjectPickerField
              selected={subject}
              onSelect={(s) => {
                touch()
                setSubject(s)
              }}
            />
            <input
              className="input-field"
              placeholder="단원 (예: 1단원)"
              value={unit}
              onChange={(e) => {
                touch()
                setUnit(e.target.value)
              }}
            />
          </section>

          {/* 카드 */}
          <section className="flex flex-col gap-3">
            <div className="flex items-center justify-between">
              <h2 className="font-semibold">카드</h2>
              <span className="text-xs text-gray-500">{validCount}개</span>
            </div>

            {cards.map((card, index) => (
              <div key={card.key} className="card p-3.5 flex flex-col gap-2">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-primary">개념 (앞면)</span>
                  <div className="flex items-center gap-1 text-gray-400">
                    <button onClick={() => move(index, -1)} disabled={index === 0} className="disabled:opacity-30">
                      <ChevronUp size={18} />
                    </button>
                    <button
                      onClick={() => move(index, 1)}
                      disabled={index === cards.length - 1}
                      className="disabled:opacity-30"
                    >
                      <ChevronDown size={18} />
                    </button>
                    <button onClick={() => removeCard(card.key)} className="ml-1">
                      <Trash2 size={16} />
                    </button>
                  </div>
                </div>
                <textarea
                  className="w-full p-2.5 bg-appbg rounded-lg outline-none resize-none text-sm font-semibold"
                  rows={1}
                  placeholder="앞면"
                  value={card.concept}
                  onChange={(e) => updateCardField(card.key, 'concept', e.target.value)}
                />
                <span className="text-xs font-bold text-apppurple">의미 (뒷면)</span>
                <textarea
                  className="w-full p-2.5 bg-appbg rounded-lg outline-none resize-none text-sm"
                  rows={1}
                  placeholder="뒷면"
                  value={card.meaning}
                  onChange={(e) => updateCardField(card.key, 'meaning', e.target.value)}
                />
              </div>
            ))}

            <button
              onClick={() => {
                touch()
                setCards((cs) => [...cs, newCard()])
              }}
              className="w-full py-3 rounded-xl bg-primary/10 text-primary font-semibold flex items-center justify-center gap-1.5"
            >
              <Plus size={18} /> 카드 추가
            </button>
            <p className="text-xs text-gray-500">위/아래 화살표로 순서를 바꾸고, 휴지통으로 삭제할 수 있어요.</p>
          </section>

          {error && <p className="text-xs text-appred">{error}</p>}

          <div className="pb-4">
            <PrimaryButton
              title={isEdit ? '저장' : '만들기'}
              disabled={saveDisabled}
              busy={busy}
              onClick={() => void save()}
            />
          </div>
        </div>
      </div>
    </div>
  )
}

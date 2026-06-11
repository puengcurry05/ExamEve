import type { ReactNode } from 'react'
import { ChevronLeft, ArrowDownCircle, Users } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { resolveProfileColor } from '../lib/theme'
import type { Deck } from '../lib/types'
import { deckIsDownloaded, deckIsShared } from '../lib/types'
import { TagChip } from './ui'

// ── 상단 헤더 ───────────────────────────────────────────
export function TopBar({
  title,
  large = false,
  back = false,
  trailing,
}: {
  title: string
  large?: boolean
  back?: boolean
  trailing?: ReactNode
}) {
  const navigate = useNavigate()
  return (
    <div className="sticky top-0 z-20 bg-appbg/90 backdrop-blur px-4 pt-3 pb-2">
      <div className="flex items-center min-h-[36px] gap-2">
        {back && (
          <button onClick={() => navigate(-1)} className="-ml-1 text-primary">
            <ChevronLeft size={26} />
          </button>
        )}
        <h1 className={large ? 'text-2xl font-extrabold' : 'text-lg font-bold flex-1 truncate'}>
          {title}
        </h1>
        {!large && <div className="flex-1" />}
        {trailing}
      </div>
    </div>
  )
}

// ── 아바타 ──────────────────────────────────────────────
export function Avatar({
  url,
  colorKey,
  size = 80,
}: {
  url: string | null | undefined
  colorKey: string | null | undefined
  size?: number
}) {
  const bg = resolveProfileColor(colorKey)
  return (
    <div
      className="rounded-full overflow-hidden shrink-0 bg-cover bg-center"
      style={{
        width: size,
        height: size,
        backgroundColor: bg,
        backgroundImage: url ? `url(${url})` : undefined,
      }}
    />
  )
}

// ── 덱 행 (학습함/프로필 공용) ──────────────────────────
export function DeckRow({ deck }: { deck: Deck }) {
  const navigate = useNavigate()
  return (
    <button
      onClick={() => navigate(`/deck/${deck.id}`)}
      className="card w-full text-left p-4 active:scale-[0.99] transition"
    >
      <div className="flex items-start justify-between gap-2">
        <span className="font-semibold leading-snug line-clamp-2">{deck.name}</span>
        {deckIsDownloaded(deck) && <ArrowDownCircle size={20} className="text-appteal shrink-0" />}
      </div>
      <div className="flex flex-wrap gap-1.5 mt-2.5">
        {deck.subject && <TagChip text={deck.subject} />}
        {deck.unit && <TagChip text={deck.unit} color="#7C5CFF" />}
      </div>
      <div className="flex items-center gap-3 mt-2.5 text-xs text-gray-500">
        <span>카드 {deck.cardCount}개</span>
        {deckIsShared(deck) && (
          <span className="flex items-center gap-1 text-primary">
            <Users size={13} /> 공유 중
          </span>
        )}
        {deck.downloadedCount > 0 && <span>↓ {deck.downloadedCount}</span>}
      </div>
    </button>
  )
}

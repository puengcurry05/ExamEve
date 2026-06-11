import { useState } from 'react'
import { ChevronLeft, ChevronRight, CheckCircle2 } from 'lucide-react'
import type { Card } from '../../lib/types'
import { StudyHeader } from './StudyChrome'

export default function MemorizeView({
  title,
  cards,
  onClose,
}: {
  title: string
  cards: Card[]
  onClose: () => void
}) {
  const [current, setCurrent] = useState(0)
  const [flipped, setFlipped] = useState(false)
  const card = cards[current]
  const isLast = current === cards.length - 1

  function go(dir: -1 | 1) {
    const next = current + dir
    if (next < 0 || next >= cards.length) return
    setFlipped(false)
    setCurrent(next)
  }

  return (
    <div className="min-h-screen flex flex-col bg-appbg">
      <StudyHeader
        title={title}
        progressText={`${current + 1} / ${cards.length}`}
        progress={(current + 1) / cards.length}
        onClose={onClose}
      />

      <div className="flex-1 flex items-center justify-center px-6">
        <div className="w-full flip-card" style={{ height: 320 }} onClick={() => setFlipped((f) => !f)}>
          <div className={`flip-inner ${flipped ? 'flipped' : ''}`}>
            {/* 앞면 (개념) */}
            <div className="flip-face card flex flex-col items-center justify-center text-center p-7">
              <span className="text-xs font-bold text-primary">개념</span>
              <p className="text-2xl font-semibold mt-4">{card.concept}</p>
            </div>
            {/* 뒷면 (의미) */}
            <div
              className="flip-face flip-back rounded-card shadow-card flex flex-col items-center justify-center text-center p-7"
              style={{ backgroundColor: 'rgba(66,85,255,0.07)' }}
            >
              <span className="text-xs font-bold text-apppurple">의미</span>
              <p className="text-2xl font-semibold mt-4">{card.meaning}</p>
            </div>
          </div>
        </div>
      </div>

      <div className="flex flex-col items-center gap-3 pb-10">
        <p className="text-xs text-gray-500">탭하면 뒤집기</p>
        <div className="flex items-center gap-6">
          <button onClick={() => go(-1)} disabled={current === 0} className="disabled:opacity-30 text-primary">
            <ChevronLeft size={44} strokeWidth={1.5} className="fill-primary/10 rounded-full" />
          </button>
          <button
            onClick={() => (isLast ? onClose() : go(1))}
            className="text-primary"
          >
            {isLast ? (
              <CheckCircle2 size={44} strokeWidth={1.5} />
            ) : (
              <ChevronRight size={44} strokeWidth={1.5} className="fill-primary/10 rounded-full" />
            )}
          </button>
        </div>
      </div>
    </div>
  )
}

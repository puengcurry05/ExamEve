import { useState } from 'react'
import { CheckCircle2, Check, ArrowRight } from 'lucide-react'
import { removeWrong } from '../../lib/data'
import { koreanMessage } from '../../lib/korean'
import type { WrongAnswerEntry } from '../../lib/types'
import { StudyHeader } from './StudyChrome'
import { TagChip } from '../../components/ui'

export default function WrongAnswersView({
  entries,
  onClose,
}: {
  entries: WrongAnswerEntry[]
  onClose: () => void
}) {
  const [current, setCurrent] = useState(0)
  const [flipped, setFlipped] = useState(false)
  const [cleared, setCleared] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const entry = entries[current]
  const card = entry?.card

  function advance() {
    setFlipped(false)
    if (current + 1 < entries.length) setCurrent((c) => c + 1)
    else setCleared(true)
  }

  if (cleared || !card) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center gap-4 bg-appbg">
        <CheckCircle2 size={56} className="text-appgreen" />
        <h1 className="text-2xl font-bold">오답을 모두 학습했어요!</h1>
        <button onClick={onClose} className="px-5 py-2.5 rounded-xl bg-primary text-white font-semibold">
          닫기
        </button>
      </div>
    )
  }

  return (
    <div className="min-h-screen flex flex-col bg-appbg">
      <StudyHeader
        title="오답 복습"
        progressText={`${current + 1} / ${entries.length}`}
        progress={(current + 1) / entries.length}
        onClose={onClose}
      />

      <div className="flex-1 flex flex-col items-center justify-center px-6 gap-5">
        <div className="w-full">
          <TagChip text={`${entry.modeLabel} 오답`} color="#FF5C5C" />
        </div>
        <div className="w-full flip-card" style={{ height: 280 }} onClick={() => setFlipped((f) => !f)}>
          <div className={`flip-inner ${flipped ? 'flipped' : ''}`}>
            <div className="flip-face card flex flex-col items-center justify-center text-center p-7">
              <span className="text-xs font-bold text-apppurple">의미</span>
              <p className="text-2xl font-semibold mt-4">{card.meaning}</p>
            </div>
            <div
              className="flip-face flip-back rounded-card shadow-card flex flex-col items-center justify-center text-center p-7"
              style={{ backgroundColor: 'rgba(66,85,255,0.05)' }}
            >
              <span className="text-xs font-bold text-primary">개념</span>
              <p className="text-2xl font-semibold mt-4">{card.concept}</p>
            </div>
          </div>
        </div>
        <p className="text-xs text-gray-500">탭하면 뒤집기</p>
      </div>

      {error && <p className="px-5 text-xs text-appred">{error}</p>}

      <div className="flex items-center gap-3 px-5 pb-10">
        <button
          onClick={async () => {
            try {
              await removeWrong(card.id)
              advance()
            } catch (e) {
              setError(koreanMessage(e))
            }
          }}
          className="flex-1 py-3.5 rounded-xl bg-appgreen text-white font-semibold flex items-center justify-center gap-1.5"
        >
          <Check size={18} /> 알았어요
        </button>
        <button
          onClick={advance}
          className="flex-1 py-3.5 rounded-xl bg-white border border-black/10 font-semibold flex items-center justify-center gap-1.5"
        >
          다음에 <ArrowRight size={18} />
        </button>
      </div>
    </div>
  )
}

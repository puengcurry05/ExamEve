import type { LucideIcon } from 'lucide-react'
import { CheckCircle2 } from 'lucide-react'
import type { QuestionResult } from './builder'

export default function StudyResult({
  icon: Icon,
  iconColor,
  headline,
  score,
  correctCount,
  total,
  wrongResults,
  savedToWrongNote,
  onRetry,
  onRetryWrong,
  onClose,
}: {
  icon: LucideIcon
  iconColor: string
  headline: string
  score: number | null
  correctCount: number
  total: number
  wrongResults: QuestionResult[]
  savedToWrongNote: boolean
  onRetry: () => void
  onRetryWrong: (() => void) | null
  onClose: () => void
}) {
  const circumference = 2 * Math.PI * 70
  return (
    <div className="min-h-screen overflow-y-auto bg-appbg">
      <div className="flex flex-col items-center gap-5 p-5">
        <Icon size={56} color={iconColor} className="mt-10" />
        <h1 className="text-2xl font-bold">{headline}</h1>

        {score !== null && (
          <div className="relative w-40 h-40">
            <svg viewBox="0 0 160 160" className="w-full h-full -rotate-90">
              <circle cx="80" cy="80" r="70" fill="none" stroke="#4255FF26" strokeWidth="12" />
              <circle
                cx="80" cy="80" r="70" fill="none" stroke="#4255FF" strokeWidth="12" strokeLinecap="round"
                strokeDasharray={circumference}
                strokeDashoffset={circumference * (1 - score / 100)}
              />
            </svg>
            <div className="absolute inset-0 flex flex-col items-center justify-center">
              <span className="text-4xl font-black">{score}점</span>
              <span className="text-xs text-gray-500">100점 만점</span>
            </div>
          </div>
        )}

        <p className="font-semibold text-gray-500">
          {total}문항 중 {correctCount}개 정답
        </p>

        {wrongResults.length > 0 && (
          <div className="card w-full p-4">
            <div className="flex items-center justify-between mb-2.5">
              <h2 className="font-semibold">틀린 문제</h2>
              {savedToWrongNote && (
                <span className="flex items-center gap-1 text-xs text-appgreen">
                  <CheckCircle2 size={14} /> 오답에 저장됨
                </span>
              )}
            </div>
            <div className="flex flex-col gap-2.5">
              {wrongResults.map((r) => (
                <div key={r.question.id} className="rounded-[10px] bg-appred/[0.06] p-3">
                  <div className="text-sm font-semibold">{r.question.card.concept}</div>
                  <div className="text-xs text-gray-500 mt-0.5">{r.question.card.meaning}</div>
                </div>
              ))}
            </div>
          </div>
        )}

        <div className="w-full flex flex-col gap-2.5 pt-2">
          <button onClick={onRetry} className="w-full py-3.5 rounded-[14px] font-semibold text-white bg-primary">
            다시 하기
          </button>
          {wrongResults.length > 0 && onRetryWrong && (
            <button
              onClick={onRetryWrong}
              className="w-full py-3 rounded-[12px] font-semibold text-appred bg-appred/[0.08]"
            >
              틀린 카드만 다시 ({wrongResults.length}개)
            </button>
          )}
          <button onClick={onClose} className="w-full py-2 font-semibold">
            닫기
          </button>
        </div>
      </div>
    </div>
  )
}

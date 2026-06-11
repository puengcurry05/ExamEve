import { X } from 'lucide-react'

// 학습 화면 상단 진행 헤더 (iOS StudyHeader)
export function StudyHeader({
  title,
  progressText,
  progress,
  onClose,
}: {
  title: string
  progressText: string
  progress: number
  onClose: () => void
}) {
  return (
    <div className="px-5 pt-3 pb-2">
      <div className="flex items-center gap-3">
        <button onClick={onClose} className="text-gray-500">
          <X size={20} />
        </button>
        <span className="flex-1 text-center text-sm font-semibold truncate">{title}</span>
        <span className="text-sm font-semibold text-primary tabular-nums">{progressText}</span>
      </div>
      <div className="mt-2 h-1.5 rounded-full bg-primary/15 overflow-hidden">
        <div className="h-full bg-primary transition-all" style={{ width: `${progress * 100}%` }} />
      </div>
    </div>
  )
}

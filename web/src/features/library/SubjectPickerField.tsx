import { useEffect, useState } from 'react'
import { ChevronRight, ChevronLeft, Check, X } from 'lucide-react'
import { fetchAllSubjects } from '../../lib/data'
import { SUBJECT_TYPE_COLORS } from '../../lib/theme'
import type { Subject } from '../../lib/types'
import { Spinner } from '../../components/ui'

const CATEGORY_ORDER = [
  '국어', '수학', '영어', '사회(역사·도덕 포함)', '과학',
  '기술·가정', '정보', '제2외국어', '한문', '교양',
]
const TYPE_ORDER = ['공통', '일반선택', '진로선택', '융합선택']

export default function SubjectPickerField({
  selected,
  onSelect,
}: {
  selected: Subject | null
  onSelect: (s: Subject | null) => void
}) {
  const [open, setOpen] = useState(false)
  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="w-full flex items-center gap-2.5 px-3.5 py-3 bg-white rounded-xl border border-black/10 text-left"
      >
        {selected ? (
          <div className="flex-1">
            <div>{selected.name}</div>
            <div className="text-xs text-gray-500">
              {selected.category} · {selected.type}
            </div>
          </div>
        ) : (
          <span className="flex-1 text-gray-400">과목 선택 (선택사항)</span>
        )}
        <ChevronRight size={18} className="text-gray-300" />
      </button>
      {open && <SubjectPickerSheet selected={selected} onSelect={onSelect} onClose={() => setOpen(false)} />}
    </>
  )
}

function SubjectPickerSheet({
  selected,
  onSelect,
  onClose,
}: {
  selected: Subject | null
  onSelect: (s: Subject | null) => void
  onClose: () => void
}) {
  const [all, setAll] = useState<Subject[]>([])
  const [loading, setLoading] = useState(true)
  const [category, setCategory] = useState<string | null>(null)

  useEffect(() => {
    void (async () => {
      try {
        setAll(await fetchAllSubjects())
      } finally {
        setLoading(false)
      }
    })()
  }, [])

  const present = new Set(all.map((s) => s.category))
  const orderedCategories = [
    ...CATEGORY_ORDER.filter((c) => present.has(c)),
    ...[...present].filter((c) => !CATEGORY_ORDER.includes(c)).sort(),
  ]

  const inCategory = category ? all.filter((s) => s.category === category) : []
  const byType = TYPE_ORDER.map((t) => ({ type: t, items: inCategory.filter((s) => s.type === t) })).filter(
    (g) => g.items.length > 0
  )

  return (
    <div className="fixed inset-0 z-50 bg-black/30 flex items-end justify-center" onClick={onClose}>
      <div
        className="w-full max-w-[480px] h-[85vh] bg-appbg rounded-t-2xl flex flex-col"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between px-4 py-3 border-b border-black/5">
          {category ? (
            <button onClick={() => setCategory(null)} className="text-primary flex items-center">
              <ChevronLeft size={22} /> 교과
            </button>
          ) : (
            <button onClick={onClose} className="text-primary">
              취소
            </button>
          )}
          <span className="font-bold">{category ?? '교과 선택'}</span>
          {selected ? (
            <button
              onClick={() => {
                onSelect(null)
                onClose()
              }}
              className="text-appred text-sm"
            >
              초기화
            </button>
          ) : (
            <span className="w-10" />
          )}
        </div>

        <div className="flex-1 overflow-y-auto">
          {loading ? (
            <div className="h-full">
              <div className="flex items-center justify-center h-40 gap-2 text-gray-500">
                <Spinner /> 과목 목록 불러오는 중…
              </div>
            </div>
          ) : !category ? (
            <ul>
              {orderedCategories.map((cat) => {
                const sel = selected?.category === cat ? selected.name : null
                return (
                  <li key={cat}>
                    <button
                      onClick={() => setCategory(cat)}
                      className="w-full flex items-center justify-between px-4 py-3.5 bg-white border-b border-black/5"
                    >
                      <span>{cat}</span>
                      <span className="flex items-center gap-2">
                        {sel && <span className="text-xs text-gray-500">{sel}</span>}
                        <ChevronRight size={16} className="text-gray-300" />
                      </span>
                    </button>
                  </li>
                )
              })}
            </ul>
          ) : (
            <div className="py-2">
              {byType.map((group) => (
                <div key={group.type} className="mb-2">
                  <div
                    className="px-4 py-1.5 text-xs font-semibold"
                    style={{ color: SUBJECT_TYPE_COLORS[group.type] ?? '#888' }}
                  >
                    {group.type}
                  </div>
                  {group.items.map((subject) => (
                    <button
                      key={subject.id}
                      onClick={() => {
                        onSelect(subject)
                        onClose()
                      }}
                      className="w-full flex items-center justify-between px-4 py-3 bg-white border-b border-black/5"
                    >
                      <span>{subject.name}</span>
                      {selected?.id === subject.id ? (
                        <Check size={18} className="text-primary" />
                      ) : (
                        <span className="w-4" />
                      )}
                    </button>
                  ))}
                </div>
              ))}
              {byType.length === 0 && (
                <p className="px-4 py-6 text-sm text-gray-500 flex items-center gap-2">
                  <X size={16} /> 과목이 없어요
                </p>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

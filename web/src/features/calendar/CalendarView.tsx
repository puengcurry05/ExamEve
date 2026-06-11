import { useEffect, useMemo, useState } from 'react'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import { fetchMonthlySessions } from '../../lib/data'
import { FullScreenLoading } from '../../components/ui'
import { TopBar } from '../../components/shared'

const WEEKDAYS = ['일', '월', '화', '수', '목', '금', '토']

function firstOfMonth(d: Date): Date {
  return new Date(d.getFullYear(), d.getMonth(), 1)
}
function dayKey(d: Date): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}
function fmtHHMM(seconds: number): string {
  const h = Math.floor(seconds / 3600)
  const m = Math.floor((seconds % 3600) / 60)
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`
}

export default function CalendarView() {
  const today = useMemo(() => new Date(), [])
  const currentMonthStart = useMemo(() => firstOfMonth(today), [today])
  const [displayMonth, setDisplayMonth] = useState<Date>(currentMonthStart)
  const [byDay, setByDay] = useState<Record<string, number>>({})
  const [loading, setLoading] = useState(false)

  const year = displayMonth.getFullYear()
  const month = displayMonth.getMonth() // 0-based

  useEffect(() => {
    void (async () => {
      setLoading(true)
      try {
        const sessions = await fetchMonthlySessions(year, month + 1)
        const acc: Record<string, number> = {}
        for (const s of sessions) {
          const key = dayKey(new Date(s.studiedAt))
          acc[key] = (acc[key] ?? 0) + s.durationSeconds
        }
        setByDay(acc)
      } finally {
        setLoading(false)
      }
    })()
  }, [year, month])

  const monthTitle = `${year}년 ${month + 1}월`
  const canGoNext = firstOfMonth(new Date(year, month + 1, 1)) <= currentMonthStart

  // 그리드 계산
  const gridDays: (Date | null)[] = useMemo(() => {
    const first = new Date(year, month, 1)
    const lead = first.getDay() // 0=일
    const daysInMonth = new Date(year, month + 1, 0).getDate()
    const cells: (Date | null)[] = Array(lead).fill(null)
    for (let i = 0; i < daysInMonth; i++) cells.push(new Date(year, month, i + 1))
    while (cells.length % 7 !== 0) cells.push(null)
    return cells
  }, [year, month])

  const totalSeconds = Object.values(byDay).reduce((a, b) => a + b, 0)
  const studyDays = Object.values(byDay).filter((v) => v > 0).length
  const todayKey = dayKey(today)

  return (
    <div className="min-h-full">
      <TopBar title="달력" />

      {/* 월 네비게이터 */}
      <div className="flex items-center justify-between px-4 py-3">
        <button onClick={() => setDisplayMonth(new Date(year, month - 1, 1))} className="text-primary">
          <ChevronLeft size={24} />
        </button>
        <span className="text-lg font-bold">{monthTitle}</span>
        <button
          onClick={() => canGoNext && setDisplayMonth(new Date(year, month + 1, 1))}
          disabled={!canGoNext}
          className={canGoNext ? 'text-primary' : 'text-gray-300'}
        >
          <ChevronRight size={24} />
        </button>
      </div>

      {/* 요일 헤더 */}
      <div className="grid grid-cols-7 px-2">
        {WEEKDAYS.map((d) => (
          <div key={d} className="text-center text-xs font-semibold text-gray-500 py-2">
            {d}
          </div>
        ))}
      </div>
      <div className="border-t border-black/5" />

      {loading ? (
        <div className="h-[40vh]"><FullScreenLoading /></div>
      ) : (
        <>
          <div className="grid grid-cols-7 gap-0.5 px-2 pt-1">
            {gridDays.map((date, i) => {
              if (!date) return <div key={i} className="h-[60px]" />
              const key = dayKey(date)
              const sec = byDay[key] ?? 0
              const isToday = key === todayKey
              return (
                <div
                  key={i}
                  className={`h-[60px] rounded-lg flex flex-col items-center justify-center gap-1
                    ${sec > 0 && !isToday ? 'bg-primary/[0.05]' : ''}`}
                >
                  <div className="relative w-7 h-7 flex items-center justify-center">
                    {isToday && <span className="absolute inset-0 rounded-full bg-primary" />}
                    <span className={`relative text-sm ${isToday ? 'text-white font-bold' : ''}`}>
                      {date.getDate()}
                    </span>
                  </div>
                  <span className="text-[9px] font-semibold text-primary h-[11px]">
                    {sec > 0 ? fmtHHMM(sec) : ' '}
                  </span>
                </div>
              )
            })}
          </div>

          {totalSeconds > 0 && (
            <div className="card mx-4 mt-4 p-4 flex items-center justify-between">
              <div>
                <div className="text-xs text-gray-500">이번 달 총 학습</div>
                <div className="text-xl font-bold text-primary">{fmtHHMM(totalSeconds)}</div>
              </div>
              <div className="text-right">
                <div className="text-xs text-gray-500">학습일</div>
                <div className="text-xl font-bold text-primary">{studyDays}일</div>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  )
}

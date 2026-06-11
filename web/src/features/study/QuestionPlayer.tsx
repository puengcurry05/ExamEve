import { useEffect, useRef, useState } from 'react'
import { CheckCircle2, XCircle } from 'lucide-react'
import { recordWrong } from '../../lib/data'
import { normalize, type QuestionResult, type StudyQuestion } from './builder'
import { StudyHeader } from './StudyChrome'

export default function QuestionPlayer({
  title,
  questions,
  wrongMode,
  onClose,
  onFinish,
}: {
  title: string
  questions: StudyQuestion[]
  wrongMode: string | null
  onClose: () => void
  onFinish: (results: QuestionResult[]) => void
}) {
  const [current, setCurrent] = useState(0)
  const [selected, setSelected] = useState<number | null>(null)
  const [spellInput, setSpellInput] = useState('')
  const [spellSubmitted, setSpellSubmitted] = useState(false)
  const resultsRef = useRef<QuestionResult[]>([])
  const inputRef = useRef<HTMLInputElement>(null)
  const advanceTimer = useRef<ReturnType<typeof setTimeout> | null>(null)

  const question = questions[current]

  useEffect(() => {
    if (question.kind === 'spell' && !spellSubmitted) {
      inputRef.current?.focus()
    }
  }, [current, question.kind, spellSubmitted])

  useEffect(() => () => { if (advanceTimer.current) clearTimeout(advanceTimer.current) }, [])

  function finishQuestion(correct: boolean, userAnswer: string) {
    resultsRef.current.push({ question, correct, userAnswer })
    if (!correct && wrongMode) {
      void recordWrong(question.card.id, wrongMode)
    }
  }

  function advance() {
    if (current + 1 < questions.length) {
      setCurrent((c) => c + 1)
      setSelected(null)
      setSpellInput('')
      setSpellSubmitted(false)
    } else {
      onFinish(resultsRef.current)
    }
  }

  function selectOption(index: number) {
    if (selected !== null) return
    setSelected(index)
    const correct = index === question.answerIndex
    finishQuestion(correct, question.options[index])
    advanceTimer.current = setTimeout(advance, 900)
  }

  function submitSpell() {
    if (spellSubmitted) return
    setSpellSubmitted(true)
    const correct = normalize(spellInput) === normalize(question.card.concept)
    finishQuestion(correct, spellInput)
  }

  const lastCorrect = resultsRef.current[resultsRef.current.length - 1]?.correct === true

  return (
    <div className="min-h-screen flex flex-col bg-appbg">
      <StudyHeader
        title={title}
        progressText={`${current + 1} / ${questions.length}`}
        progress={(current + 1) / questions.length}
        onClose={onClose}
      />

      <div className="flex-1 overflow-y-auto p-5 flex flex-col gap-5">
        {/* 의미 카드 */}
        <div className="card p-6 min-h-[160px] flex flex-col items-center justify-center text-center">
          <span className="text-xs font-bold text-apppurple">의미</span>
          <p className="text-xl font-semibold mt-3">{question.card.meaning}</p>
        </div>

        {question.kind === 'recall' ? (
          <div className="flex flex-col gap-2.5">
            <p className="text-center text-xs text-gray-500">알맞은 개념을 고르세요</p>
            {question.options.map((option, index) => {
              const isAnswer = index === question.answerIndex
              const isSelected = index === selected
              let bg = 'bg-white'
              let border = 'border-black/10'
              if (selected !== null) {
                if (isAnswer) { bg = 'bg-appgreen/[0.12]'; border = 'border-appgreen' }
                else if (isSelected) { bg = 'bg-appred/[0.12]'; border = 'border-appred' }
                else { border = 'border-black/5' }
              }
              return (
                <button
                  key={index}
                  disabled={selected !== null}
                  onClick={() => selectOption(index)}
                  className={`flex items-center justify-between p-4 rounded-xl border ${bg} ${border} text-left transition`}
                >
                  <span className="font-medium">{option}</span>
                  {selected !== null && isAnswer && <CheckCircle2 size={20} className="text-appgreen" />}
                  {selected !== null && isSelected && !isAnswer && <XCircle size={20} className="text-appred" />}
                </button>
              )
            })}
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            {spellSubmitted ? (
              <>
                <div className={`p-5 rounded-xl text-center ${lastCorrect ? 'bg-appgreen/[0.08]' : 'bg-appred/[0.08]'}`}>
                  <p className={`font-semibold ${lastCorrect ? 'text-appgreen' : 'text-appred'}`}>
                    {lastCorrect ? '정답이에요!' : '아쉬워요'}
                  </p>
                  {!lastCorrect && (
                    <p className="text-sm text-gray-500 mt-1">
                      내 답: {spellInput.trim() === '' ? '(입력 없음)' : spellInput}
                    </p>
                  )}
                  <p className="text-xl font-bold mt-1">정답: {question.card.concept}</p>
                </div>
                <button onClick={advance} className="w-full py-3.5 rounded-[14px] font-semibold text-white bg-primary">
                  {current + 1 === questions.length ? '결과 보기' : '다음'}
                </button>
              </>
            ) : (
              <>
                <p className="text-center text-xs text-gray-500">개념을 직접 입력하세요</p>
                <form
                  onSubmit={(e) => { e.preventDefault(); submitSpell() }}
                  className="flex flex-col gap-3"
                >
                  <input
                    ref={inputRef}
                    className="input-field"
                    placeholder="정답 입력"
                    autoCapitalize="none"
                    autoCorrect="off"
                    value={spellInput}
                    onChange={(e) => setSpellInput(e.target.value)}
                  />
                  <button type="submit" className="w-full py-3.5 rounded-[14px] font-semibold text-white bg-primary">
                    제출
                  </button>
                </form>
              </>
            )}
          </div>
        )}
      </div>
    </div>
  )
}

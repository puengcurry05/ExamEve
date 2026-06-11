import { useEffect, useMemo, useRef, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { Star, CheckCircle2, RotateCcw, BookOpen, Pencil } from 'lucide-react'
import { cards as fetchCards, fetchDeck, wrongEntries, recordStudySession } from '../../lib/data'
import type { Card, WrongAnswerEntry } from '../../lib/types'
import { FullScreenLoading } from '../../components/ui'
import {
  recallQuestions, spellQuestions, testQuestions,
  type QuestionResult, type StudyQuestion,
} from './builder'
import QuestionPlayer from './QuestionPlayer'
import StudyResult from './StudyResult'
import MemorizeView from './MemorizeView'
import WrongAnswersView from './WrongAnswersView'

type Mode = 'memorize' | 'recall' | 'spell' | 'test' | 'wrong'

export default function StudyRunner() {
  const { mode = '', deckId = '' } = useParams()
  const navigate = useNavigate()
  const [title, setTitle] = useState('')
  const [cards, setCards] = useState<Card[]>([])
  const [wrong, setWrong] = useState<WrongAnswerEntry[]>([])
  const [loaded, setLoaded] = useState(false)
  const sessionStart = useRef<number>(Date.now())

  const m = mode as Mode

  useEffect(() => {
    void (async () => {
      const deck = await fetchDeck(deckId)
      setTitle(deck?.name ?? '')
      if (m === 'wrong') {
        setWrong(await wrongEntries(deckId))
      } else {
        setCards(await fetchCards(deckId))
      }
      sessionStart.current = Date.now()
      setLoaded(true)
    })()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [deckId, m])

  function record(modeName: string) {
    const duration = Math.floor((Date.now() - sessionStart.current) / 1000)
    void recordStudySession(duration, modeName)
  }

  function close() {
    navigate(-1)
  }

  if (!loaded) {
    return <div className="min-h-screen"><FullScreenLoading /></div>
  }

  if (m === 'memorize') {
    return (
      <MemorizeView
        title={title}
        cards={cards}
        onClose={() => { record('memorize'); close() }}
      />
    )
  }

  if (m === 'wrong') {
    return <WrongAnswersView entries={wrong} onClose={close} />
  }

  if (m === 'recall' || m === 'spell') {
    return (
      <QuizFlow
        kind={m}
        title={title}
        cards={cards}
        onRecordFinish={() => record(m)}
        onResetTimer={() => (sessionStart.current = Date.now())}
        onClose={close}
      />
    )
  }

  if (m === 'test') {
    return (
      <TestFlow
        title={title}
        cards={cards}
        onRecordFinish={() => record('test')}
        onResetTimer={() => (sessionStart.current = Date.now())}
        onClose={close}
      />
    )
  }

  return null
}

// ── 리콜/스펠 흐름 ──────────────────────────────────────
function QuizFlow({
  kind, title, cards, onRecordFinish, onResetTimer, onClose,
}: {
  kind: 'recall' | 'spell'
  title: string
  cards: Card[]
  onRecordFinish: () => void
  onResetTimer: () => void
  onClose: () => void
}) {
  const build = (cs: Card[]) => (kind === 'recall' ? recallQuestions(cs) : spellQuestions(cs))
  const [questions, setQuestions] = useState<StudyQuestion[]>(() => build(cards))
  const [results, setResults] = useState<QuestionResult[] | null>(null)

  if (results) {
    const wrong = results.filter((r) => !r.correct)
    return (
      <StudyResult
        icon={wrong.length === 0 ? CheckCircle2 : kind === 'recall' ? Pencil : BookOpen}
        iconColor={wrong.length === 0 ? '#23B574' : '#4255FF'}
        headline={
          wrong.length === 0
            ? kind === 'recall' ? '모두 맞혔어요!' : '스펠링 완벽!'
            : kind === 'recall' ? '조금 더 연습해볼까요?' : '한 번 더 연습해봐요'
        }
        score={null}
        correctCount={results.filter((r) => r.correct).length}
        total={results.length}
        wrongResults={wrong}
        savedToWrongNote={kind === 'recall' && wrong.length > 0}
        onRetry={() => { onResetTimer(); setQuestions(build(cards)); setResults(null) }}
        onRetryWrong={
          wrong.length === 0
            ? null
            : () => { onResetTimer(); setQuestions(build(wrong.map((w) => w.question.card))); setResults(null) }
        }
        onClose={onClose}
      />
    )
  }

  return (
    <QuestionPlayer
      title={title}
      questions={questions}
      wrongMode={kind === 'recall' ? 'recall' : null}
      onClose={onClose}
      onFinish={(r) => { onRecordFinish(); setResults(r) }}
    />
  )
}

// ── 테스트 흐름 (문항 수 선택 → 플레이 → 결과) ─────────
function TestFlow({
  title, cards, onRecordFinish, onResetTimer, onClose,
}: {
  title: string
  cards: Card[]
  onRecordFinish: () => void
  onResetTimer: () => void
  onClose: () => void
}) {
  const availableCounts = useMemo(() => {
    const steps = [10, 20, 30, 50].filter((s) => s <= cards.length)
    if (cards.length % 10 !== 0) steps.push(cards.length)
    return steps.length > 0 ? steps : [cards.length]
  }, [cards.length])

  const [phase, setPhase] = useState<'setup' | 'playing' | 'result'>('setup')
  const [count, setCount] = useState(availableCounts[0])
  const [questions, setQuestions] = useState<StudyQuestion[]>([])
  const [results, setResults] = useState<QuestionResult[]>([])

  if (phase === 'setup') {
    return (
      <div className="min-h-screen flex flex-col bg-appbg p-6">
        <div className="flex items-center justify-between mb-7">
          <button onClick={onClose} className="text-primary">취소</button>
          <span className="font-bold">테스트 설정</span>
          <span className="w-10" />
        </div>
        <h1 className="text-xl font-bold">문항 수를 선택하세요</h1>
        <p className="text-sm text-gray-500 mt-1">총 카드 수: {cards.length}개</p>

        <div className="flex flex-col gap-2.5 mt-7">
          {availableCounts.map((c) => (
            <button
              key={c}
              onClick={() => setCount(c)}
              className={`flex items-center justify-between p-4 rounded-xl border-[1.5px] transition
                ${count === c ? 'border-primary bg-primary/[0.08]' : 'border-black/10 bg-white'}`}
            >
              <span className="font-semibold">{c}문항</span>
              {count === c && <CheckCircle2 size={20} className="text-primary" />}
            </button>
          ))}
        </div>

        <div className="flex-1" />
        <p className="text-xs text-gray-500 mb-3 whitespace-pre-line">
          {'리콜(4지선다)과 스펠(직접 입력)이 섞여 출제돼요.\n오답은 자동으로 오답 노트에 저장됩니다.'}
        </p>
        <button
          onClick={() => {
            onResetTimer()
            setQuestions(testQuestions(cards, count))
            setResults([])
            setPhase('playing')
          }}
          className="w-full py-3.5 rounded-[14px] font-semibold text-white bg-primary"
        >
          시작
        </button>
      </div>
    )
  }

  if (phase === 'playing') {
    return (
      <QuestionPlayer
        title={title}
        questions={questions}
        wrongMode="test"
        onClose={onClose}
        onFinish={(r) => { onRecordFinish(); setResults(r); setPhase('result') }}
      />
    )
  }

  // result
  const correct = results.filter((r) => r.correct).length
  const score = Math.round((correct / results.length) * 100)
  const wrong = results.filter((r) => !r.correct)
  return (
    <StudyResult
      icon={score >= 90 ? Star : score >= 70 ? CheckCircle2 : RotateCcw}
      iconColor={score >= 90 ? '#FFCD42' : score >= 70 ? '#23B574' : '#FF9040'}
      headline={score >= 90 ? '훌륭해요!' : score >= 70 ? '잘 했어요!' : '더 열심히 해봐요!'}
      score={score}
      correctCount={correct}
      total={results.length}
      wrongResults={wrong}
      savedToWrongNote={wrong.length > 0}
      onRetry={() => setPhase('setup')}
      onRetryWrong={
        wrong.length === 0
          ? null
          : () => {
              onResetTimer()
              setQuestions(testQuestions(wrong.map((w) => w.question.card), wrong.length))
              setResults([])
              setPhase('playing')
            }
      }
      onClose={onClose}
    />
  )
}

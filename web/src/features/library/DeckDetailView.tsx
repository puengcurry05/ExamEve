import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import {
  MoreHorizontal, Pencil, Share, Trash2, Layers, ListChecks,
  Keyboard, FileText, AlertTriangle, Globe, Building2,
  type LucideIcon,
} from 'lucide-react'
import {
  fetchDeck, cards as fetchCards, wrongEntries, deleteDeck, setSharing,
} from '../../lib/data'
import { koreanMessage } from '../../lib/korean'
import type { Card, Deck, WrongAnswerEntry } from '../../lib/types'
import { useAuth } from '../../state/AuthContext'
import { FullScreenLoading, TagChip } from '../../components/ui'
import { TopBar } from '../../components/shared'
import DeckEditorModal from './DeckEditorModal'

export default function DeckDetailView() {
  const { id = '' } = useParams()
  const navigate = useNavigate()
  const [deck, setDeck] = useState<Deck | null>(null)
  const [cards, setCards] = useState<Card[]>([])
  const [wrong, setWrong] = useState<WrongAnswerEntry[]>([])
  const [loaded, setLoaded] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [notice, setNotice] = useState<string | null>(null)
  const [showEditor, setShowEditor] = useState(false)
  const [showShare, setShowShare] = useState(false)
  const [showMenu, setShowMenu] = useState(false)

  async function load() {
    try {
      const d = await fetchDeck(id)
      if (d) setDeck(d)
      setCards(await fetchCards(id))
      setWrong(await wrongEntries(id))
      setLoaded(true)
    } catch (e) {
      setError(koreanMessage(e))
    }
  }

  useEffect(() => {
    void load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id])

  if (!deck) {
    return (
      <div>
        <TopBar title="" back />
        <div className="h-[70vh]">
          <FullScreenLoading />
        </div>
        {error && <p className="px-4 text-xs text-appred">{error}</p>}
      </div>
    )
  }

  function study(mode: string, minCards: number, emptyMsg: string) {
    if (cards.length < minCards) {
      setNotice(emptyMsg)
      return
    }
    navigate(`/study/${mode}/${id}`)
  }

  const modes = [
    { key: 'memorize', icon: Layers, color: '#4255FF', title: '암기', sub: '카드 넘기며 외우기', min: 1, msg: '카드가 없어요. 먼저 카드를 추가해주세요.' },
    { key: 'recall', icon: ListChecks, color: '#7C5CFF', title: '리콜', sub: '4지선다 퀴즈', min: 4, msg: '리콜 모드는 카드가 4개 이상일 때 사용할 수 있어요.' },
    { key: 'spell', icon: Keyboard, color: '#18AEBC', title: '스펠', sub: '직접 입력하기', min: 1, msg: '카드가 없어요. 먼저 카드를 추가해주세요.' },
    { key: 'test', icon: FileText, color: '#FF9040', title: '테스트', sub: '100점 만점 시험', min: 4, msg: '테스트 모드는 카드가 4개 이상일 때 사용할 수 있어요.' },
  ]

  return (
    <div className="min-h-full">
      <TopBar
        title={deck.name}
        back
        trailing={
          <div className="relative">
            <button onClick={() => setShowMenu((v) => !v)} className="text-gray-600">
              <MoreHorizontal size={24} />
            </button>
            {showMenu && (
              <>
                <div className="fixed inset-0 z-30" onClick={() => setShowMenu(false)} />
                <div className="absolute right-0 mt-1 w-40 bg-white rounded-xl shadow-dropdown border border-black/5 z-40 overflow-hidden">
                  <MenuItem icon={<Pencil size={16} />} label="덱 편집" onClick={() => { setShowMenu(false); setShowEditor(true) }} />
                  <MenuItem icon={<Share size={16} />} label="공유하기" onClick={() => { setShowMenu(false); setShowShare(true) }} />
                  <MenuItem
                    icon={<Trash2 size={16} />}
                    label="덱 삭제"
                    danger
                    onClick={async () => {
                      setShowMenu(false)
                      if (!window.confirm('이 덱을 삭제할까요? 덱에 들어 있는 카드도 모두 삭제돼요.')) return
                      try {
                        await deleteDeck(id)
                        navigate(-1)
                      } catch (e) {
                        setError(koreanMessage(e))
                      }
                    }}
                  />
                </div>
              </>
            )}
          </div>
        }
      />

      <div className="flex flex-col gap-6 p-4">
        {/* 헤더 카드 */}
        <div className="card p-4">
          <div className="flex flex-wrap gap-1.5">
            {deck.subject && <TagChip text={deck.subject} />}
            {deck.unit && <TagChip text={deck.unit} color="#7C5CFF" />}
          </div>
          <div className="flex items-center gap-3 mt-2.5 text-xs text-gray-500">
            <span>카드 {cards.length}개</span>
            {deck.isSharedPublic && (
              <span className="flex items-center gap-1 text-primary">
                <Globe size={13} /> 전체 공유
              </span>
            )}
            {deck.isSharedSchool && (
              <span className="flex items-center gap-1 text-appteal">
                <Building2 size={13} /> 학교 공유
              </span>
            )}
          </div>
        </div>

        {/* 학습 모드 */}
        <section>
          <h2 className="font-semibold mb-3">학습 모드</h2>
          <div className="grid grid-cols-2 gap-3">
            {modes.map((m) => (
              <ModeButton
                key={m.key}
                icon={m.icon}
                color={m.color}
                title={m.title}
                sub={m.sub}
                onClick={() => study(m.key, m.min, m.msg)}
              />
            ))}
            <ModeButton
              icon={AlertTriangle}
              color="#FF5C5C"
              title="오답"
              sub={wrong.length === 0 ? '틀린 카드 없음' : `틀린 카드 ${wrong.length}개`}
              onClick={() => {
                if (wrong.length === 0) {
                  setNotice('아직 오답이 없어요. 리콜이나 테스트에서 틀린 카드가 자동으로 모여요.')
                  return
                }
                navigate(`/study/wrong/${id}`)
              }}
            />
          </div>
        </section>

        {/* 카드 목록 */}
        <section>
          <h2 className="font-semibold mb-3">카드 목록</h2>
          {cards.length === 0 && loaded ? (
            <div className="card p-4 text-sm text-gray-500">
              카드가 없어요. 우측 상단 메뉴에서 덱을 편집해 카드를 추가해보세요.
            </div>
          ) : (
            <div className="flex flex-col gap-3">
              {cards.map((c) => (
                <div key={c.id} className="card p-3.5 flex items-start gap-3">
                  <span className="flex-1 text-sm font-semibold">{c.concept}</span>
                  <span className="w-px self-stretch bg-black/10" />
                  <span className="flex-1 text-sm text-gray-500">{c.meaning}</span>
                </div>
              ))}
            </div>
          )}
        </section>
      </div>

      {notice && <Toast message={notice} onClose={() => setNotice(null)} />}
      {error && <Toast message={error} onClose={() => setError(null)} />}

      {showEditor && (
        <DeckEditorModal
          mode={{ kind: 'edit', deck, cards }}
          onClose={() => setShowEditor(false)}
          onSaved={() => { setShowEditor(false); void load() }}
        />
      )}
      {showShare && <ShareDeckModal deck={deck} onClose={() => setShowShare(false)} onSaved={() => { setShowShare(false); void load() }} />}
    </div>
  )
}

function ModeButton({
  icon: Icon, color, title, sub, onClick,
}: {
  icon: LucideIcon
  color: string
  title: string
  sub: string
  onClick: () => void
}) {
  return (
    <button onClick={onClick} className="card p-3.5 text-left active:scale-[0.98] transition">
      <div
        className="w-10 h-10 rounded-[10px] flex items-center justify-center"
        style={{ backgroundColor: `${color}1F` }}
      >
        <Icon size={20} color={color} />
      </div>
      <div className="font-semibold mt-2">{title}</div>
      <div className="text-xs text-gray-500 truncate">{sub}</div>
    </button>
  )
}

function MenuItem({
  icon, label, onClick, danger = false,
}: {
  icon: React.ReactNode
  label: string
  onClick: () => void
  danger?: boolean
}) {
  return (
    <button
      onClick={onClick}
      className={`w-full flex items-center gap-2 px-3.5 py-2.5 text-sm hover:bg-gray-50 ${danger ? 'text-appred' : ''}`}
    >
      {icon} {label}
    </button>
  )
}

function Toast({ message, onClose }: { message: string; onClose: () => void }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30 px-8" onClick={onClose}>
      <div className="bg-white rounded-2xl p-5 max-w-xs w-full text-center" onClick={(e) => e.stopPropagation()}>
        <p className="text-sm">{message}</p>
        <button onClick={onClose} className="mt-4 w-full py-2.5 rounded-xl bg-primary text-white font-semibold">
          확인
        </button>
      </div>
    </div>
  )
}

function ShareDeckModal({ deck, onClose, onSaved }: { deck: Deck; onClose: () => void; onSaved: () => void }) {
  const { profile } = useAuth()
  const hasSchool = profile?.schoolId != null
  const [isPublic, setIsPublic] = useState(deck.isSharedPublic)
  const [isSchool, setIsSchool] = useState(deck.isSharedSchool)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function save() {
    setBusy(true)
    setError(null)
    try {
      await setSharing({
        deckId: deck.id,
        isPublic,
        isSchool: isSchool && hasSchool,
        schoolId: profile?.schoolId ?? null,
      })
      onSaved()
    } catch (e) {
      setError(koreanMessage(e))
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 bg-black/30 flex items-end justify-center" onClick={onClose}>
      <div className="w-full max-w-[480px] bg-appbg rounded-t-2xl p-5 flex flex-col gap-5" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between">
          <button onClick={onClose} className="text-primary">취소</button>
          <span className="font-bold">공유하기</span>
          <span className="w-8" />
        </div>

        <ToggleRow
          icon={<Globe size={18} />}
          title="일반 공유"
          desc="모든 사용자가 공유 탭에서 볼 수 있어요."
          checked={isPublic}
          onChange={setIsPublic}
        />
        <ToggleRow
          icon={<Building2 size={18} />}
          title="학교 공유"
          desc={hasSchool ? `${profile?.school?.name ?? '내 학교'} 친구들만 볼 수 있어요.` : '프로필에서 학교를 설정하면 사용할 수 있어요.'}
          checked={isSchool && hasSchool}
          disabled={!hasSchool}
          onChange={setIsSchool}
        />

        {error && <p className="text-xs text-appred">{error}</p>}

        <div className="pb-2">
          <PrimaryButtonInline title="저장" busy={busy} onClick={() => void save()} />
        </div>
      </div>
    </div>
  )
}

function ToggleRow({
  icon, title, desc, checked, onChange, disabled = false,
}: {
  icon: React.ReactNode
  title: string
  desc: string
  checked: boolean
  onChange: (v: boolean) => void
  disabled?: boolean
}) {
  return (
    <button
      onClick={() => !disabled && onChange(!checked)}
      disabled={disabled}
      className={`flex items-start gap-3 text-left ${disabled ? 'opacity-50' : ''}`}
    >
      <div className="flex-1">
        <div className="font-semibold flex items-center gap-1.5">{icon} {title}</div>
        <div className="text-xs text-gray-500 mt-0.5">{desc}</div>
      </div>
      <span
        className={`w-12 h-7 rounded-full transition relative shrink-0 ${checked ? 'bg-appgreen' : 'bg-gray-300'}`}
      >
        <span
          className={`absolute top-0.5 w-6 h-6 bg-white rounded-full shadow transition-all ${checked ? 'left-[22px]' : 'left-0.5'}`}
        />
      </span>
    </button>
  )
}

function PrimaryButtonInline({ title, busy, onClick }: { title: string; busy: boolean; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      disabled={busy}
      className="w-full py-3.5 rounded-[14px] font-semibold text-white bg-primary disabled:bg-gray-400/60"
    >
      {busy ? '저장 중…' : title}
    </button>
  )
}

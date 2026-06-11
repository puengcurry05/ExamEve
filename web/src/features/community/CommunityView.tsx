import { useEffect, useMemo, useState } from 'react'
import { ArrowUpDown, ArrowDownToLine, Check, Building2, Inbox, Search } from 'lucide-react'
import { publicDecks, schoolDecks, myDecks, downloadDeck } from '../../lib/data'
import { koreanMessage } from '../../lib/korean'
import type { Deck } from '../../lib/types'
import { useAuth } from '../../state/AuthContext'
import { FullScreenLoading, TagChip } from '../../components/ui'
import { TopBar } from '../../components/shared'

type Tab = 'general' | 'school'
type Sort = 'latest' | 'popular'

export default function CommunityView() {
  const { profile } = useAuth()
  const hasSchool = profile?.schoolId != null
  const schoolName = profile?.school?.name ?? '학교'

  const [tab, setTab] = useState<Tab>('general')
  const [general, setGeneral] = useState<Deck[]>([])
  const [school, setSchool] = useState<Deck[]>([])
  const [downloadedIds, setDownloadedIds] = useState<Set<string>>(new Set())
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [sort, setSort] = useState<Sort>('latest')
  const [sortMenu, setSortMenu] = useState(false)
  const [downloadingId, setDownloadingId] = useState<string | null>(null)
  const [justDownloaded, setJustDownloaded] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  async function load() {
    setLoading(true)
    try {
      const [pub, mine] = await Promise.all([publicDecks(), myDecks()])
      setGeneral(pub)
      setDownloadedIds(new Set(mine.map((d) => d.sourceDeckId).filter(Boolean) as string[]))
      if (hasSchool && profile?.schoolId) {
        setSchool(await schoolDecks(profile.schoolId))
      }
    } catch (e) {
      setError(koreanMessage(e))
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const activeDecks = useMemo(() => {
    const source = tab === 'general' ? general : school
    const q = search.trim().toLowerCase()
    const filtered = q
      ? source.filter(
          (d) =>
            d.name.toLowerCase().includes(q) ||
            d.subject.toLowerCase().includes(q) ||
            d.unit.toLowerCase().includes(q) ||
            d.ownerNickname.toLowerCase().includes(q)
        )
      : source
    return sort === 'popular' ? [...filtered].sort((a, b) => b.downloadedCount - a.downloadedCount) : filtered
  }, [tab, general, school, search, sort])

  async function download(deck: Deck) {
    setDownloadingId(deck.id)
    try {
      await downloadDeck(deck.id)
      setJustDownloaded(deck.id)
      setDownloadedIds((s) => new Set(s).add(deck.id))
      const bump = (list: Deck[]) =>
        list.map((d) => (d.id === deck.id ? { ...d, downloadedCount: d.downloadedCount + 1 } : d))
      if (tab === 'general') setGeneral(bump)
      else setSchool(bump)
      setTimeout(() => setJustDownloaded((id) => (id === deck.id ? null : id)), 2000)
    } catch (e) {
      setError(koreanMessage(e))
    } finally {
      setDownloadingId(null)
    }
  }

  return (
    <div className="min-h-full">
      <TopBar
        title="공유"
        large
        trailing={
          <div className="relative">
            <button onClick={() => setSortMenu((v) => !v)} className="text-primary">
              <ArrowUpDown size={22} />
            </button>
            {sortMenu && (
              <>
                <div className="fixed inset-0 z-30" onClick={() => setSortMenu(false)} />
                <div className="absolute right-0 mt-1 w-32 bg-white rounded-xl shadow-dropdown border border-black/5 z-40 overflow-hidden">
                  {(['latest', 'popular'] as Sort[]).map((s) => (
                    <button
                      key={s}
                      onClick={() => { setSort(s); setSortMenu(false) }}
                      className="w-full flex items-center justify-between px-3.5 py-2.5 text-sm hover:bg-gray-50"
                    >
                      {s === 'latest' ? '최신 순' : '인기 순'}
                      {sort === s && <Check size={16} className="text-primary" />}
                    </button>
                  ))}
                </div>
              </>
            )}
          </div>
        }
      />

      {/* 검색 */}
      <div className="px-4 pb-2">
        <div className="flex items-center gap-2 px-3.5 py-2.5 bg-white rounded-xl border border-black/10">
          <Search size={18} className="text-gray-400" />
          <input
            className="flex-1 outline-none bg-transparent text-sm placeholder:text-gray-400"
            placeholder="덱 이름, 과목, 닉네임 검색"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
      </div>

      {/* 탭 */}
      <div className="flex px-4">
        {(['general', 'school'] as Tab[]).map((t) => {
          const disabled = t === 'school' && !hasSchool
          const active = tab === t
          return (
            <button
              key={t}
              disabled={disabled}
              onClick={() => setTab(t)}
              className="flex-1 flex flex-col items-center gap-1 pt-1"
            >
              <span
                className={`text-sm ${active ? 'font-bold text-primary' : disabled ? 'text-gray-300' : 'text-gray-700'}`}
              >
                {t === 'school' && hasSchool ? schoolName : t === 'general' ? '일반' : '학교'}
              </span>
              <span className={`h-0.5 w-full ${active && !disabled ? 'bg-primary' : 'bg-transparent'}`} />
            </button>
          )
        })}
      </div>

      {/* 콘텐츠 */}
      {tab === 'school' && !hasSchool ? (
        <SchoolPrompt />
      ) : loading && activeDecks.length === 0 ? (
        <div className="h-[60vh]"><FullScreenLoading /></div>
      ) : activeDecks.length === 0 ? (
        <Empty searching={search.trim() !== ''} />
      ) : (
        <div className="flex flex-col gap-3 p-4">
          {activeDecks.map((deck) => (
            <CommunityRow
              key={deck.id}
              deck={deck}
              downloading={downloadingId === deck.id}
              justDownloaded={justDownloaded === deck.id}
              alreadyDownloaded={downloadedIds.has(deck.id)}
              onDownload={() => void download(deck)}
            />
          ))}
        </div>
      )}

      {error && <p className="px-4 text-xs text-appred">{error}</p>}
    </div>
  )
}

function CommunityRow({
  deck, downloading, justDownloaded, alreadyDownloaded, onDownload,
}: {
  deck: Deck
  downloading: boolean
  justDownloaded: boolean
  alreadyDownloaded: boolean
  onDownload: () => void
}) {
  const done = justDownloaded || alreadyDownloaded
  return (
    <div className="card p-4">
      <div className="flex items-start justify-between gap-3">
        <div>
          <div className="font-semibold line-clamp-2">{deck.name}</div>
          <div className="text-xs text-gray-500 mt-1">by {deck.ownerNickname}</div>
        </div>
        <button
          onClick={onDownload}
          disabled={downloading || done}
          className={`w-9 h-9 rounded-full flex items-center justify-center text-white shrink-0 transition
            ${alreadyDownloaded ? 'bg-appgreen/80' : justDownloaded ? 'bg-appgreen' : 'bg-primary'}`}
        >
          {downloading ? (
            <span className="w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin" />
          ) : done ? (
            <Check size={18} />
          ) : (
            <ArrowDownToLine size={18} />
          )}
        </button>
      </div>
      <div className="flex flex-wrap gap-1.5 mt-2.5">
        {deck.subject && <TagChip text={deck.subject} />}
        {deck.unit && <TagChip text={deck.unit} color="#7C5CFF" />}
      </div>
      <div className="flex items-center gap-3 mt-2.5 text-xs text-gray-500">
        <span>카드 {deck.cardCount}개</span>
        <span className="flex items-center gap-1"><ArrowDownToLine size={12} /> {deck.downloadedCount}</span>
      </div>
    </div>
  )
}

function SchoolPrompt() {
  return (
    <div className="flex flex-col items-center justify-center h-[60vh] gap-3 px-8 text-center">
      <Building2 size={48} className="text-gray-400" />
      <h2 className="font-semibold">학교를 설정해주세요</h2>
      <p className="text-sm text-gray-500">
        프로필에서 학교를 입력하면
        <br />
        우리 학교 친구들이 공유한 덱을 볼 수 있어요.
      </p>
    </div>
  )
}

function Empty({ searching }: { searching: boolean }) {
  return (
    <div className="flex flex-col items-center justify-center h-[60vh] gap-3 text-gray-400">
      <Inbox size={48} />
      <h2 className="font-semibold text-gray-600">{searching ? '검색 결과가 없어요' : '아직 공유된 덱이 없어요'}</h2>
    </div>
  )
}

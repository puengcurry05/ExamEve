import { useEffect, useState } from 'react'
import { Plus, BookMarked } from 'lucide-react'
import { myDecks } from '../../lib/data'
import { koreanMessage } from '../../lib/korean'
import type { Deck } from '../../lib/types'
import { FullScreenLoading } from '../../components/ui'
import { TopBar, DeckRow } from '../../components/shared'
import DeckEditorModal from './DeckEditorModal'

export default function LibraryView() {
  const [decks, setDecks] = useState<Deck[]>([])
  const [loading, setLoading] = useState(true)
  const [loaded, setLoaded] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [showCreate, setShowCreate] = useState(false)

  async function load() {
    setLoading(true)
    try {
      setDecks(await myDecks())
      setLoaded(true)
    } catch (e) {
      setError(koreanMessage(e))
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  return (
    <div className="min-h-full">
      <TopBar
        title="학습함"
        large
        trailing={
          <button onClick={() => setShowCreate(true)} className="text-primary">
            <Plus size={26} />
          </button>
        }
      />

      {loading && !loaded ? (
        <div className="h-[70vh]">
          <FullScreenLoading />
        </div>
      ) : decks.length === 0 && loaded ? (
        <EmptyState onCreate={() => setShowCreate(true)} />
      ) : (
        <div className="flex flex-col gap-3 p-4">
          {decks.map((d) => (
            <DeckRow key={d.id} deck={d} />
          ))}
        </div>
      )}

      {error && <p className="px-4 text-xs text-appred">{error}</p>}

      {showCreate && (
        <DeckEditorModal
          mode={{ kind: 'create' }}
          onClose={() => setShowCreate(false)}
          onSaved={() => {
            setShowCreate(false)
            void load()
          }}
        />
      )}
    </div>
  )
}

function EmptyState({ onCreate }: { onCreate: () => void }) {
  return (
    <div className="flex flex-col items-center justify-center h-[70vh] gap-3 px-8 text-center">
      <BookMarked size={48} className="text-gray-400" />
      <h2 className="font-semibold">아직 덱이 없어요</h2>
      <p className="text-sm text-gray-500">
        첫 덱을 만들거나 공유 탭에서
        <br />
        친구들의 덱을 다운로드해보세요!
      </p>
      <button
        onClick={onCreate}
        className="mt-2 px-5 py-2.5 rounded-xl bg-primary text-white font-semibold inline-flex items-center gap-1.5"
      >
        <Plus size={18} /> 덱 만들기
      </button>
    </div>
  )
}

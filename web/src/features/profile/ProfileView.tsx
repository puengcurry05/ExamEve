import { useEffect, useRef, useState } from 'react'
import { Pencil, Building2, LogOut, Camera, ImageOff, Check } from 'lucide-react'
import { myDecks, currentUid, updateNickname, updateAvatarColor, uploadAvatar, updateSchool } from '../../lib/data'
import { koreanMessage } from '../../lib/korean'
import { PROFILE_COLORS, PROFILE_COLOR_KEYS, resolveProfileColor } from '../../lib/theme'
import type { Deck, School } from '../../lib/types'
import { deckIsShared } from '../../lib/types'
import { useAuth } from '../../state/AuthContext'
import { PrimaryButton, RoundedField } from '../../components/ui'
import { TopBar, Avatar, DeckRow } from '../../components/shared'
import SchoolSearchField from '../auth/SchoolSearchField'

export default function ProfileView() {
  const { profile, refreshProfile, signOut } = useAuth()
  const [shared, setShared] = useState<Deck[]>([])
  const [downloaded, setDownloaded] = useState<Deck[]>([])
  const [showProfileEditor, setShowProfileEditor] = useState(false)
  const [showSchoolEditor, setShowSchoolEditor] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function loadDecks() {
    try {
      const uid = await currentUid()
      if (!uid) return
      const all = await myDecks()
      setShared(all.filter((d) => deckIsShared(d) && d.userId === uid))
      setDownloaded(all.filter((d) => d.sourceDeckId != null))
    } catch (e) {
      setError(koreanMessage(e))
    }
  }

  useEffect(() => {
    void loadDecks()
  }, [])

  return (
    <div className="min-h-full">
      <TopBar title="프로필" large />

      <div className="flex flex-col gap-5 p-4">
        {/* 프로필 카드 */}
        <div className="card p-5 flex flex-col items-center gap-4">
          <Avatar url={profile?.avatarUrl} colorKey={profile?.avatarColor} size={80} />
          <div className="text-center">
            <div className="text-lg font-bold">{profile?.nickname}</div>
            {profile?.school ? (
              <div className="text-sm text-gray-500 flex items-center justify-center gap-1 mt-0.5">
                <Building2 size={14} /> {profile.school.name}
              </div>
            ) : (
              <div className="text-sm text-gray-500 mt-0.5">학교 미설정</div>
            )}
          </div>
          <div className="flex gap-3 w-full">
            <button
              onClick={() => setShowProfileEditor(true)}
              className="flex-1 py-2.5 rounded-[10px] bg-primary/10 text-primary font-semibold text-sm flex items-center justify-center gap-1.5"
            >
              <Pencil size={15} /> 프로필 수정
            </button>
            <button
              onClick={() => setShowSchoolEditor(true)}
              className="flex-1 py-2.5 rounded-[10px] bg-appteal/10 text-appteal font-semibold text-sm flex items-center justify-center gap-1.5"
            >
              <Building2 size={15} /> 학교 수정
            </button>
          </div>
        </div>

        {/* 내가 공유한 덱 */}
        <Section title="내가 공유한 덱" decks={shared} emptyText="공유한 덱이 없어요." />
        {/* 다운로드한 덱 */}
        <Section title="다운로드한 덱" decks={downloaded} emptyText="다운로드한 덱이 없어요." />

        {error && <p className="text-xs text-appred">{error}</p>}

        <button
          onClick={() => {
            if (window.confirm('로그아웃할까요?')) void signOut()
          }}
          className="w-full py-3.5 rounded-xl bg-appred/[0.08] text-appred font-semibold flex items-center justify-center gap-1.5"
        >
          <LogOut size={18} /> 로그아웃
        </button>
      </div>

      {showProfileEditor && (
        <ProfileEditorModal
          onClose={() => setShowProfileEditor(false)}
          onSaved={() => { setShowProfileEditor(false); void refreshProfile() }}
        />
      )}
      {showSchoolEditor && (
        <SchoolEditorModal
          onClose={() => setShowSchoolEditor(false)}
          onSaved={() => { setShowSchoolEditor(false); void refreshProfile() }}
        />
      )}
    </div>
  )
}

function Section({ title, decks, emptyText }: { title: string; decks: Deck[]; emptyText: string }) {
  return (
    <section>
      <h2 className="font-semibold mb-3 px-1">{title}</h2>
      {decks.length === 0 ? (
        <div className="card p-4 text-sm text-gray-500">{emptyText}</div>
      ) : (
        <div className="flex flex-col gap-3">
          {decks.map((d) => (
            <DeckRow key={d.id} deck={d} />
          ))}
        </div>
      )}
    </section>
  )
}

// ── 프로필 편집 모달 ────────────────────────────────────
type AvatarMode = 'color' | 'existingPhoto' | 'newPhoto'

function ProfileEditorModal({ onClose, onSaved }: { onClose: () => void; onSaved: () => void }) {
  const { profile } = useAuth()
  const [nickname, setNickname] = useState(profile?.nickname ?? '')
  const [colorKey, setColorKey] = useState(profile?.avatarColor ?? 'sky')
  const [mode, setMode] = useState<AvatarMode>(profile?.avatarUrl ? 'existingPhoto' : 'color')
  const [pendingFile, setPendingFile] = useState<File | null>(null)
  const [pendingPreview, setPendingPreview] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const fileInput = useRef<HTMLInputElement>(null)

  function pickFile(file: File) {
    setPendingFile(file)
    setPendingPreview(URL.createObjectURL(file))
    setMode('newPhoto')
  }

  async function save() {
    setBusy(true)
    setError(null)
    try {
      await updateNickname(nickname.trim())
      if (mode === 'color') {
        await updateAvatarColor(colorKey)
      } else if (mode === 'newPhoto' && pendingFile) {
        await uploadAvatar(pendingFile)
      }
      onSaved()
    } catch (e) {
      setError(koreanMessage(e))
    } finally {
      setBusy(false)
    }
  }

  const previewUrl =
    mode === 'newPhoto' ? pendingPreview : mode === 'existingPhoto' ? profile?.avatarUrl ?? null : null

  return (
    <Sheet title="프로필 수정" onClose={onClose}>
      <div className="flex flex-col items-center gap-5 p-5">
        {/* 미리보기 */}
        <div className="relative">
          <div
            className="w-[90px] h-[90px] rounded-full bg-cover bg-center"
            style={{
              backgroundColor: resolveProfileColor(colorKey),
              backgroundImage: previewUrl ? `url(${previewUrl})` : undefined,
            }}
          />
          <button
            onClick={() => fileInput.current?.click()}
            className="absolute bottom-0 right-0 w-7 h-7 rounded-full bg-gray-800 text-white flex items-center justify-center"
          >
            <Camera size={13} />
          </button>
          <input
            ref={fileInput}
            type="file"
            accept="image/*"
            className="hidden"
            onChange={(e) => {
              const f = e.target.files?.[0]
              if (f) pickFile(f)
            }}
          />
        </div>

        {/* 색상 팔레트 */}
        <div className="w-full">
          <p className="text-xs font-semibold text-gray-500 mb-2.5">색상 선택</p>
          <div className="flex justify-between">
            {PROFILE_COLOR_KEYS.map((key) => {
              const selected = mode === 'color' && colorKey === key
              return (
                <button
                  key={key}
                  onClick={() => {
                    setColorKey(key)
                    setPendingFile(null)
                    setPendingPreview(null)
                    setMode('color')
                  }}
                  className="relative w-10 h-10 rounded-full flex items-center justify-center"
                  style={{ backgroundColor: PROFILE_COLORS[key] }}
                >
                  {selected && <Check size={16} className="text-gray-700" />}
                  {selected && (
                    <span className="absolute -inset-1 rounded-full border-2 border-gray-400/40" />
                  )}
                </button>
              )
            })}
          </div>
        </div>

        {(mode === 'existingPhoto' || mode === 'newPhoto') && (
          <button
            onClick={() => {
              setPendingFile(null)
              setPendingPreview(null)
              setMode('color')
            }}
            className="text-sm text-appred flex items-center gap-1"
          >
            <ImageOff size={15} /> 사진 삭제
          </button>
        )}

        <div className="w-full">
          <label className="font-semibold">닉네임</label>
          <div className="mt-2">
            <RoundedField value={nickname} onChange={(e) => setNickname(e.target.value)} placeholder="닉네임" />
          </div>
        </div>

        {error && <p className="text-xs text-appred self-start">{error}</p>}

        <div className="w-full pt-2">
          <PrimaryButton title="저장" disabled={nickname.trim() === ''} busy={busy} onClick={() => void save()} />
        </div>
      </div>
    </Sheet>
  )
}

// ── 학교 편집 모달 ──────────────────────────────────────
function SchoolEditorModal({ onClose, onSaved }: { onClose: () => void; onSaved: () => void }) {
  const { profile } = useAuth()
  const [school, setSchool] = useState<School | null>(profile?.school ?? null)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function save() {
    setBusy(true)
    setError(null)
    try {
      await updateSchool(school?.id ?? null)
      onSaved()
    } catch (e) {
      setError(koreanMessage(e))
    } finally {
      setBusy(false)
    }
  }

  return (
    <Sheet title="학교 수정" onClose={onClose}>
      <div className="flex flex-col gap-4 p-5">
        <div>
          <h2 className="font-semibold">학교 검색</h2>
          <p className="text-xs text-gray-500 mt-1">목록에서 선택해야 저장됩니다. 비워두면 학교 정보가 삭제돼요.</p>
        </div>
        <SchoolSearchField selectedSchool={school} onSelect={setSchool} placeholder="학교 이름으로 검색" />
        {school && (
          <div className="flex items-center gap-2 p-3 rounded-[10px] bg-appteal/[0.08]">
            <Building2 size={16} className="text-appteal" />
            <span className="text-sm font-semibold">{school.name}</span>
            <span className="text-gray-400">·</span>
            <span className="text-xs text-gray-500 flex-1">{school.region}</span>
            <button onClick={() => setSchool(null)} className="text-gray-400">✕</button>
          </div>
        )}
        {error && <p className="text-xs text-appred">{error}</p>}
        <div className="pt-2">
          <PrimaryButton title="저장" busy={busy} onClick={() => void save()} />
        </div>
      </div>
    </Sheet>
  )
}

function Sheet({ title, onClose, children }: { title: string; onClose: () => void; children: React.ReactNode }) {
  return (
    <div className="fixed inset-0 z-50 bg-black/30 flex items-end justify-center" onClick={onClose}>
      <div
        className="w-full max-w-[480px] max-h-[92vh] overflow-y-auto bg-appbg rounded-t-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between px-4 py-3 border-b border-black/5 sticky top-0 bg-appbg">
          <button onClick={onClose} className="text-primary">취소</button>
          <span className="font-bold">{title}</span>
          <span className="w-8" />
        </div>
        {children}
      </div>
    </div>
  )
}

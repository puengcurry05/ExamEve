import { useState } from 'react'
import { createProfile } from '../../lib/data'
import { koreanMessage } from '../../lib/korean'
import { useAuth } from '../../state/AuthContext'
import { PrimaryButton, RoundedField } from '../../components/ui'
import SchoolSearchField from './SchoolSearchField'
import type { School } from '../../lib/types'

export default function OnboardingView() {
  const { refreshProfile } = useAuth()
  const [nickname, setNickname] = useState('')
  const [school, setSchool] = useState<School | null>(null)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function complete() {
    setBusy(true)
    setError(null)
    try {
      await createProfile(nickname.trim(), school?.id ?? null)
      await refreshProfile()
    } catch (e) {
      setError(koreanMessage(e))
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="min-h-screen px-6 overflow-y-auto">
      <div className="pt-16 pb-6">
        <h1 className="text-3xl font-extrabold">거의 다 왔어요!</h1>
        <p className="text-sm text-gray-500 mt-2">친구들에게 보여질 프로필을 만들어주세요.</p>
      </div>

      <div className="flex flex-col gap-6">
        <div>
          <label className="font-semibold">닉네임</label>
          <div className="mt-2">
            <RoundedField
              placeholder="예: 전교일등"
              value={nickname}
              onChange={(e) => setNickname(e.target.value)}
            />
          </div>
        </div>

        <div>
          <label className="font-semibold">학교 (선택)</label>
          <div className="mt-2">
            <SchoolSearchField selectedSchool={school} onSelect={setSchool} />
          </div>
          <p className="text-xs text-gray-500 mt-2">
            학교를 선택하면 우리 학교 친구들이 공유한 덱을 볼 수 있어요. 나중에 프로필에서 바꿀 수 있어요.
          </p>
        </div>

        {error && <p className="text-xs text-appred">{error}</p>}

        <PrimaryButton
          title="시작하기"
          disabled={nickname.trim().length === 0}
          busy={busy}
          onClick={() => void complete()}
        />
      </div>
    </div>
  )
}

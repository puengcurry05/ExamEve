import { useState } from 'react'
import { Moon } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { koreanMessage } from '../../lib/korean'
import { PrimaryButton, RoundedField } from '../../components/ui'

export default function AuthView() {
  const [isSignUp, setIsSignUp] = useState(false)
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const submitDisabled = email.trim().length === 0 || password.length < 6

  async function submit() {
    setBusy(true)
    setError(null)
    try {
      if (isSignUp) {
        const { error } = await supabase.auth.signUp({ email, password })
        if (error) throw error
      } else {
        const { error } = await supabase.auth.signInWithPassword({ email, password })
        if (error) throw error
      }
    } catch (e) {
      setError(koreanMessage(e))
    } finally {
      setBusy(false)
    }
  }

  async function sendReset() {
    const target = window.prompt('가입한 이메일을 입력하면 비밀번호 재설정 링크를 보내드려요.', email)
    if (!target || target.trim().length === 0) return
    try {
      const { error } = await supabase.auth.resetPasswordForEmail(target.trim())
      if (error) throw error
      window.alert(`${target}로 재설정 링크를 보냈어요. 메일함을 확인해주세요.`)
    } catch (e) {
      setError(koreanMessage(e))
    }
  }

  return (
    <div className="min-h-screen flex flex-col px-6 overflow-y-auto">
      <div className="flex flex-col items-center pt-20 pb-10">
        <Moon size={56} className="text-primary fill-primary" />
        <h1 className="text-4xl font-extrabold mt-2">시험전야</h1>
        <p className="text-sm text-gray-500 mt-1">시험 전날 밤, 가장 빠른 암기장</p>
      </div>

      <form
        className="flex flex-col gap-3"
        onSubmit={(e) => {
          e.preventDefault()
          if (!submitDisabled) void submit()
        }}
      >
        <RoundedField
          type="email"
          inputMode="email"
          autoCapitalize="none"
          autoCorrect="off"
          placeholder="이메일"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
        />
        <RoundedField
          type="password"
          placeholder="비밀번호 (6자 이상)"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
        />

        {error && <p className="text-xs text-appred">{error}</p>}

        <div className="pt-1">
          <PrimaryButton
            type="submit"
            title={isSignUp ? '회원가입' : '로그인'}
            disabled={submitDisabled}
            busy={busy}
          />
        </div>

        <div className="flex items-center justify-between pt-1">
          <button
            type="button"
            className="text-sm font-semibold text-primary"
            onClick={() => {
              setIsSignUp((v) => !v)
              setError(null)
            }}
          >
            {isSignUp ? '이미 계정이 있나요? 로그인' : '계정이 없나요? 회원가입'}
          </button>
          {!isSignUp && (
            <button type="button" className="text-sm text-gray-500" onClick={() => void sendReset()}>
              비밀번호 찾기
            </button>
          )}
        </div>
      </form>
    </div>
  )
}

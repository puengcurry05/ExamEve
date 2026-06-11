import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useRef,
  useState,
  type ReactNode,
} from 'react'
import { supabase } from '../lib/supabase'
import { fetchProfile } from '../lib/data'
import { koreanMessage } from '../lib/korean'
import type { Profile } from '../lib/types'

export type Phase = 'loading' | 'signedOut' | 'needsOnboarding' | 'ready' | 'error'

interface AuthState {
  phase: Phase
  profile: Profile | null
  errorMessage: string
  refreshProfile: () => Promise<void>
  signOut: () => Promise<void>
}

const Ctx = createContext<AuthState | null>(null)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [phase, setPhase] = useState<Phase>('loading')
  const [profile, setProfile] = useState<Profile | null>(null)
  const [errorMessage, setErrorMessage] = useState('')
  const profileRef = useRef<Profile | null>(null)
  profileRef.current = profile

  const refreshProfile = useCallback(async () => {
    const { data } = await supabase.auth.getSession()
    const uid = data.session?.user.id
    if (!uid) {
      setProfile(null)
      setPhase('signedOut')
      return
    }
    try {
      const fetched = await fetchProfile(uid)
      if (fetched) {
        setProfile(fetched)
        setPhase('ready')
      } else {
        setPhase('needsOnboarding')
      }
    } catch (e) {
      setErrorMessage(koreanMessage(e))
      setPhase('error')
    }
  }, [])

  const signOut = useCallback(async () => {
    await supabase.auth.signOut()
  }, [])

  useEffect(() => {
    const { data: sub } = supabase.auth.onAuthStateChange((event, session) => {
      if (event === 'INITIAL_SESSION' || event === 'SIGNED_IN') {
        if (!session) {
          setPhase('signedOut')
        } else if (!profileRef.current) {
          void refreshProfile()
        }
      } else if (event === 'SIGNED_OUT') {
        setProfile(null)
        setPhase('signedOut')
      }
    })
    return () => sub.subscription.unsubscribe()
  }, [refreshProfile])

  return (
    <Ctx.Provider value={{ phase, profile, errorMessage, refreshProfile, signOut }}>
      {children}
    </Ctx.Provider>
  )
}

export function useAuth(): AuthState {
  const ctx = useContext(Ctx)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}

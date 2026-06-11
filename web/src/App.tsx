import { Moon } from 'lucide-react'
import { useAuth } from './state/AuthContext'
import { Spinner } from './components/ui'
import AuthView from './features/auth/AuthView'
import OnboardingView from './features/auth/OnboardingView'
import MainTabs from './features/MainTabs'

export default function App() {
  const { phase, errorMessage, refreshProfile } = useAuth()

  return (
    <div className="mx-auto w-full max-w-[480px] min-h-screen bg-appbg relative shadow-sm">
      {phase === 'loading' && (
        <div className="flex flex-col items-center justify-center min-h-screen gap-4">
          <Moon size={48} className="text-primary fill-primary" />
          <h1 className="text-3xl font-extrabold">시험전야</h1>
          <Spinner />
        </div>
      )}

      {phase === 'error' && (
        <div className="flex flex-col items-center justify-center min-h-screen gap-4 px-8 text-center">
          <h2 className="text-lg font-semibold">문제가 발생했어요</h2>
          <p className="text-sm text-gray-500">{errorMessage}</p>
          <button
            onClick={() => void refreshProfile()}
            className="px-5 py-2.5 rounded-xl bg-primary text-white font-semibold"
          >
            다시 시도
          </button>
        </div>
      )}

      {phase === 'signedOut' && <AuthView />}
      {phase === 'needsOnboarding' && <OnboardingView />}
      {phase === 'ready' && <MainTabs />}
    </div>
  )
}

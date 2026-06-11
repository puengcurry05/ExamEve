import { Routes, Route, Navigate, useLocation, useNavigate } from 'react-router-dom'
import { Layers, Users, Calendar, UserCircle } from 'lucide-react'
import LibraryView from './library/LibraryView'
import DeckDetailView from './library/DeckDetailView'
import CommunityView from './community/CommunityView'
import CalendarView from './calendar/CalendarView'
import ProfileView from './profile/ProfileView'
import StudyRunner from './study/StudyRunner'

const TABS = [
  { path: '/library', label: '학습함', icon: Layers },
  { path: '/community', label: '공유', icon: Users },
  { path: '/calendar', label: '달력', icon: Calendar },
  { path: '/profile', label: '프로필', icon: UserCircle },
]

export default function MainTabs() {
  const location = useLocation()
  const navigate = useNavigate()

  // 학습 모드 실행 중에는 탭 바 숨김
  const isStudy = location.pathname.startsWith('/study/')

  return (
    <div className="min-h-screen flex flex-col">
      <div className={`flex-1 ${isStudy ? '' : 'pb-[64px]'}`}>
        <Routes>
          <Route path="/" element={<Navigate to="/library" replace />} />
          <Route path="/library" element={<LibraryView />} />
          <Route path="/deck/:id" element={<DeckDetailView />} />
          <Route path="/community" element={<CommunityView />} />
          <Route path="/calendar" element={<CalendarView />} />
          <Route path="/profile" element={<ProfileView />} />
          <Route path="/study/:mode/:deckId" element={<StudyRunner />} />
          <Route path="*" element={<Navigate to="/library" replace />} />
        </Routes>
      </div>

      {!isStudy && (
        <nav className="fixed bottom-0 left-1/2 -translate-x-1/2 w-full max-w-[480px] h-[64px] bg-white/95 backdrop-blur border-t border-black/5 flex items-stretch z-30">
          {TABS.map((tab) => {
            const active =
              location.pathname === tab.path ||
              (tab.path === '/library' && location.pathname.startsWith('/deck/'))
            const Icon = tab.icon
            return (
              <button
                key={tab.path}
                onClick={() => navigate(tab.path)}
                className={`flex-1 flex flex-col items-center justify-center gap-0.5 transition
                  ${active ? 'text-primary' : 'text-gray-400'}`}
              >
                <Icon size={22} className={active ? 'fill-primary/15' : ''} />
                <span className="text-[10px] font-medium">{tab.label}</span>
              </button>
            )
          })}
        </nav>
      )}
    </div>
  )
}

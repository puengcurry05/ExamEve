/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        // iOS 앱 Theme.swift와 동일한 팔레트
        primary: '#4255FF',     // Quizlet 시그니처 블루
        appbg: '#F6F7FB',
        appyellow: '#FFCD42',
        appgreen: '#23B574',
        appred: '#FF5C5C',
        apppurple: '#7C5CFF',
        appteal: '#18AEBC',
        apporange: '#FF9040',
        // 프로필 파스텔
        'profile-sky': '#C8E4FF',
        'profile-pink': '#FFD6E8',
        'profile-mint': '#C5F5E8',
        'profile-lavender': '#E8D5FF',
        'profile-peach': '#FFE8C8',
      },
      fontFamily: {
        sans: [
          '-apple-system', 'BlinkMacSystemFont', 'Apple SD Gothic Neo',
          'Pretendard', 'Segoe UI', 'Roboto', 'sans-serif',
        ],
      },
      boxShadow: {
        card: '0 2px 8px rgba(0,0,0,0.06)',
        dropdown: '0 4px 12px rgba(0,0,0,0.10)',
      },
      borderRadius: {
        card: '16px',
      },
    },
  },
  plugins: [],
}

# 시험전야 Web

iOS SwiftUI 앱 [시험전야](../)의 웹 버전. 동일한 Supabase 백엔드/스키마를 그대로 사용합니다.

## 스택

- React 18 + TypeScript + Vite
- Tailwind CSS (iOS 앱과 동일한 색상 팔레트)
- React Router (탭/덱 상세/학습 라우팅)
- Supabase JS SDK v2 (인증 + PostgREST + Storage)
- lucide-react (아이콘, SF Symbols 대응)

## 기능 (iOS 앱과 동일)

- 이메일 로그인/회원가입/비밀번호 찾기
- 온보딩(닉네임 + 학교 검색)
- 학습함: 덱 목록 / 생성·편집(카드 순서 변경·삭제) / 삭제
- 학습 모드: 암기(플립) / 리콜(4지선다) / 스펠(직접 입력) / 테스트(점수) / 오답 복습
- 틀린 카드만 다시 풀기, 오답 자동 저장
- 공유 탭: 일반/학교 공유 덱 탐색, 검색, 최신·인기 정렬, 다운로드
- 달력 탭: 일별 학습 시간(HH:MM) + 월간 합계
- 프로필: 아바타 색상/사진, 닉네임·학교 수정, 로그아웃

## 실행

```bash
cp .env.example .env.local   # Supabase URL / anon key 입력
npm install
npm run dev                  # http://localhost:5173
npm run build                # 프로덕션 빌드 (dist/)
```

## 환경변수 (`.env.local`, gitignore됨)

```
VITE_SUPABASE_URL=https://<project-id>.supabase.co
VITE_SUPABASE_ANON_KEY=<anon/publishable key>
```

## 구조

```
src/
  lib/         supabase 클라이언트, 타입, 데이터 서비스, 테마, 에러 메시지
  state/       AuthContext (iOS AppState 대응)
  components/  공용 UI (버튼/칩/아바타/덱 행/헤더)
  features/
    auth/      로그인 · 온보딩 · 학교 검색
    library/   학습함 · 덱 상세 · 덱 편집 · 과목 선택
    community/ 공유 탭
    calendar/  달력 탭
    profile/   프로필 · 프로필/학교 편집
    study/     학습 로직(builder) · 암기 · 문제 플레이어 · 결과 · 오답
```

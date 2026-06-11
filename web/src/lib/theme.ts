// iOS ProfileColor enum과 동일

export const PROFILE_COLORS = {
  sky: '#C8E4FF',
  pink: '#FFD6E8',
  mint: '#C5F5E8',
  lavender: '#E8D5FF',
  peach: '#FFE8C8',
} as const

export type ProfileColorKey = keyof typeof PROFILE_COLORS
export const PROFILE_COLOR_KEYS = Object.keys(PROFILE_COLORS) as ProfileColorKey[]

export function resolveProfileColor(key: string | null | undefined): string {
  if (key && key in PROFILE_COLORS) return PROFILE_COLORS[key as ProfileColorKey]
  return PROFILE_COLORS.sky
}

// 과목 타입별 색상 (SubjectPicker)
export const SUBJECT_TYPE_COLORS: Record<string, string> = {
  공통: '#4255FF',
  일반선택: '#23B574',
  진로선택: '#FF9040',
  융합선택: '#7C5CFF',
}

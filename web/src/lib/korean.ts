// iOS koreanMessage(for:)와 동일한 에러 메시지 매핑

export function koreanMessage(error: unknown): string {
  const raw =
    error instanceof Error ? error.message : typeof error === 'string' ? error : String(error)
  const lower = raw.toLowerCase()

  const has = (s: string) => lower.includes(s.toLowerCase())

  if (has('Invalid login credentials')) return '이메일 또는 비밀번호가 올바르지 않아요.'
  if (has('User already registered')) return '이미 가입된 이메일이에요.'
  if (has('Password should be at least')) return '비밀번호는 6자 이상이어야 해요.'
  if (has('Email not confirmed')) return '이메일 인증이 아직 완료되지 않았어요.'
  if (has('Token has expired') || has('expired')) return '코드가 만료됐어요. 코드를 다시 요청해주세요.'
  if (has('Token is invalid') || has('invalid token') || has('otp'))
    return '코드가 올바르지 않아요. 다시 확인해주세요.'
  if (has('invalid format') || has('validate email')) return '이메일 형식이 올바르지 않아요.'
  if (has('rate limit') || has('too many')) return '요청이 너무 많아요. 잠시 후 다시 시도해주세요.'
  return raw
}

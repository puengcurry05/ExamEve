import type { ButtonHTMLAttributes, InputHTMLAttributes, ReactNode } from 'react'

// ── PrimaryButton ───────────────────────────────────────
export function PrimaryButton({
  title,
  busy = false,
  disabled = false,
  onClick,
  type = 'button',
}: {
  title: string
  busy?: boolean
  disabled?: boolean
  onClick?: () => void
  type?: 'button' | 'submit'
}) {
  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled || busy}
      className={`w-full py-3.5 rounded-[14px] font-semibold text-white transition
        ${disabled || busy ? 'bg-gray-400/60 cursor-not-allowed' : 'bg-primary hover:bg-primary/90 active:scale-[0.99]'}`}
    >
      {busy ? <Spinner light /> : title}
    </button>
  )
}

// ── Spinner ─────────────────────────────────────────────
export function Spinner({ light = false }: { light?: boolean }) {
  return (
    <span
      className={`inline-block w-5 h-5 rounded-full border-2 animate-spin align-middle
        ${light ? 'border-white/40 border-t-white' : 'border-primary/30 border-t-primary'}`}
    />
  )
}

// ── TagChip ─────────────────────────────────────────────
export function TagChip({ text, color = '#4255FF' }: { text: string; color?: string }) {
  return (
    <span className="tag-chip" style={{ color, backgroundColor: `${color}1F` }}>
      {text}
    </span>
  )
}

// ── RoundedField ────────────────────────────────────────
export function RoundedField(props: InputHTMLAttributes<HTMLInputElement>) {
  return <input {...props} className={`input-field ${props.className ?? ''}`} />
}

// ── Card 컨테이너 ───────────────────────────────────────
export function CardBox({
  children,
  className = '',
  onClick,
}: {
  children: ReactNode
  className?: string
  onClick?: () => void
}) {
  return (
    <div onClick={onClick} className={`card ${className}`}>
      {children}
    </div>
  )
}

// ── IconButton ──────────────────────────────────────────
export function IconButton({
  children,
  ...props
}: ButtonHTMLAttributes<HTMLButtonElement> & { children: ReactNode }) {
  return (
    <button {...props} className={`transition active:scale-95 ${props.className ?? ''}`}>
      {children}
    </button>
  )
}

// ── 전체 화면 로딩 ──────────────────────────────────────
export function FullScreenLoading({ label }: { label?: string }) {
  return (
    <div className="flex flex-col items-center justify-center h-full gap-4 text-gray-500">
      <Spinner />
      {label && <span className="text-sm">{label}</span>}
    </div>
  )
}

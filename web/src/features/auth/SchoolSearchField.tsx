import { useEffect, useRef, useState } from 'react'
import { Search, CheckCircle2, XCircle, Check } from 'lucide-react'
import { searchSchools } from '../../lib/data'
import type { School } from '../../lib/types'
import { Spinner } from '../../components/ui'

export default function SchoolSearchField({
  selectedSchool,
  onSelect,
  placeholder = '학교 이름 검색',
}: {
  selectedSchool: School | null
  onSelect: (s: School | null) => void
  placeholder?: string
}) {
  const [query, setQuery] = useState(selectedSchool?.name ?? '')
  const [results, setResults] = useState<School[]>([])
  const [searching, setSearching] = useState(false)
  const [showDropdown, setShowDropdown] = useState(false)
  const [focused, setFocused] = useState(false)
  const debounce = useRef<ReturnType<typeof setTimeout> | null>(null)

  // 외부에서 selectedSchool이 세팅되면 query 동기화
  useEffect(() => {
    if (selectedSchool) setQuery(selectedSchool.name)
  }, [selectedSchool])

  function handleChange(value: string) {
    setQuery(value)
    if (selectedSchool && value !== selectedSchool.name) onSelect(null)
    if (value.trim().length < 1) {
      setResults([])
      setShowDropdown(false)
      return
    }
    setShowDropdown(true)
    if (debounce.current) clearTimeout(debounce.current)
    debounce.current = setTimeout(() => void runSearch(value), 300)
  }

  async function runSearch(q: string) {
    setSearching(true)
    try {
      setResults(await searchSchools(q))
    } catch {
      setResults([])
    } finally {
      setSearching(false)
    }
  }

  function select(school: School) {
    onSelect(school)
    setQuery(school.name)
    setShowDropdown(false)
    setResults([])
  }

  function clear() {
    setQuery('')
    onSelect(null)
    setResults([])
    setShowDropdown(false)
  }

  return (
    <div className="relative">
      <div
        className={`flex items-center gap-2.5 px-3.5 py-3 bg-white rounded-xl border transition
          ${focused ? 'border-primary ring-1 ring-primary/30' : 'border-black/10'}`}
      >
        <Search size={18} className="text-gray-400 shrink-0" />
        <input
          className="flex-1 outline-none bg-transparent placeholder:text-gray-400"
          placeholder={placeholder}
          value={query}
          autoCapitalize="none"
          autoCorrect="off"
          onFocus={() => setFocused(true)}
          onBlur={() => {
            setFocused(false)
            // 드롭다운 클릭이 먼저 처리되도록 약간 지연
            setTimeout(() => setShowDropdown(false), 150)
          }}
          onChange={(e) => handleChange(e.target.value)}
        />
        {searching ? (
          <Spinner />
        ) : selectedSchool ? (
          <CheckCircle2 size={20} className="text-appgreen shrink-0" />
        ) : query.length > 0 ? (
          <button type="button" onClick={clear}>
            <XCircle size={20} className="text-gray-400 shrink-0" />
          </button>
        ) : null}
      </div>

      {showDropdown && results.length > 0 && (
        <div className="absolute z-20 left-0 right-0 mt-1 max-h-[220px] overflow-y-auto bg-white rounded-xl shadow-dropdown border border-black/5">
          {results.map((school, i) => (
            <button
              key={school.id}
              type="button"
              onMouseDown={(e) => e.preventDefault()}
              onClick={() => select(school)}
              className={`w-full flex items-center justify-between px-3.5 py-2.5 text-left hover:bg-gray-50
                ${i < results.length - 1 ? 'border-b border-black/5' : ''}`}
            >
              <div>
                <div className="text-sm font-semibold">{school.name}</div>
                <div className="text-xs text-gray-500">{school.region}</div>
              </div>
              {selectedSchool?.id === school.id && <Check size={16} className="text-primary" />}
            </button>
          ))}
        </div>
      )}

      {showDropdown && query.length > 0 && !searching && results.length === 0 && (
        <div className="absolute z-20 left-0 right-0 mt-1 bg-white rounded-xl shadow-dropdown border border-black/5 px-3.5 py-2.5 text-xs text-gray-500">
          일치하는 학교가 없어요
        </div>
      )}
    </div>
  )
}

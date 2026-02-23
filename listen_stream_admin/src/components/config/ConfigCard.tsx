import React, { useState } from 'react'
import { Eye, EyeOff, Info } from 'lucide-react'
import { cn } from '@/lib/utils'

interface ConfigCardProps {
  icon: React.ReactNode
  title: string
  configKey: string
  value: string
  description?: string
  updatedAt: string
  isSensitive?: boolean
  isEditing?: boolean
  onChange?: (value: string) => void
}

function maskValue(value: string): string {
  if (!value || value.length <= 6) return '••••••'
  return value.slice(0, 8) + '•'.repeat(Math.min(value.length - 12, 30)) + value.slice(-4)
}

export function ConfigCard({
  icon,
  title,
  configKey,
  value,
  description,
  updatedAt,
  isSensitive = false,
  isEditing = false,
  onChange,
}: ConfigCardProps) {
  const [revealed, setRevealed] = useState(false)
  const displayValue = revealed || !isSensitive ? value : maskValue(value)

  return (
    <div
      className={cn(
        'bg-white border rounded-lg p-6 transition-all duration-200',
        isEditing
          ? 'border-blue-400 shadow-md ring-1 ring-blue-100'
          : 'border-slate-200 hover:border-slate-300'
      )}
    >
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <div className="text-slate-600">{icon}</div>
          <h3 className="font-semibold text-slate-900">{title}</h3>
        </div>
        <time className="text-xs text-slate-400">
          {updatedAt}
        </time>
      </div>

      {/* Value */}
      <div className="mb-3">
        {isEditing ? (
          <input
            type="text"
            defaultValue={value}
            onChange={(e) => onChange?.(e.target.value)}
            className="w-full px-3 py-2 border border-slate-300 rounded-md text-sm font-mono focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            placeholder={`Enter ${title.toLowerCase()}`}
          />
        ) : (
          <div className="flex items-center gap-2 group">
            <code className="flex-1 text-sm font-mono text-slate-800 break-all bg-slate-50 px-3 py-2 rounded-md border border-slate-200">
              {displayValue || '—'}
            </code>
            {isSensitive && value && (
              <button
                onClick={() => setRevealed(!revealed)}
                className="shrink-0 p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-md transition-colors"
                title={revealed ? 'Hide value' : 'Show value'}
              >
                {revealed ? <EyeOff size={16} /> : <Eye size={16} />}
              </button>
            )}
          </div>
        )}
      </div>

      {/* Description */}
      {description && (
        <p className="text-xs text-slate-500 flex items-start gap-1">
          <Info size={12} className="mt-0.5 shrink-0" />
          <span>{description}</span>
        </p>
      )}
    </div>
  )
}

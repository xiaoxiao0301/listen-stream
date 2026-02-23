import React from 'react'
import { CheckCircle, XCircle, AlertTriangle, Info, X } from 'lucide-react'
import { cn } from '@/lib/utils'

interface StatusBannerProps {
  type: 'success' | 'error' | 'warning' | 'info'
  message: string
  timestamp?: string
  dismissible?: boolean
  onDismiss?: () => void
}

const variantStyles = {
  success: {
    container: 'bg-green-50 border-green-200 text-green-800',
    icon: CheckCircle,
    iconColor: 'text-green-600',
  },
  error: {
    container: 'bg-red-50 border-red-200 text-red-800',
    icon: XCircle,
    iconColor: 'text-red-600',
  },
  warning: {
    container: 'bg-amber-50 border-amber-200 text-amber-800',
    icon: AlertTriangle,
    iconColor: 'text-amber-600',
  },
  info: {
    container: 'bg-blue-50 border-blue-200 text-blue-800',
    icon: Info,
    iconColor: 'text-blue-600',
  },
}

export function StatusBanner({
  type,
  message,
  timestamp,
  dismissible,
  onDismiss,
}: StatusBannerProps) {
  const variant = variantStyles[type]
  const Icon = variant.icon

  return (
    <div
      className={cn(
        'flex items-start gap-3 px-4 py-3 rounded-lg border',
        variant.container
      )}
    >
      <Icon size={20} className={cn('mt-0.5 shrink-0', variant.iconColor)} />
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium">{message}</p>
        {timestamp && (
          <p className="text-xs opacity-75 mt-0.5">
            {timestamp}
          </p>
        )}
      </div>
      {dismissible && onDismiss && (
        <button
          onClick={onDismiss}
          className="shrink-0 hover:opacity-70 transition-opacity"
        >
          <X size={16} />
        </button>
      )}
    </div>
  )
}

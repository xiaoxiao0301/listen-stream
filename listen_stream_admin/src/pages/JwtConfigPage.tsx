import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { getJWTConfig, updateJWTConfig } from '@/api/config'
import { PageHeader } from '@/components/config/PageHeader'
import { StatusBanner } from '@/components/config/StatusBanner'
import { ConfigCard } from '@/components/config/ConfigCard'
import { AlertTriangle, Shield, Clock, Key } from 'lucide-react'

const CONFIG_METADATA = {
  JWT_SECRET_KEY: {
    icon: <Key size={20} />,
    title: 'JWT Secret Key',
    description: 'Secret key used to sign JWT tokens',
    sensitive: true,
  },
  JWT_EXPIRY_HOURS: {
    icon: <Clock size={20} />,
    title: 'JWT Expiry Hours',
    description: 'Token validity duration in hours',
    sensitive: false,
  },
  JWT_REFRESH_SECRET: {
    icon: <Shield size={20} />,
    title: 'JWT Refresh Secret',
    description: 'Secret key for refresh tokens',
    sensitive: true,
  },
  JWT_REFRESH_EXPIRY_DAYS: {
    icon: <Clock size={20} />,
    title: 'Refresh Token Expiry Days',
    description: 'Refresh token validity duration in days',
    sensitive: false,
  },
}

function formatRelativeTime(dateString: string): string {
  const date = new Date(dateString)
  const now = new Date()
  const diffInMs = now.getTime() - date.getTime()
  const diffInMinutes = Math.floor(diffInMs / (1000 * 60))
  const diffInHours = Math.floor(diffInMs / (1000 * 60 * 60))
  const diffInDays = Math.floor(diffInMs / (1000 * 60 * 60 * 24))

  if (diffInMinutes < 1) return 'just now'
  if (diffInMinutes < 60) return `${diffInMinutes}m ago`
  if (diffInHours < 24) return `${diffInHours}h ago`
  if (diffInDays < 7) return `${diffInDays}d ago`
  return date.toLocaleDateString()
}

export function JwtConfigPage() {
  const qc = useQueryClient()
  const [editing, setEditing] = useState(false)
  const [changes, setChanges] = useState<Record<string, string>>({})
  const [confirmOpen, setConfirmOpen] = useState(false)
  const [confirmText, setConfirmText] = useState('')
  const [affectedSessions, setAffectedSessions] = useState<number | null>(null)

  const { data: items = [], isLoading } = useQuery({
    queryKey: ['jwt-config'],
    queryFn: getJWTConfig,
  })

  const saveMutation = useMutation({
    mutationFn: () => updateJWTConfig(changes),
    onSuccess: (data) => {
      setAffectedSessions(data.affected_sessions)
      qc.invalidateQueries({ queryKey: ['jwt-config'] })
      setEditing(false)
      setChanges({})
      setConfirmOpen(false)
      setConfirmText('')
      // Auto-dismiss after 5s
      setTimeout(() => setAffectedSessions(null), 5000)
    },
  })

  const hasJwtSecret = Object.keys(changes).some((k) => k.toLowerCase().includes('secret'))

  function handleSaveClick() {
    if (hasJwtSecret) {
      setConfirmOpen(true)
    } else {
      saveMutation.mutate()
    }
  }

  function handleConfirm() {
    if (confirmText.trim() !== 'CONFIRM') return
    saveMutation.mutate()
  }

  function handleChange(key: string, value: string) {
    setChanges((prev) => ({ ...prev, [key]: value }))
  }

  if (isLoading) {
    return (
      <div className="space-y-6">
        <PageHeader title="JWT Configuration" />
        <div className="grid gap-4">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="bg-white border border-slate-200 rounded-lg h-40 animate-pulse" />
          ))}
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <PageHeader
        title="JWT Configuration"
        description="JWT signing secrets and token expiry settings"
        actions={
          !editing ? (
            <button
              onClick={() => setEditing(true)}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors"
            >
              Edit Configuration
            </button>
          ) : (
            <>
              <button
                onClick={() => {
                  setEditing(false)
                  setChanges({})
                }}
                className="px-4 py-2 border border-slate-300 text-slate-700 rounded-lg text-sm font-medium hover:bg-slate-50 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveClick}
                disabled={saveMutation.isPending || Object.keys(changes).length === 0}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                {saveMutation.isPending ? 'Saving…' : 'Save Changes'}
              </button>
            </>
          )
        }
      />

      {/* Status Banners */}
      <div className="space-y-3">
        {affectedSessions !== null && (
          <StatusBanner
            type="warning"
            message={`JWT secret updated — ${affectedSessions} active session${affectedSessions !== 1 ? 's' : ''} ${affectedSessions !== 1 ? 'were' : 'was'} invalidated`}
            dismissible
            onDismiss={() => setAffectedSessions(null)}
          />
        )}

        {saveMutation.isError && (
          <StatusBanner
            type="error"
            message={(saveMutation.error as any)?.response?.data?.message ?? 'Failed to save configuration'}
            dismissible
            onDismiss={() => saveMutation.reset()}
          />
        )}

        {hasJwtSecret && editing && (
          <StatusBanner
            type="warning"
            message="Changing the JWT secret will invalidate all active user sessions immediately."
          />
        )}
      </div>

      {/* Configuration Cards */}
      <div className="grid gap-4">
        {items.length === 0 ? (
          <div className="bg-white border border-slate-200 rounded-lg p-12 text-center">
            <p className="text-slate-400">No configuration entries found.</p>
          </div>
        ) : (
          items.map((item) => {
            const metadata = CONFIG_METADATA[item.key as keyof typeof CONFIG_METADATA]
            if (!metadata) return null

            return (
              <ConfigCard
                key={item.key}
                icon={metadata.icon}
                title={metadata.title}
                configKey={item.key}
                value={changes[item.key] ?? item.value}
                description={metadata.description}
                updatedAt={formatRelativeTime(item.updated_at)}
                isSensitive={metadata.sensitive}
                isEditing={editing}
                onChange={(value) => handleChange(item.key, value)}
              />
            )
          })
        )}
      </div>

      {/* Confirmation Dialog */}
      {confirmOpen && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 px-4">
          <div className="bg-white rounded-xl shadow-xl max-w-md w-full p-6 space-y-4">
            <h2 className="text-lg font-semibold text-slate-900 flex items-center gap-2">
              <AlertTriangle size={18} className="text-red-500" />
              Confirm JWT Secret Change
            </h2>
            <p className="text-sm text-slate-600">
              This will invalidate all active user sessions. Users will need to log in again.
              Type <strong>CONFIRM</strong> to proceed.
            </p>
            <input
              type="text"
              value={confirmText}
              onChange={(e) => setConfirmText(e.target.value)}
              placeholder="Type CONFIRM"
              className="w-full border border-slate-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-red-500"
              autoFocus
            />
            <div className="flex justify-end gap-2">
              <button
                onClick={() => {
                  setConfirmOpen(false)
                  setConfirmText('')
                }}
                className="px-4 py-2 border border-slate-300 text-slate-700 rounded-lg text-sm hover:bg-slate-50 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleConfirm}
                disabled={confirmText.trim() !== 'CONFIRM' || saveMutation.isPending}
                className="px-4 py-2 bg-red-600 text-white rounded-lg text-sm font-medium hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                {saveMutation.isPending ? 'Saving…' : 'Confirm & Save'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

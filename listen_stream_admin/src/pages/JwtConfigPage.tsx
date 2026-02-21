import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { getJWTConfig, updateJWTConfig, type ConfigItem } from '@/api/config'
import { Eye, EyeOff, AlertTriangle } from 'lucide-react'

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

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">JWT Config</h1>
          <p className="text-sm text-slate-500 mt-0.5">JWT signing secrets and expiry settings</p>
        </div>
        <div className="flex items-center gap-2">
          {!editing ? (
            <button
              onClick={() => setEditing(true)}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors"
            >
              Edit
            </button>
          ) : (
            <>
              <button
                onClick={() => {
                  setEditing(false)
                  setChanges({})
                }}
                className="px-4 py-2 border border-slate-300 text-slate-700 rounded-lg text-sm hover:bg-slate-50 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveClick}
                disabled={saveMutation.isPending || Object.keys(changes).length === 0}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 disabled:opacity-50 transition-colors"
              >
                Save
              </button>
            </>
          )}
        </div>
      </div>

      {affectedSessions !== null && (
        <div className="bg-amber-50 border border-amber-200 rounded-lg px-4 py-3 text-amber-700 text-sm flex items-center gap-2">
          <AlertTriangle size={15} />
          JWT secret updated — <strong>{affectedSessions}</strong> active session
          {affectedSessions !== 1 ? 's' : ''} were invalidated
        </div>
      )}

      {saveMutation.isError && (
        <div className="bg-red-50 border border-red-200 rounded-lg px-4 py-3 text-red-700 text-sm">
          {(saveMutation.error as any)?.response?.data?.message ?? 'Save failed'}
        </div>
      )}

      {hasJwtSecret && editing && (
        <div className="bg-orange-50 border border-orange-200 rounded-lg px-4 py-3 text-orange-700 text-sm flex items-center gap-2">
          <AlertTriangle size={15} />
          Changing the JWT secret will invalidate all active user sessions immediately.
        </div>
      )}

      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
        {isLoading ? (
          <div className="p-8 text-center text-slate-400 text-sm">Loading config…</div>
        ) : (
          <table className="w-full">
            <thead>
              <tr className="border-b border-slate-200 bg-slate-50">
                <th className="text-left py-3 px-4 text-xs font-semibold text-slate-500 uppercase tracking-wide">
                  Key
                </th>
                <th className="text-left py-3 pr-4 text-xs font-semibold text-slate-500 uppercase tracking-wide">
                  Value
                </th>
                <th className="py-3 pr-4 text-xs font-semibold text-slate-500 uppercase tracking-wide text-right">
                  Updated
                </th>
              </tr>
            </thead>
            <tbody>
              {items.map((item) => (
                <JwtRow
                  key={item.key}
                  item={item}
                  editing={editing}
                  onChange={(val) => setChanges((c) => ({ ...c, [item.key]: val }))}
                />
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* Confirmation dialog */}
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
            />
            <div className="flex justify-end gap-2">
              <button
                onClick={() => {
                  setConfirmOpen(false)
                  setConfirmText('')
                }}
                className="px-4 py-2 border border-slate-300 text-slate-700 rounded-lg text-sm hover:bg-slate-50"
              >
                Cancel
              </button>
              <button
                onClick={handleConfirm}
                disabled={confirmText.trim() !== 'CONFIRM' || saveMutation.isPending}
                className="px-4 py-2 bg-red-600 text-white rounded-lg text-sm font-medium hover:bg-red-700 disabled:opacity-50"
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

function JwtRow({
  item,
  editing,
  onChange,
}: {
  item: ConfigItem
  editing: boolean
  onChange: (val: string) => void
}) {
  const [revealed, setRevealed] = useState(false)
  const isSensitive = item.key.toLowerCase().includes('secret')

  const display =
    revealed || !isSensitive
      ? item.value
      : item.value.slice(0, 6) + '•'.repeat(32) + item.value.slice(-4)

  return (
    <tr className="border-b border-slate-100 last:border-0">
      <td className="py-3 pl-4 pr-4 text-sm font-mono text-slate-600 whitespace-nowrap">{item.key}</td>
      <td className="py-3 pr-4 w-full">
        {editing ? (
          <input
            type={isSensitive && !revealed ? 'password' : 'text'}
            defaultValue={item.value}
            onChange={(e) => onChange(e.target.value)}
            className="w-full border border-slate-300 rounded px-2 py-1 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        ) : (
          <span className="flex items-center gap-1.5">
            <span className="font-mono text-sm text-slate-800">{display || '—'}</span>
            {isSensitive && item.value && (
              <button
                onClick={() => setRevealed((r) => !r)}
                className="text-slate-400 hover:text-slate-600"
              >
                {revealed ? <EyeOff size={13} /> : <Eye size={13} />}
              </button>
            )}
          </span>
        )}
      </td>
      <td className="py-3 pr-4 text-xs text-slate-400 whitespace-nowrap text-right">
        {new Date(item.updated_at).toLocaleDateString()}
      </td>
    </tr>
  )
}

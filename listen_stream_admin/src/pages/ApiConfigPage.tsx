import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { getAPIConfig, updateAPIConfig, testAPIConnectivity, type ConfigItem } from '@/api/config'
import { cn } from '@/lib/utils'
import { Eye, EyeOff, RefreshCw, Wifi } from 'lucide-react'

function maskValue(key: string, value: string): string {
  const sensitiveKeys = ['cookie', 'token', 'secret', 'key', 'password']
  const isSensitive = sensitiveKeys.some((k) => key.toLowerCase().includes(k))
  if (!isSensitive || !value) return value
  if (value.length <= 6) return '••••••'
  return value.slice(0, 3) + '•'.repeat(Math.min(value.length - 6, 20)) + value.slice(-3)
}

export function ApiConfigPage() {
  const qc = useQueryClient()
  const [editing, setEditing] = useState(false)
  const [changes, setChanges] = useState<Record<string, string>>({})
  const [testResult, setTestResult] = useState<{ ok: boolean; latency_ms: number } | null>(null)
  const [testing, setTesting] = useState(false)

  const { data: items = [], isLoading } = useQuery({
    queryKey: ['api-config'],
    queryFn: getAPIConfig,
  })

  const saveMutation = useMutation({
    mutationFn: () => updateAPIConfig(changes),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['api-config'] })
      setEditing(false)
      setChanges({})
    },
  })

  async function handleTest() {
    setTesting(true)
    setTestResult(null)
    try {
      const result = await testAPIConnectivity()
      setTestResult(result)
    } catch {
      setTestResult({ ok: false, latency_ms: 0 })
    } finally {
      setTesting(false)
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">API Config</h1>
          <p className="text-sm text-slate-500 mt-0.5">Music API URL, cookie, and sync schedule</p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={handleTest}
            disabled={testing}
            className="flex items-center gap-1.5 px-3 py-2 border border-slate-300 text-slate-700 rounded-lg text-sm hover:bg-slate-50 disabled:opacity-50 transition-colors"
          >
            {testing ? <RefreshCw size={14} className="animate-spin" /> : <Wifi size={14} />}
            Test Connectivity
          </button>
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
                onClick={() => saveMutation.mutate()}
                disabled={saveMutation.isPending || Object.keys(changes).length === 0}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 disabled:opacity-50 transition-colors"
              >
                {saveMutation.isPending ? 'Saving…' : 'Save'}
              </button>
            </>
          )}
        </div>
      </div>

      {testResult !== null && (
        <div
          className={cn(
            'flex items-center gap-2 px-4 py-3 rounded-lg text-sm border',
            testResult.ok
              ? 'bg-green-50 border-green-200 text-green-700'
              : 'bg-red-50 border-red-200 text-red-700'
          )}
        >
          {testResult.ok
            ? `✓ Connectivity OK — ${testResult.latency_ms}ms`
            : '✗ Connectivity test failed'}
        </div>
      )}

      {saveMutation.isError && (
        <div className="bg-red-50 border border-red-200 rounded-lg px-4 py-3 text-red-700 text-sm">
          {(saveMutation.error as any)?.response?.data?.message ?? 'Save failed'}
        </div>
      )}

      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
        {isLoading ? (
          <div className="p-8 text-center text-slate-400 text-sm">Loading config…</div>
        ) : items.length === 0 ? (
          <div className="p-8 text-center text-slate-400 text-sm">No configuration entries found.</div>
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
                <th />
              </tr>
            </thead>
            <tbody className="px-4">
              {items.map((item) => (
                <tr key={item.key} className="border-b border-slate-100 last:border-0">
                  <td className="py-3 pl-4 pr-4 text-sm font-mono text-slate-600 whitespace-nowrap">
                    {item.key}
                  </td>
                  <td className="py-3 pr-4 w-full">
                    {editing ? (
                      <input
                        type="text"
                        defaultValue={item.value}
                        onChange={(e) =>
                          setChanges((c) => ({ ...c, [item.key]: e.target.value }))
                        }
                        className="w-full border border-slate-300 rounded px-2 py-1 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    ) : (
                      <RevealableValue configKey={item.key} value={item.value} />
                    )}
                  </td>
                  <td className="py-3 pr-4 text-xs text-slate-400 whitespace-nowrap">
                    {new Date(item.updated_at).toLocaleDateString()}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}

function RevealableValue({ configKey, value }: { configKey: string; value: string }) {
  const [revealed, setRevealed] = useState(false)
  const isSensitive = ['cookie', 'token', 'secret', 'key', 'password'].some((k) =>
    configKey.toLowerCase().includes(k)
  )
  const display = revealed || !isSensitive ? value : maskValue(configKey, value)

  return (
    <span className="flex items-center gap-1.5">
      <span className="font-mono text-sm text-slate-800 break-all">{display || '—'}</span>
      {isSensitive && value && (
        <button
          onClick={() => setRevealed((r) => !r)}
          className="text-slate-400 hover:text-slate-600 shrink-0"
        >
          {revealed ? <EyeOff size={13} /> : <Eye size={13} />}
        </button>
      )}
    </span>
  )
}

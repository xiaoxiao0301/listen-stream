import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { getAPIConfig, updateAPIConfig, testAPIConnectivity } from '@/api/config'
import { PageHeader } from '@/components/config/PageHeader'
import { StatusBanner } from '@/components/config/StatusBanner'
import { ConfigCard } from '@/components/config/ConfigCard'
import { RefreshCw, Wifi, Globe, RotateCcw, Key } from 'lucide-react'

const CONFIG_METADATA = {
  API_BASE_URL: {
    icon: <Globe size={20} />,
    title: 'API Base URL',
    description: 'Primary endpoint for all music API requests',
    sensitive: false,
  },
  API_FALLBACK_URL: {
    icon: <RotateCcw size={20} />,
    title: 'API Fallback URL',
    description: 'Automatically used if primary endpoint fails',
    sensitive: false,
  },
  API_KEY: {
    icon: <Key size={20} />,
    title: 'API Key',
    description: 'Sent as Authorization: Bearer <key> header',
    sensitive: true,
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

export function ApiConfigPage() {
  const qc = useQueryClient()
  const [editing, setEditing] = useState(false)
  const [changes, setChanges] = useState<Record<string, string>>({})
  const [testResult, setTestResult] = useState<{ ok: boolean; latency_ms: number } | null>(null)
  const [testing, setTesting] = useState(false)
  const [saveSuccess, setSaveSuccess] = useState(false)

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
      setSaveSuccess(true)
      // Auto-dismiss success message after 3s
      setTimeout(() => setSaveSuccess(false), 3000)
    },
  })

  async function handleTest() {
    setTesting(true)
    setTestResult(null)
    try {
      const result = await testAPIConnectivity()
      setTestResult(result)
      // Auto-dismiss after 5s
      setTimeout(() => setTestResult(null), 5000)
    } catch {
      setTestResult({ ok: false, latency_ms: 0 })
    } finally {
      setTesting(false)
    }
  }

  function handleChange(key: string, value: string) {
    setChanges((prev) => ({ ...prev, [key]: value }))
  }

  if (isLoading) {
    return (
      <div className="space-y-6">
        <PageHeader title="API Configuration" />
        <div className="grid gap-4">
          {[1, 2, 3].map((i) => (
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
        title="API Configuration"
        description="Configure music API endpoints and authentication"
        actions={
          <>
            <button
              onClick={handleTest}
              disabled={testing || editing}
              className="flex items-center gap-2 px-4 py-2 border border-slate-300 text-slate-700 rounded-lg text-sm font-medium hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              {testing ? (
                <RefreshCw size={16} className="animate-spin" />
              ) : (
                <Wifi size={16} />
              )}
              Test Connectivity
            </button>
            {!editing ? (
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
                  onClick={() => saveMutation.mutate()}
                  disabled={saveMutation.isPending || Object.keys(changes).length === 0}
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                  {saveMutation.isPending ? 'Saving…' : 'Save Changes'}
                </button>
              </>
            )}
          </>
        }
      />

      {/* Status Banners */}
      <div className="space-y-3">
        {testResult !== null && (
          <StatusBanner
            type={testResult.ok ? 'success' : 'error'}
            message={
              testResult.ok
                ? `Connectivity OK — ${testResult.latency_ms}ms`
                : 'Connectivity test failed. Please check your configuration.'
            }
            dismissible
            onDismiss={() => setTestResult(null)}
          />
        )}

        {saveSuccess && (
          <StatusBanner
            type="success"
            message="Configuration saved successfully"
            dismissible
            onDismiss={() => setSaveSuccess(false)}
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
    </div>
  )
}

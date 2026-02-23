import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import {
  listOperationLogs,
  listProxyLogs,
  type OperationLog,
  type ProxyLog,
} from '@/api/logs'
import { PageHeader } from '@/components/config/PageHeader'
import { cn } from '@/lib/utils'
import { ChevronDown, ChevronRight, ScrollText } from 'lucide-react'

const PAGE_SIZE = 30

function StatusBadge({ code }: { code: number }) {
  const color =
    code >= 500
      ? 'bg-red-100 text-red-700'
      : code >= 400
      ? 'bg-orange-100 text-orange-700'
      : 'bg-green-100 text-green-700'
  return (
    <span className={cn('inline-flex items-center px-2 py-0.5 rounded-full text-xs font-mono font-medium', color)}>
      {code}
    </span>
  )
}

function MaskedDiff({ before, after }: { before: string; after: string }) {
  const [revealed, setRevealed] = useState(false)

  function mask(val: string) {
    if (!val) return '—'
    try {
      const obj = JSON.parse(val)
      const masked = Object.fromEntries(
        Object.entries(obj).map(([k, v]) => {
          const sensitive = ['secret', 'password', 'key', 'token'].some((s) =>
            k.toLowerCase().includes(s)
          )
          return [k, sensitive && !revealed ? '••••••' : v]
        })
      )
      return JSON.stringify(masked, null, 2)
    } catch {
      return val
    }
  }

  return (
    <div className="space-y-2">
      <button
        onClick={() => setRevealed((r) => !r)}
        className="text-xs text-blue-600 hover:underline transition-colors"
      >
        {revealed ? 'Hide values' : 'Reveal values'}
      </button>
      <div className="grid grid-cols-2 gap-2">
        <div>
          <p className="text-xs text-slate-500 mb-1 font-medium">Before</p>
          <pre className="text-xs bg-red-50 border border-red-100 rounded p-2 overflow-x-auto whitespace-pre-wrap">
            {mask(before)}
          </pre>
        </div>
        <div>
          <p className="text-xs text-slate-500 mb-1 font-medium">After</p>
          <pre className="text-xs bg-green-50 border border-green-100 rounded p-2 overflow-x-auto whitespace-pre-wrap">
            {mask(after)}
          </pre>
        </div>
      </div>
    </div>
  )
}

function OperationLogsTab() {
  const [page, setPage] = useState(1)
  const [expanded, setExpanded] = useState<Set<number>>(new Set())

  const { data, isLoading } = useQuery({
    queryKey: ['operation-logs', page],
    queryFn: () => listOperationLogs({ page, page_size: PAGE_SIZE }),
    placeholderData: (prev) => prev,
  })

  const logs: OperationLog[] = data?.logs ?? []
  const total = data?.total ?? 0
  const totalPages = Math.ceil(total / PAGE_SIZE)

  function toggleExpand(id: number) {
    setExpanded((prev) => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  if (isLoading) return <div className="py-8 text-center text-slate-400 text-sm">Loading logs…</div>

  return (
    <div className="space-y-4">
      <div className="bg-white rounded-lg border border-slate-200 overflow-hidden">
        {logs.length === 0 ? (
          <div className="p-12 text-center">
            <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-slate-100 mb-3">
              <ScrollText size={20} className="text-slate-400" />
            </div>
            <p className="text-slate-600 text-sm font-medium">No operation logs yet</p>
            <p className="text-slate-400 text-xs mt-1">Admin operations will appear here</p>
          </div>
        ) : (
          <table className="w-full">
            <thead>
              <tr className="border-b border-slate-200 bg-slate-50">
                <th className="w-8" />
                <th className="text-left py-3 pl-4 text-xs font-semibold text-slate-500 uppercase tracking-wide">
                  Admin
                </th>
                <th className="text-left py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">
                  Action
                </th>
                <th className="text-left py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">
                  Resource
                </th>
                <th className="text-left py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">
                  IP
                </th>
                <th className="text-left py-3 pr-4 text-xs font-semibold text-slate-500 uppercase tracking-wide">
                  Time
                </th>
              </tr>
            </thead>
            <tbody>
              {logs.map((log) => (
                <>
                  <tr key={log.id} className="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                    <td className="pl-3">
                      <button
                        onClick={() => toggleExpand(log.id)}
                        className="text-slate-400 hover:text-slate-600 p-1 transition-colors"
                        disabled={!log.before_value && !log.after_value}
                      >
                        {expanded.has(log.id) ? (
                          <ChevronDown size={14} />
                        ) : (
                          <ChevronRight size={14} className={(!log.before_value && !log.after_value) ? 'opacity-20' : ''} />
                        )}
                      </button>
                    </td>
                    <td className="py-3 pl-1 text-sm text-slate-800">{log.admin_name}</td>
                    <td className="py-3 text-sm font-mono text-slate-600">{log.action}</td>
                    <td className="py-3 text-sm text-slate-600">{log.resource}</td>
                    <td className="py-3 text-xs font-mono text-slate-400">{log.ip}</td>
                    <td className="py-3 pr-4 text-xs text-slate-400 whitespace-nowrap">
                      {new Date(log.created_at).toLocaleString()}
                    </td>
                  </tr>
                  {expanded.has(log.id) && (
                    <tr key={`diff-${log.id}`} className="bg-slate-50 border-b border-slate-100">
                      <td />
                      <td colSpan={5} className="py-3 pl-4 pr-4 pb-4">
                        <MaskedDiff before={log.before_value} after={log.after_value} />
                      </td>
                    </tr>
                  )}
                </>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {totalPages > 1 && (
        <div className="flex items-center justify-between text-sm text-slate-600">
          <span>Page {page} of {totalPages} ({total.toLocaleString()} entries)</span>
          <div className="flex items-center gap-1">
            <button
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page === 1}
              className="px-3 py-1.5 border border-slate-300 rounded-lg hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
            >
              ← Prev
            </button>
            <button
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              disabled={page === totalPages}
              className="px-3 py-1.5 border border-slate-300 rounded-lg hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
            >
              Next →
            </button>
          </div>
        </div>
      )}
    </div>
  )
}

function ProxyLogsTab() {
  const [page, setPage] = useState(1)

  const { data, isLoading } = useQuery({
    queryKey: ['proxy-logs', page],
    queryFn: () => listProxyLogs({ page, page_size: PAGE_SIZE }),
    placeholderData: (prev) => prev,
  })

  const logs: ProxyLog[] = data?.logs ?? []
  const total = data?.total ?? 0
  const totalPages = Math.ceil(total / PAGE_SIZE)

  if (isLoading) return <div className="py-8 text-center text-slate-400 text-sm">Loading logs…</div>

  return (
    <div className="space-y-4">
      <div className="bg-white rounded-lg border border-slate-200 overflow-hidden">
        {logs.length === 0 ? (
          <div className="p-12 text-center">
            <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-slate-100 mb-3">
              <ScrollText size={20} className="text-slate-400" />
            </div>
            <p className="text-slate-600 text-sm font-medium">No proxy logs yet</p>
            <p className="text-slate-400 text-xs mt-1">API requests will be logged here</p>
          </div>
        ) : (
          <table className="w-full">
            <thead>
              <tr className="border-b border-slate-200 bg-slate-50">
                <th className="text-left py-3 pl-4 text-xs font-semibold text-slate-500 uppercase tracking-wide">
                  User
                </th>
                <th className="text-left py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">
                  Path
                </th>
                <th className="text-left py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">
                  Status
                </th>
                <th className="text-left py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">
                  Latency
                </th>
                <th className="text-left py-3 pr-4 text-xs font-semibold text-slate-500 uppercase tracking-wide">
                  Time
                </th>
              </tr>
            </thead>
            <tbody>
              {logs.map((log) => (
                <tr key={log.id} className="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                  <td className="py-3 pl-4 text-sm text-slate-600">{log.user_id}</td>
                  <td className="py-3 text-sm font-mono text-slate-600 max-w-xs truncate">{log.path}</td>
                  <td className="py-3">
                    <StatusBadge code={log.status_code} />
                  </td>
                  <td className="py-3 text-sm text-slate-500">{log.latency_ms}ms</td>
                  <td className="py-3 pr-4 text-xs text-slate-400 whitespace-nowrap">
                    {new Date(log.created_at).toLocaleString()}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {totalPages > 1 && (
        <div className="flex items-center justify-between text-sm text-slate-600">
          <span>Page {page} of {totalPages} ({total.toLocaleString()} entries)</span>
          <div className="flex items-center gap-1">
            <button
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page === 1}
              className="px-3 py-1.5 border border-slate-300 rounded-lg hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
            >
              ← Prev
            </button>
            <button
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              disabled={page === totalPages}
              className="px-3 py-1.5 border border-slate-300 rounded-lg hover:bg-slate-50 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
            >
              Next →
            </button>
          </div>
        </div>
      )}
    </div>
  )
}

export function LogsPage() {
  const [tab, setTab] = useState<'operation' | 'proxy'>('operation')

  return (
    <div className="space-y-6">
      <PageHeader
        title="System Logs"
        description="Admin operation history and proxy request logs"
      />

      <div className="flex gap-1 border-b border-slate-200 pb-px">
        {(['operation', 'proxy'] as const).map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={cn(
              'px-4 py-2 text-sm font-medium border-b-2 -mb-px transition-colors',
              tab === t
                ? 'border-blue-600 text-blue-600'
                : 'border-transparent text-slate-500 hover:text-slate-700'
            )}
          >
            {t === 'operation' ? 'Operation Logs' : 'Proxy Logs'}
          </button>
        ))}
      </div>

      {tab === 'operation' ? <OperationLogsTab /> : <ProxyLogsTab />}
    </div>
  )
}

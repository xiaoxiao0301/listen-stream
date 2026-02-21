import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { getSMSRecords, clearSMSRecords, type SMSRecord } from '@/api/config'
import { RefreshCw, Trash2 } from 'lucide-react'

export function SmsLogsPage() {
  const qc = useQueryClient()
  const [confirmClear, setConfirmClear] = useState(false)

  const { data: records = [], isLoading, isFetching, dataUpdatedAt } = useQuery({
    queryKey: ['sms-records'],
    queryFn: getSMSRecords,
    refetchInterval: 10_000, // auto-refresh every 10s
  })

  const clearMutation = useMutation({
    mutationFn: clearSMSRecords,
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['sms-records'] })
      setConfirmClear(false)
    },
  })

  const lastUpdated = dataUpdatedAt
    ? new Date(dataUpdatedAt).toLocaleTimeString()
    : '—'

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">SMS 日志</h1>
          <p className="text-sm text-slate-500 mt-0.5">
            开发模式下发送的短信验证码。每 10s 自动刷新，最多保留 200 条。
          </p>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-xs text-slate-400">上次更新 {lastUpdated}</span>
          <button
            onClick={() => qc.invalidateQueries({ queryKey: ['sms-records'] })}
            disabled={isFetching}
            className="flex items-center gap-1.5 px-3 py-2 border border-slate-300 text-slate-700 rounded-lg text-sm hover:bg-slate-50 disabled:opacity-50"
          >
            <RefreshCw size={14} className={isFetching ? 'animate-spin' : ''} />
            刷新
          </button>
          {!confirmClear ? (
            <button
              onClick={() => setConfirmClear(true)}
              disabled={records.length === 0}
              className="flex items-center gap-1.5 px-3 py-2 border border-red-300 text-red-600 rounded-lg text-sm hover:bg-red-50 disabled:opacity-40"
            >
              <Trash2 size={14} />
              清空
            </button>
          ) : (
            <>
              <span className="text-sm text-red-600 font-medium">确认清空？</span>
              <button
                onClick={() => clearMutation.mutate()}
                disabled={clearMutation.isPending}
                className="px-3 py-1.5 bg-red-600 text-white rounded-lg text-sm hover:bg-red-700 disabled:opacity-50"
              >
                {clearMutation.isPending ? '清空中…' : '确认'}
              </button>
              <button
                onClick={() => setConfirmClear(false)}
                className="px-3 py-1.5 border border-slate-300 text-slate-700 rounded-lg text-sm hover:bg-slate-50"
              >
                取消
              </button>
            </>
          )}
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
        {isLoading ? (
          <div className="p-8 text-center text-slate-400 text-sm">加载中…</div>
        ) : records.length === 0 ? (
          <div className="p-12 text-center">
            <p className="text-slate-400 text-sm">暂无记录</p>
            <p className="text-slate-300 text-xs mt-1">
              开启开发模式后，发送验证码时记录将出现在此处
            </p>
          </div>
        ) : (
          <table className="w-full">
            <thead>
              <tr className="border-b border-slate-200 bg-slate-50">
                <th className="text-left py-3 px-4 text-xs font-semibold text-slate-500 uppercase tracking-wide">
                  手机号
                </th>
                <th className="text-left py-3 px-4 text-xs font-semibold text-slate-500 uppercase tracking-wide">
                  验证码
                </th>
                <th className="text-left py-3 px-4 text-xs font-semibold text-slate-500 uppercase tracking-wide">
                  发送时间
                </th>
              </tr>
            </thead>
            <tbody>
              {records.map((r, i) => (
                <SmsRow key={`${r.phone}-${r.sent_at}-${i}`} record={r} />
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}

function SmsRow({ record }: { record: SMSRecord }) {
  const dt = new Date(record.sent_at)
  const timeStr = isNaN(dt.getTime())
    ? record.sent_at
    : dt.toLocaleString('zh-CN', { hour12: false })

  const expired = !isNaN(dt.getTime()) && Date.now() - dt.getTime() > 5 * 60 * 1000

  return (
    <tr className="border-b border-slate-100 last:border-0 hover:bg-slate-50">
      <td className="py-3 px-4 font-mono text-sm text-slate-700">{record.phone}</td>
      <td className="py-3 px-4">
        <span className="inline-block font-mono text-lg font-semibold tracking-[0.2em] text-blue-600">
          {record.code}
        </span>
        {expired && (
          <span className="ml-2 text-xs text-slate-400 font-normal">已过期</span>
        )}
      </td>
      <td className="py-3 px-4 text-sm text-slate-500 whitespace-nowrap">{timeStr}</td>
    </tr>
  )
}

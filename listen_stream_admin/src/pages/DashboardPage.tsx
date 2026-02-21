import { useQuery } from '@tanstack/react-query'
import { getOverview } from '@/api/stats'
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts'
import { AlertTriangle, Users, Activity, Clock } from 'lucide-react'

function StatCard({
  title,
  value,
  icon: Icon,
  accent,
}: {
  title: string
  value: string | number
  icon: React.FC<{ size?: number; className?: string }>
  accent?: string
}) {
  return (
    <div className="bg-white rounded-xl border border-slate-200 p-5 flex items-start gap-4">
      <div className={`p-2.5 rounded-lg ${accent ?? 'bg-blue-50'}`}>
        <Icon size={20} className={accent ? 'text-white' : 'text-blue-600'} />
      </div>
      <div>
        <p className="text-sm text-slate-500">{title}</p>
        <p className="text-2xl font-bold text-slate-900 mt-0.5">{value}</p>
      </div>
    </div>
  )
}

export function DashboardPage() {
  const { data, isLoading, error } = useQuery({
    queryKey: ['stats-overview'],
    queryFn: getOverview,
    refetchInterval: 30_000,
  })

  if (isLoading) {
    return (
      <div className="space-y-4">
        <h1 className="text-2xl font-bold text-slate-900">Dashboard</h1>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="bg-white rounded-xl border border-slate-200 p-5 h-24 animate-pulse">
              <div className="bg-slate-100 h-4 w-24 rounded mb-2" />
              <div className="bg-slate-200 h-7 w-16 rounded" />
            </div>
          ))}
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="space-y-4">
        <h1 className="text-2xl font-bold text-slate-900">Dashboard</h1>
        <div className="bg-red-50 border border-red-200 rounded-xl p-5 text-red-700 text-sm">
          Failed to load stats. The backend may be unavailable.
        </div>
      </div>
    )
  }

  const chartData =
    data?.requests_by_hour?.map((p) => ({
      hour: `${String(p.hour).padStart(2, '0')}:00`,
      requests: p.count,
    })) ?? []

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-slate-900">Dashboard</h1>
        {data?.cookie_alert && (
          <div className="flex items-center gap-2 px-3 py-2 bg-amber-50 border border-amber-200 rounded-lg text-amber-700 text-sm">
            <AlertTriangle size={15} />
            Cookie alert active — check API Config
          </div>
        )}
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <StatCard
          title="Total Users"
          value={(data?.total_users ?? 0).toLocaleString()}
          icon={Users}
        />
        <StatCard
          title="Active Today"
          value={(data?.active_users_today ?? 0).toLocaleString()}
          icon={Activity}
          accent="bg-green-500"
        />
        <StatCard
          title="Requests Today"
          value={(data?.total_requests_today ?? 0).toLocaleString()}
          icon={Activity}
        />
        <StatCard
          title="Avg Latency"
          value={`${data?.avg_latency_ms ?? 0} ms`}
          icon={Clock}
          accent={
            (data?.avg_latency_ms ?? 0) > 500
              ? 'bg-red-500'
              : (data?.avg_latency_ms ?? 0) > 200
              ? 'bg-amber-500'
              : 'bg-blue-500'
          }
        />
      </div>

      {chartData.length > 0 && (
        <div className="bg-white rounded-xl border border-slate-200 p-5">
          <h2 className="text-sm font-semibold text-slate-700 mb-4">Requests by Hour (Today)</h2>
          <ResponsiveContainer width="100%" height={200}>
            <AreaChart data={chartData}>
              <defs>
                <linearGradient id="colorReqs" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.2} />
                  <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
              <XAxis dataKey="hour" tick={{ fontSize: 11 }} />
              <YAxis tick={{ fontSize: 11 }} />
              <Tooltip />
              <Area
                type="monotone"
                dataKey="requests"
                stroke="#3b82f6"
                strokeWidth={2}
                fill="url(#colorReqs)"
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      )}

      <p className="text-xs text-slate-400 text-right">Auto-refreshes every 30 seconds</p>
    </div>
  )
}

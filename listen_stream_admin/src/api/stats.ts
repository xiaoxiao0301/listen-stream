import apiClient from './client'

export interface OverviewStats {
  total_users: number
  active_users_today: number
  total_requests_today: number
  error_rate: number
  cookie_alert: boolean
  avg_latency_ms: number
  requests_by_hour: Array<{ hour: number; count: number }>
}

export async function getOverview(): Promise<OverviewStats> {
  const res = await apiClient.get<OverviewStats>('/admin/stats/overview')
  return res.data
}

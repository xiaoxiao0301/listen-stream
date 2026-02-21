import apiClient from './client'

export interface OperationLog {
  id: number
  admin_id: number
  admin_name: string
  action: string
  resource: string
  before_value: string
  after_value: string
  ip: string
  created_at: string
}

export interface ProxyLog {
  id: number
  user_id: number
  path: string
  status_code: number
  latency_ms: number
  created_at: string
}

export interface LogsParams {
  page: number
  page_size: number
}

export interface OperationLogsResponse {
  total: number
  logs: OperationLog[]
}

export interface ProxyLogsResponse {
  total: number
  logs: ProxyLog[]
}

export async function listOperationLogs(params: LogsParams): Promise<OperationLogsResponse> {
  const res = await apiClient.get<OperationLogsResponse>('/admin/logs/operation', { params })
  return res.data
}

export async function listProxyLogs(params: LogsParams): Promise<ProxyLogsResponse> {
  const res = await apiClient.get<ProxyLogsResponse>('/admin/logs/proxy', { params })
  return res.data
}

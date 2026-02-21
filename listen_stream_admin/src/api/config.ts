import apiClient from './client'

export interface ConfigItem {
  key: string
  value: string
  updated_at: string
}

// Keys to always display, even when absent from the DB (value will be empty string)
const API_CONFIG_KEYS = ['API_BASE_URL', 'API_KEY', 'COOKIE']
const JWT_CONFIG_KEYS = ['USER_JWT_SECRET', 'ADMIN_JWT_SECRET', 'ACCESS_TOKEN_TTL', 'REFRESH_TOKEN_TTL', 'MAX_DEVICES']
const SMS_CONFIG_KEYS = ['SMS_PROVIDER', 'SMS_APP_ID', 'SMS_APP_KEY', 'SMS_SIGN_NAME', 'SMS_TEMPLATE']

function mapToItems(data: Record<string, string>, expectedKeys: string[]): ConfigItem[] {
  // Start from the expected key list so all fields appear even when DB is empty
  return expectedKeys.map((key) => ({
    key,
    value: data[key] ?? '',
    updated_at: '',
  }))
}

export async function getAPIConfig(): Promise<ConfigItem[]> {
  const res = await apiClient.get<Record<string, string>>('/admin/config/api')
  return mapToItems(res.data, API_CONFIG_KEYS)
}

export async function updateAPIConfig(items: Record<string, string>): Promise<void> {
  await apiClient.put('/admin/config/api', items)
}

export async function testAPIConnectivity(): Promise<{ ok: boolean; latency_ms: number }> {
  const res = await apiClient.post('/admin/config/api/test')
  return res.data
}

export async function getJWTConfig(): Promise<ConfigItem[]> {
  const res = await apiClient.get<Record<string, string>>('/admin/config/jwt')
  return mapToItems(res.data, JWT_CONFIG_KEYS)
}

export async function updateJWTConfig(items: Record<string, string>): Promise<{ affected_sessions: number }> {
  const res = await apiClient.put<{ affected_sessions: number }>('/admin/config/jwt', items)
  return res.data
}

export async function getSMSConfig(): Promise<ConfigItem[]> {
  const res = await apiClient.get<Record<string, string>>('/admin/config/sms')
  return mapToItems(res.data, SMS_CONFIG_KEYS)
}

export async function updateSMSConfig(items: Record<string, string>): Promise<void> {
  await apiClient.put('/admin/config/sms', items)
}

export interface SMSRecord {
  phone: string
  code: string
  sent_at: string
}

export async function getSMSRecords(): Promise<SMSRecord[]> {
  const res = await apiClient.get<{ data: SMSRecord[]; total: number }>('/admin/config/sms/records')
  return res.data.data
}

export async function clearSMSRecords(): Promise<void> {
  await apiClient.delete('/admin/config/sms/records')
}

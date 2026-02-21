import apiClient from './client'

export interface SetupStatus {
  initialized: boolean
}

export interface InitRequest {
  username: string
  password: string
  totp_enabled: boolean
  sms_provider?: string
  sms_config?: Record<string, string>
}

export async function getSetupStatus(): Promise<SetupStatus> {
  const res = await apiClient.get<SetupStatus>('/admin/setup/status')
  return res.data
}

export async function initSetup(data: InitRequest): Promise<void> {
  await apiClient.post('/admin/setup/init', data)
}

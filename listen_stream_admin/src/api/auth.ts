import apiClient from './client'

export interface LoginRequest {
  username: string
  password: string
  totp_code?: string
}

export interface LoginResponse {
  access_token: string
  expires_in: number
}

export interface LoginError {
  code: string
  message: string
  unlock_at?: string
}

export async function login(data: LoginRequest): Promise<LoginResponse> {
  const res = await apiClient.post<LoginResponse>('/admin/auth/login', data)
  return res.data
}

export async function logout(): Promise<void> {
  await apiClient.post('/admin/auth/logout')
}

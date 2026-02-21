import apiClient from './client'

export interface Device {
  id: string
  device_id: string
  platform: string
  last_active_at: string
  created_at: string
}

export interface User {
  id: string          // UUID
  phone: string
  role: string
  disabled: boolean
  created_at: string
  updated_at: string
  device_count: number
}

export interface ListUsersParams {
  page: number
  page_size: number
  phone?: string
}

export interface ListUsersResponse {
  data: User[]
  page: number
  size: number
  total: number
}

export async function listUsers(params: ListUsersParams): Promise<ListUsersResponse> {
  const res = await apiClient.get<ListUsersResponse>('/admin/users', { params })
  return res.data
}

export async function setUserStatus(id: string, disabled: boolean): Promise<void> {
  await apiClient.put(`/admin/users/${id}/status`, { disabled })
}

export async function getUserDevices(id: string): Promise<Device[]> {
  const res = await apiClient.get<{ data: Device[] }>(`/admin/users/${id}/devices`)
  return res.data.data
}

export async function revokeDevice(userId: string, deviceId: string): Promise<void> {
  await apiClient.delete(`/admin/devices/${deviceId}`)
}

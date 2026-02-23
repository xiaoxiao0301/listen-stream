import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { listUsers, setUserStatus, getUserDevices, revokeDevice, type User, type Device } from '@/api/users'
import { PageHeader } from '@/components/config/PageHeader'
import { StatusBanner } from '@/components/config/StatusBanner'
import { cn } from '@/lib/utils'
import { ChevronDown, ChevronRight, Search, Smartphone, X, Users as UsersIcon } from 'lucide-react'

function StatusBadge({ disabled }: { disabled: boolean }) {
  return (
    <span
      className={cn(
        'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium',
        !disabled
          ? 'bg-green-100 text-green-700'
          : 'bg-red-100 text-red-700'
      )}
    >
      {disabled ? 'banned' : 'active'}
    </span>
  )
}

function DevicesRow({ userId, onRevoke }: { userId: string; onRevoke: () => void }) {
  const { data: devices = [], isLoading } = useQuery({
    queryKey: ['user-devices', userId],
    queryFn: () => getUserDevices(userId),
  })

  const qc = useQueryClient()
  const revokeMutation = useMutation({
    mutationFn: (deviceId: string) => revokeDevice(userId, deviceId),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['user-devices', userId] })
      onRevoke()
    },
  })

  if (isLoading) {
    return (
      <tr>
        <td colSpan={6} className="pl-16 py-2 text-sm text-slate-400">
          Loading devices…
        </td>
      </tr>
    )
  }

  if (devices.length === 0) {
    return (
      <tr>
        <td colSpan={6} className="pl-16 py-2 text-sm text-slate-400">
          No devices registered
        </td>
      </tr>
    )
  }

  return (
    <>
      {devices.map((device: Device) => (
        <tr key={device.device_id} className="bg-slate-50 border-b border-slate-100">
          <td />
          <td colSpan={3} className="pl-16 py-2">
            <div className="flex items-center gap-2 text-sm text-slate-600">
              <Smartphone size={13} className="text-slate-400" />
              <span className="font-medium">{device.device_id}</span>
              <span className="text-xs text-slate-400">{device.platform}</span>
            </div>
          </td>
          <td className="py-2 text-xs text-slate-400">
            {new Date(device.last_active_at).toLocaleDateString()}
          </td>
          <td className="py-2 pr-4 text-right">
            <button
              onClick={() => revokeMutation.mutate(device.device_id)}
              disabled={revokeMutation.isPending}
              className="inline-flex items-center gap-1 text-xs text-red-600 hover:text-red-700 disabled:opacity-50 transition-colors"
            >
              <X size={12} /> Revoke
            </button>
          </td>
        </tr>
      ))}
    </>
  )
}

export function UsersPage() {
  const qc = useQueryClient()
  const [page, setPage] = useState(1)
  const [phone, setPhone] = useState('')
  const [searchInput, setSearchInput] = useState('')
  const [expandedUsers, setExpandedUsers] = useState<Set<string>>(new Set())
  const PAGE_SIZE = 20

  const { data, isLoading } = useQuery({
    queryKey: ['users', page, phone],
    queryFn: () => listUsers({ page, page_size: PAGE_SIZE, phone: phone || undefined }),
    placeholderData: (prev) => prev,
  })

  const statusMutation = useMutation({
    mutationFn: ({ id, disabled }: { id: string; disabled: boolean }) =>
      setUserStatus(id, disabled),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['users'] })
    },
  })

  function toggleExpand(id: string) {
    setExpandedUsers((prev) => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  function handleSearch(e: React.FormEvent) {
    e.preventDefault()
    setPhone(searchInput)
    setPage(1)
  }

  const users: User[] = data?.data ?? []
  const total = data?.total ?? 0
  const totalPages = Math.ceil(total / PAGE_SIZE)

  return (
    <div className="space-y-6">
      {/* Header */}
      <PageHeader
        title="User Management"
        description={`${total.toLocaleString()} total users`}
        actions={
          <form onSubmit={handleSearch} className="flex items-center gap-2">
            <div className="relative">
              <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
              <input
                type="text"
                value={searchInput}
                onChange={(e) => setSearchInput(e.target.value)}
                placeholder="Search by phone…"
                className="pl-9 pr-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 w-56"
              />
            </div>
            <button
              type="submit"
              className="px-3 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors"
            >
              Search
            </button>
            {phone && (
              <button
                type="button"
                onClick={() => {
                  setPhone('')
                  setSearchInput('')
                  setPage(1)
                }}
                className="px-3 py-2 border border-slate-300 text-slate-700 rounded-lg text-sm hover:bg-slate-50 transition-colors"
              >
                Clear
              </button>
            )}
          </form>
        }
      />

      {/* Status Banners */}
      {statusMutation.isSuccess && (
        <StatusBanner
          type="success"
          message="User status updated successfully"
          dismissible
          onDismiss={() => statusMutation.reset()}
        />
      )}

      {statusMutation.isError && (
        <StatusBanner
          type="error"
          message={(statusMutation.error as any)?.response?.data?.message ?? 'Failed to update user status'}
          dismissible
          onDismiss={() => statusMutation.reset()}
        />
      )}

      {/* Users Table */}
      <div className="bg-white rounded-lg border border-slate-200 overflow-hidden">
        {isLoading ? (
          <div className="p-8 text-center text-slate-400 text-sm">Loading users…</div>
        ) : users.length === 0 ? (
          <div className="p-12 text-center">
            <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-slate-100 mb-3">
              <UsersIcon size={20} className="text-slate-400" />
            </div>
            <p className="text-slate-600 text-sm font-medium">No users found</p>
            <p className="text-slate-400 text-xs mt-1">
              {phone ? 'Try a different search query' : 'No users in the system yet'}
            </p>
          </div>
        ) : (
          <table className="w-full">
            <thead>
              <tr className="border-b border-slate-200 bg-slate-50">
                <th className="w-8" />
                <th className="text-left py-3 pl-4 text-xs font-semibold text-slate-500 uppercase tracking-wide">
                  User
                </th>
                <th className="text-left py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">
                  Phone
                </th>
                <th className="text-left py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">
                  Status
                </th>
                <th className="text-left py-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">
                  Registered
                </th>
                <th className="py-3 pr-4 text-xs font-semibold text-slate-500 uppercase tracking-wide text-right">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody>
              {users.map((user) => (
                <>
                  <tr key={user.id} className="border-b border-slate-100 hover:bg-slate-50 transition-colors">
                    <td className="pl-3">
                      <button
                        onClick={() => toggleExpand(user.id)}
                        className="text-slate-400 hover:text-slate-600 p-1 transition-colors"
                      >
                        {expandedUsers.has(user.id) ? (
                          <ChevronDown size={14} />
                        ) : (
                          <ChevronRight size={14} />
                        )}
                      </button>
                    </td>
                    <td className="py-3 pl-1">
                      <div className="text-sm font-medium text-slate-800 font-mono text-xs">{user.id.slice(0, 8)}…</div>
                      <div className="text-xs text-slate-400">{user.role}</div>
                    </td>
                    <td className="py-3 text-sm text-slate-600 font-mono">{user.phone}</td>
                    <td className="py-3">
                      <StatusBadge disabled={user.disabled} />
                    </td>
                    <td className="py-3 text-sm text-slate-500">
                      {new Date(user.created_at).toLocaleDateString()}
                    </td>
                    <td className="py-3 pr-4 text-right">
                      <button
                        onClick={() =>
                          statusMutation.mutate({
                            id: user.id,
                            disabled: !user.disabled,
                          })
                        }
                        disabled={statusMutation.isPending}
                        className={cn(
                          'text-xs font-medium px-2.5 py-1 rounded-md transition-colors disabled:opacity-50',
                          !user.disabled
                            ? 'bg-red-50 text-red-600 hover:bg-red-100'
                            : 'bg-green-50 text-green-600 hover:bg-green-100'
                        )}
                      >
                        {user.disabled ? 'Unban' : 'Ban'}
                      </button>
                    </td>
                  </tr>
                  {expandedUsers.has(user.id) && (
                    <DevicesRow
                      key={`devices-${user.id}`}
                      userId={user.id}
                      onRevoke={() => qc.invalidateQueries({ queryKey: ['users'] })}
                    />
                  )}
                </>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between text-sm text-slate-600">
          <span>
            Page {page} of {totalPages} ({total.toLocaleString()} users)
          </span>
          <div className="flex items-center gap-1">
            <button
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page === 1}
              className="px-3 py-1.5 border border-slate-300 rounded-lg hover:bg-slate-50 disabled:opacity-40 transition-colors"
            >
              ← Prev
            </button>
            <button
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              disabled={page === totalPages}
              className="px-3 py-1.5 border border-slate-300 rounded-lg hover:bg-slate-50 disabled:opacity-40 transition-colors"
            >
              Next →
            </button>
          </div>
        </div>
      )}
    </div>
  )
}

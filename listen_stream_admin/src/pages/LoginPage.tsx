import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router'
import { useMutation, useQuery } from '@tanstack/react-query'
import { login } from '@/api/auth'
import { getSetupStatus } from '@/api/setup'
import { useAuthStore } from '@/stores/authStore'

export function LoginPage() {
  const navigate = useNavigate()
  const token = useAuthStore((s) => s.token)
  const setToken = useAuthStore((s) => s.setToken)

  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [totpCode, setTotpCode] = useState('')
  const [showTotp, setShowTotp] = useState(false)
  const [error, setError] = useState('')
  const [unlockAt, setUnlockAt] = useState<Date | null>(null)

  // Check if the system has been initialized; redirect to /setup if not.
  const { data: setupStatus, isLoading: setupLoading } = useQuery({
    queryKey: ['setup-status'],
    queryFn: getSetupStatus,
    retry: false,
  })

  const loginMutation = useMutation({
    mutationFn: login,
    onSuccess: (data) => {
      setToken(data.access_token)
      // navigation is driven by the useEffect above
    },
    onError: (err: any) => {
      const code = err.response?.data?.code
      const msg = err.response?.data?.message ?? 'Login failed'

      if (code === 'TOTP_REQUIRED') {
        setShowTotp(true)
        setError('Please enter your TOTP code')
        return
      }

      if (code === 'ACCOUNT_LOCKED' && err.response?.data?.unlock_at) {
        setUnlockAt(new Date(err.response.data.unlock_at))
        setError('')
        return
      }

      setError(msg)
    },
  })

  useEffect(() => {
    if (setupStatus && !setupStatus.initialized) {
      navigate('/setup', { replace: true })
    }
  }, [setupStatus, navigate])

  // Redirect as soon as a token appears in the store (handles both
  // "just logged in" and "already logged in" on page load).
  useEffect(() => {
    if (token) {
      navigate('/dashboard', { replace: true })
    }
  }, [token, navigate])

  if (setupLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-slate-500">Checking system status…</div>
      </div>
    )
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    setUnlockAt(null)
    loginMutation.mutate({
      username,
      password,
      totp_code: showTotp ? totpCode : undefined,
    })
  }

  const isLocked = unlockAt !== null && unlockAt > new Date()

  return (
    <div className="min-h-screen bg-slate-50 flex items-center justify-center px-4">
      <div className="w-full max-w-sm bg-white rounded-xl shadow-md overflow-hidden">
        <div className="bg-slate-900 px-6 py-5">
          <h1 className="text-white text-lg font-semibold">ListenStream Admin</h1>
          <p className="text-slate-400 text-sm mt-0.5">Sign in to continue</p>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">Username</label>
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              required
              autoFocus
              disabled={isLocked}
              className="w-full border border-slate-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-slate-100"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              disabled={isLocked}
              className="w-full border border-slate-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-slate-100"
            />
          </div>

          {showTotp && (
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">TOTP Code</label>
              <input
                type="text"
                value={totpCode}
                onChange={(e) => setTotpCode(e.target.value)}
                maxLength={6}
                inputMode="numeric"
                autoFocus
                className="w-full border border-slate-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 font-mono tracking-widest"
                placeholder="000000"
              />
            </div>
          )}

          {error && (
            <p className="text-sm text-red-600 bg-red-50 border border-red-200 rounded px-3 py-2">
              {error}
            </p>
          )}

          {isLocked && (
            <div className="text-sm text-orange-700 bg-orange-50 border border-orange-200 rounded px-3 py-2">
              Account locked due to too many failed attempts.
              <br />
              Unlock at: <strong>{unlockAt!.toLocaleTimeString()}</strong>
            </div>
          )}

          <button
            type="submit"
            disabled={loginMutation.isPending || isLocked}
            className="w-full py-2.5 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 disabled:opacity-50 transition-colors"
          >
            {loginMutation.isPending ? 'Signing in…' : 'Sign In'}
          </button>
        </form>
      </div>
    </div>
  )
}

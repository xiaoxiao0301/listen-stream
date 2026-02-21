import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router'
import { useQuery, useMutation } from '@tanstack/react-query'
import { getSetupStatus, initSetup } from '@/api/setup'
import { cn } from '@/lib/utils'

type Step = 1 | 2 | 3 | 4

export function SetupPage() {
  const navigate = useNavigate()
  const [step, setStep] = useState<Step>(1)
  const [form, setForm] = useState({
    username: '',
    password: '',
    confirmPassword: '',
    sms_provider: 'none',
    sms_app_id: '',
    sms_app_key: '',
    sms_sign: '',
  })
  const [errors, setErrors] = useState<Record<string, string>>({})

  const { data: status, isLoading } = useQuery({
    queryKey: ['setup-status'],
    queryFn: getSetupStatus,
    retry: false,
  })

  useEffect(() => {
    if (status?.initialized) {
      navigate('/login')
    }
  }, [status, navigate])

  const initMutation = useMutation({
    mutationFn: initSetup,
    onSuccess: () => {
      setStep(4)
    },
    onError: (err: any) => {
      setErrors({ submit: err.response?.data?.message ?? 'Initialization failed' })
    },
  })

  function validateStep2() {
    const e: Record<string, string> = {}
    if (!form.username || form.username.length < 4) e.username = 'Username must be at least 4 characters'
    if (!form.password) e.password = 'Password is required'
    if (form.password !== form.confirmPassword) e.confirmPassword = 'Passwords do not match'
    setErrors(e)
    return Object.keys(e).length === 0
  }

  function handleNext() {
    if (step === 2 && !validateStep2()) return
    setStep((s) => Math.min(4, s + 1) as Step)
  }

  async function handleSubmit() {
    const smsConfig: Record<string, string> = {}
    if (form.sms_provider !== 'none') {
      smsConfig.app_id = form.sms_app_id
      smsConfig.app_key = form.sms_app_key
      smsConfig.sign = form.sms_sign
    }
    initMutation.mutate({
      username: form.username,
      password: form.password,
      totp_enabled: false,
      sms_provider: form.sms_provider === 'none' ? undefined : form.sms_provider,
      sms_config: form.sms_provider !== 'none' ? smsConfig : undefined,
    })
  }

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-slate-500">Checking system status…</div>
      </div>
    )
  }

  const steps = [
    { num: 1, label: 'Welcome' },
    { num: 2, label: 'Admin Account' },
    { num: 3, label: 'SMS Provider' },
    { num: 4, label: 'Complete' },
  ]

  return (
    <div className="min-h-screen bg-slate-50 flex items-center justify-center px-4">
      <div className="w-full max-w-lg bg-white rounded-xl shadow-md overflow-hidden">
        {/* Steps header */}
        <div className="bg-slate-900 px-6 py-5">
          <h1 className="text-white text-lg font-semibold mb-4">ListenStream Setup</h1>
          <div className="flex items-center gap-2">
            {steps.map((s, i) => (
              <div key={s.num} className="flex items-center gap-2">
                <div
                  className={cn(
                    'w-7 h-7 rounded-full flex items-center justify-center text-xs font-semibold',
                    step > s.num
                      ? 'bg-green-500 text-white'
                      : step === s.num
                      ? 'bg-blue-500 text-white'
                      : 'bg-slate-700 text-slate-400'
                  )}
                >
                  {step > s.num ? '✓' : s.num}
                </div>
                <span
                  className={cn(
                    'text-xs',
                    step === s.num ? 'text-white' : 'text-slate-400'
                  )}
                >
                  {s.label}
                </span>
                {i < steps.length - 1 && (
                  <div className={cn('h-px w-6 mx-1', step > s.num ? 'bg-green-500' : 'bg-slate-700')} />
                )}
              </div>
            ))}
          </div>
        </div>

        <div className="p-6">
          {/* Step 1 — Welcome */}
          {step === 1 && (
            <div className="space-y-4">
              <h2 className="text-xl font-semibold text-slate-800">Welcome!</h2>
              <p className="text-slate-600">
                This wizard will guide you through setting up your ListenStream admin account.
                You'll create a super-admin account and optionally configure an SMS provider.
              </p>
              <p className="text-sm text-slate-500 bg-slate-50 border border-slate-200 rounded p-3">
                This setup page is only accessible before the system is initialized. Once complete,
                it will redirect to the login page.
              </p>
              <div className="pt-2 flex justify-end">
                <button
                  onClick={handleNext}
                  className="px-5 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors"
                >
                  Get Started →
                </button>
              </div>
            </div>
          )}

          {/* Step 2 — Admin Account */}
          {step === 2 && (
            <div className="space-y-4">
              <h2 className="text-xl font-semibold text-slate-800">Create Admin Account</h2>
              <p className="text-sm text-slate-500">
                Password must be at least 12 characters and include uppercase, lowercase, digits,
                and special characters.
              </p>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Username</label>
                <input
                  type="text"
                  autoComplete="off"
                  value={form.username}
                  onChange={(e) => setForm((f) => ({ ...f, username: e.target.value }))}
                  className="w-full border border-slate-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="admin"
                />
                {errors.username && <p className="text-red-500 text-xs mt-1">{errors.username}</p>}
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Password</label>
                <input
                  type="password"
                  autoComplete="new-password"
                  value={form.password}
                  onChange={(e) => setForm((f) => ({ ...f, password: e.target.value }))}
                  className="w-full border border-slate-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
                {errors.password && <p className="text-red-500 text-xs mt-1">{errors.password}</p>}
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Confirm Password</label>
                <input
                  type="password"
                  autoComplete="new-password"
                  value={form.confirmPassword}
                  onChange={(e) => setForm((f) => ({ ...f, confirmPassword: e.target.value }))}
                  className="w-full border border-slate-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
                {errors.confirmPassword && <p className="text-red-500 text-xs mt-1">{errors.confirmPassword}</p>}
              </div>
              <div className="pt-2 flex justify-between">
                <button
                  onClick={() => setStep(1)}
                  className="px-5 py-2 border border-slate-300 text-slate-700 rounded-lg text-sm hover:bg-slate-50 transition-colors"
                >
                  ← Back
                </button>
                <button
                  onClick={handleNext}
                  className="px-5 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors"
                >
                  Next →
                </button>
              </div>
            </div>
          )}

          {/* Step 3 — SMS Provider */}
          {step === 3 && (
            <div className="space-y-4">
              <h2 className="text-xl font-semibold text-slate-800">SMS Provider (Optional)</h2>
              <p className="text-sm text-slate-500">
                Configure an SMS provider to allow phone number registration/login for users.
                You can skip this and configure it later in Settings.
              </p>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Provider</label>
                <select
                  value={form.sms_provider}
                  onChange={(e) => setForm((f) => ({ ...f, sms_provider: e.target.value }))}
                  className="w-full border border-slate-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="none">Skip (no SMS)</option>
                  <option value="tencent">Tencent Cloud SMS</option>
                  <option value="aliyun">Alibaba Cloud SMS</option>
                </select>
              </div>
              {form.sms_provider !== 'none' && (
                <>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">App ID</label>
                    <input
                      type="text"
                      value={form.sms_app_id}
                      onChange={(e) => setForm((f) => ({ ...f, sms_app_id: e.target.value }))}
                      className="w-full border border-slate-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">App Key / Secret</label>
                    <input
                      type="password"
                      value={form.sms_app_key}
                      onChange={(e) => setForm((f) => ({ ...f, sms_app_key: e.target.value }))}
                      className="w-full border border-slate-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">SMS Sign</label>
                    <input
                      type="text"
                      value={form.sms_sign}
                      onChange={(e) => setForm((f) => ({ ...f, sms_sign: e.target.value }))}
                      className="w-full border border-slate-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                </>
              )}
              {errors.submit && (
                <p className="text-red-500 text-sm bg-red-50 border border-red-200 rounded p-3">
                  {errors.submit}
                </p>
              )}
              <div className="pt-2 flex justify-between">
                <button
                  onClick={() => setStep(2)}
                  className="px-5 py-2 border border-slate-300 text-slate-700 rounded-lg text-sm hover:bg-slate-50 transition-colors"
                >
                  ← Back
                </button>
                <button
                  onClick={handleSubmit}
                  disabled={initMutation.isPending}
                  className="px-5 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 disabled:opacity-50 transition-colors"
                >
                  {initMutation.isPending ? 'Initializing…' : 'Complete Setup →'}
                </button>
              </div>
            </div>
          )}

          {/* Step 4 — Complete */}
          {step === 4 && (
            <div className="space-y-4 text-center">
              <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto">
                <span className="text-3xl">✓</span>
              </div>
              <h2 className="text-xl font-semibold text-slate-800">Setup Complete!</h2>
              <p className="text-slate-600">
                Your admin account has been created. You can now log in to the admin console.
              </p>
              <button
                onClick={() => navigate('/login')}
                className="px-6 py-2.5 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors"
              >
                Go to Login
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

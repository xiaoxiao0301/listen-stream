import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Link } from 'react-router'
import { getSMSConfig, updateSMSConfig } from '@/api/config'
import { PageHeader } from '@/components/config/PageHeader'
import { StatusBanner } from '@/components/config/StatusBanner'
import { Eye, EyeOff, MessageSquare, ExternalLink } from 'lucide-react'
import { cn } from '@/lib/utils'

const PROVIDERS = [
  { value: 'aliyun',  label: '阿里云 SMS' },
  { value: 'tencent', label: '腾讯云 SMS' },
]

const PROVIDER_FIELDS: Record<string, { key: string; label: string; sensitive?: boolean; placeholder?: string }[]> = {
  aliyun: [
    { key: 'SMS_APP_ID',    label: 'AccessKey ID',  placeholder: 'LTAI...' },
    { key: 'SMS_APP_KEY',   label: 'AccessKey Secret', sensitive: true },
    { key: 'SMS_SIGN_NAME', label: '短信签名', placeholder: '你的应用名' },
    { key: 'SMS_TEMPLATE',  label: '模板 Code', placeholder: 'SMS_123456789' },
  ],
  tencent: [
    { key: 'SMS_APP_ID',    label: 'SDK AppID', placeholder: '1400...' },
    { key: 'SMS_APP_KEY',   label: 'App Key',   sensitive: true },
    { key: 'SMS_SIGN_NAME', label: '短信签名', placeholder: '你的应用名' },
    { key: 'SMS_TEMPLATE',  label: '模板 ID',  placeholder: '123456' },
  ],
}

export function SmsConfigPage() {
  const qc = useQueryClient()
  const [editing, setEditing] = useState(false)
  const [changes, setChanges] = useState<Record<string, string>>({})
  const [confirmOff, setConfirmOff] = useState(false)

  const { data: items = [], isLoading } = useQuery({
    queryKey: ['sms-config'],
    queryFn: getSMSConfig,
  })

  const saveMutation = useMutation({
    mutationFn: () => updateSMSConfig(changes),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['sms-config'] })
      setEditing(false)
      setChanges({})
      setConfirmOff(false)
    },
  })

  // Derive current values from query data + uncommitted changes
  function getValue(key: string) {
    return changes[key] ?? items.find((i) => i.key === key)?.value ?? ''
  }

  const provider = getValue('SMS_PROVIDER')
  const isDevMode = provider === '' || provider === 'dev'
  const prodProvider = PROVIDER_FIELDS[provider] ? provider : 'aliyun'
  const currentFields = PROVIDER_FIELDS[prodProvider]

  function handleToggle(on: boolean) {
    if (on) {
      // Switch to dev mode immediately
      setChanges({ SMS_PROVIDER: 'dev' })
      saveMutation.mutate()
    } else {
      // Show confirmation + provider selection
      setConfirmOff(true)
      setEditing(true)
      setChanges((c) => ({ ...c, SMS_PROVIDER: 'aliyun' }))
    }
  }

  function handleProviderChange(p: string) {
    setChanges((c) => ({ ...c, SMS_PROVIDER: p }))
  }

  function change(key: string, value: string) {
    setChanges((c) => ({ ...c, [key]: value }))
  }

  if (isLoading) {
    return (
      <div className="space-y-6">
        <PageHeader title="SMS Configuration" />
        <div className="bg-white border border-slate-200 rounded-lg h-32 animate-pulse" />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <PageHeader
        title="SMS Configuration"
        description="控制短信验证码的发送方式。开发模式下仅打印日志，生产模式需要配置 SMS 服务商。"
      />

      {/* Status Banners */}
      {saveMutation.isError && (
        <StatusBanner
          type="error"
          message={(saveMutation.error as any)?.response?.data?.message ?? '保存失败'}
          dismissible
          onDismiss={() => saveMutation.reset()}
        />
      )}

      {/* Dev mode toggle card */}
      <div className="bg-white rounded-lg border border-slate-200 p-6">
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-3">
            <div className={cn(
              'w-10 h-10 rounded-lg flex items-center justify-center',
              isDevMode ? 'bg-amber-100 text-amber-600' : 'bg-green-100 text-green-600'
            )}>
              <MessageSquare size={20} />
            </div>
            <div>
              <div className="font-semibold text-slate-900">
                {isDevMode ? '开发模式' : '生产模式'}
              </div>
              <div className="text-xs text-slate-500">
                {isDevMode
                  ? '验证码打印到 auth-svc 日志，不发送真实短信'
                  : `SMS 服务商：${PROVIDERS.find((p) => p.value === provider)?.label ?? provider}`}
              </div>
            </div>
          </div>

          {/* Toggle */}
          <button
            onClick={() => handleToggle(!isDevMode)}
            disabled={saveMutation.isPending}
            className={cn(
              'relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none disabled:opacity-50',
              isDevMode ? 'bg-amber-400' : 'bg-green-500'
            )}
          >
            <span className={cn(
              'inline-block h-4 w-4 transform rounded-full bg-white shadow transition-transform',
              isDevMode ? 'translate-x-1' : 'translate-x-6'
            )} />
          </button>
        </div>

        {isDevMode && (
          <div className="mt-4 flex items-center gap-2 text-sm text-amber-700 bg-amber-50 rounded-lg px-4 py-2.5">
            <span>开发模式已启用 — 验证码可在</span>
            <Link
              to="/sms-logs"
              className="inline-flex items-center gap-1 font-medium underline underline-offset-2 hover:text-amber-900"
            >
              SMS 日志 <ExternalLink size={12} />
            </Link>
            <span>中查看。关闭此开关将切换为真实短信发送。</span>
          </div>
        )}
      </div>

      {/* Production config panel (visible when not in dev mode OR when switching off) */}
      {(!isDevMode || editing) && (
        <div className="bg-white rounded-lg border border-slate-200 overflow-hidden">
          <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
            <span className="font-semibold text-slate-800">SMS 服务商配置</span>
            <div className="flex items-center gap-2">
              {editing ? (
                <>
                  <button
                    onClick={() => {
                      setEditing(false)
                      setChanges({})
                      setConfirmOff(false)
                    }}
                    className="px-3 py-1.5 border border-slate-300 text-slate-700 rounded-lg text-sm hover:bg-slate-50 transition-colors"
                  >
                    取消
                  </button>
                  <button
                    onClick={() => saveMutation.mutate()}
                    disabled={saveMutation.isPending || Object.keys(changes).length === 0}
                    className="px-4 py-1.5 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 disabled:opacity-50 transition-colors"
                  >
                    {saveMutation.isPending ? '保存中…' : '保存'}
                  </button>
                </>
              ) : (
                <button
                  onClick={() => setEditing(true)}
                  className="px-4 py-1.5 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors"
                >
                  编辑
                </button>
              )}
            </div>
          </div>

          <div className="p-6 space-y-5">
            {/* Provider selector */}
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-2">服务商</label>
              <div className="flex gap-2">
                {PROVIDERS.map((p) => (
                  <button
                    key={p.value}
                    disabled={!editing}
                    onClick={() => handleProviderChange(p.value)}
                    className={cn(
                      'px-4 py-2 rounded-lg text-sm border transition-colors',
                      getValue('SMS_PROVIDER') === p.value
                        ? 'border-blue-500 bg-blue-50 text-blue-700 font-medium'
                        : 'border-slate-300 text-slate-600 hover:bg-slate-50',
                      !editing && 'cursor-default opacity-70'
                    )}
                  >
                    {p.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Provider-specific fields */}
            {currentFields.map((field) => (
              <div key={field.key}>
                <label className="block text-sm font-medium text-slate-700 mb-1.5">
                  {field.label}
                  <span className="ml-1.5 font-mono text-xs text-slate-400">{field.key}</span>
                </label>
                {editing ? (
                  <SensitiveInput
                    sensitive={!!field.sensitive}
                    value={getValue(field.key)}
                    placeholder={field.placeholder}
                    onChange={(v) => change(field.key, v)}
                  />
                ) : (
                  <ReadonlyField sensitive={!!field.sensitive} value={getValue(field.key)} />
                )}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

function SensitiveInput({
  sensitive,
  value,
  placeholder,
  onChange,
}: {
  sensitive: boolean
  value: string
  placeholder?: string
  onChange: (v: string) => void
}) {
  const [show, setShow] = useState(false)
  return (
    <div className="flex items-center gap-1.5">
      <input
        type={sensitive && !show ? 'password' : 'text'}
        value={value}
        placeholder={placeholder}
        onChange={(e) => onChange(e.target.value)}
        className="flex-1 border border-slate-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 font-mono"
      />
      {sensitive && (
        <button onClick={() => setShow((s) => !s)} className="text-slate-400 hover:text-slate-600 p-1">
          {show ? <EyeOff size={15} /> : <Eye size={15} />}
        </button>
      )}
    </div>
  )
}

function ReadonlyField({ sensitive, value }: { sensitive: boolean; value: string }) {
  const [show, setShow] = useState(false)
  const display = sensitive && !show && value
    ? value.slice(0, 3) + '•'.repeat(Math.min(value.length - 4, 16)) + value.slice(-1)
    : value
  return (
    <div className="flex items-center gap-1.5">
      <span className="font-mono text-sm text-slate-800 flex-1 break-all">{display || '—'}</span>
      {sensitive && value && (
        <button onClick={() => setShow((s) => !s)} className="text-slate-400 hover:text-slate-600 p-1">
          {show ? <EyeOff size={13} /> : <Eye size={13} />}
        </button>
      )}
    </div>
  )
}

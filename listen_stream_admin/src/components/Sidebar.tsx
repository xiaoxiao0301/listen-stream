import { NavLink, useNavigate } from 'react-router'
import { cn } from '@/lib/utils'
import { useAuthStore } from '@/stores/authStore'
import { logout } from '@/api/auth'
import {
  LayoutDashboard,
  Settings,
  KeyRound,
  MessageSquare,
  Inbox,
  Users,
  ScrollText,
  LogOut,
} from 'lucide-react'

const navItems = [
  { to: '/dashboard',  icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/api-config', icon: Settings,         label: 'API Config' },
  { to: '/jwt-config', icon: KeyRound,         label: 'JWT Config' },
  { to: '/sms-config', icon: MessageSquare,    label: 'SMS Config' },
  { to: '/sms-logs',   icon: Inbox,            label: 'SMS 日志' },
  { to: '/users',      icon: Users,            label: 'Users' },
  { to: '/logs',       icon: ScrollText,       label: 'Logs' },
]

export function Sidebar() {
  const clearToken = useAuthStore((s) => s.clearToken)
  const navigate = useNavigate()

  async function handleLogout() {
    try {
      await logout()
    } catch {}
    clearToken()
    navigate('/login')
  }

  return (
    <aside className="w-56 shrink-0 bg-slate-900 text-slate-100 flex flex-col h-screen sticky top-0">
      <div className="px-6 py-5 border-b border-slate-700">
        <span className="text-lg font-semibold tracking-tight">ListenStream</span>
        <span className="block text-xs text-slate-400 mt-0.5">Admin Console</span>
      </div>

      <nav className="flex-1 py-4 space-y-1 overflow-y-auto">
        {navItems.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            className={({ isActive }: { isActive: boolean }) =>
              cn(
                'flex items-center gap-3 px-5 py-2.5 text-sm transition-colors',
                isActive
                  ? 'bg-slate-700 text-white font-medium'
                  : 'text-slate-400 hover:text-white hover:bg-slate-800'
              )
            }
          >
            <Icon size={16} />
            {label}
          </NavLink>
        ))}
      </nav>

      <div className="px-4 py-4 border-t border-slate-700">
        <button
          onClick={handleLogout}
          className="flex w-full items-center gap-3 px-3 py-2 text-sm text-slate-400 hover:text-white hover:bg-slate-800 rounded transition-colors"
        >
          <LogOut size={16} />
          Logout
        </button>
      </div>
    </aside>
  )
}

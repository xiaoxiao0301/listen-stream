import { createBrowserRouter, Navigate } from 'react-router'
import { Layout } from '@/components/Layout'
import { ProtectedRoute } from '@/components/ProtectedRoute'
import { SetupPage } from '@/pages/SetupPage'
import { LoginPage } from '@/pages/LoginPage'
import { DashboardPage } from '@/pages/DashboardPage'
import { ApiConfigPage } from '@/pages/ApiConfigPage'
import { JwtConfigPage } from '@/pages/JwtConfigPage'
import { SmsConfigPage } from '@/pages/SmsConfigPage'
import { SmsLogsPage } from '@/pages/SmsLogsPage'
import { UsersPage } from '@/pages/UsersPage'
import { LogsPage } from '@/pages/LogsPage'

export const router = createBrowserRouter([
  {
    path: '/setup',
    element: <SetupPage />,
  },
  {
    path: '/login',
    element: <LoginPage />,
  },
  {
    path: '/',
    element: (
      <ProtectedRoute>
        <Layout />
      </ProtectedRoute>
    ),
    children: [
      { index: true, element: <Navigate to="/dashboard" replace /> },
      { path: 'dashboard',  element: <DashboardPage /> },
      { path: 'api-config', element: <ApiConfigPage /> },
      { path: 'jwt-config', element: <JwtConfigPage /> },
      { path: 'sms-config', element: <SmsConfigPage /> },
      { path: 'sms-logs',   element: <SmsLogsPage /> },
      { path: 'users',      element: <UsersPage /> },
      { path: 'logs',       element: <LogsPage /> },
    ],
  },
  {
    path: '*',
    element: <Navigate to="/dashboard" replace />,
  },
])

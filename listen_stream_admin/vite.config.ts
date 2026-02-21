import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import path from 'path'

export default defineConfig({
  plugins: [
    react(),
    tailwindcss(),
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 5173,
    proxy: {
      '/admin': {
        target: 'http://localhost:8004',
        changeOrigin: true,
        // Only proxy API/XHR calls. Browser navigations (Accept: text/html)
        // must be served by Vite so the SPA router handles the URL.
        bypass(req) {
          if (req.headers['accept']?.includes('text/html')) {
            return '/index.html'
          }
        },
      },
    },
  },
})

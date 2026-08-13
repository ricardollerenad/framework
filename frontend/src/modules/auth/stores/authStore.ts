import { defineStore } from 'pinia'
import authService from '../services/authService.js'

interface UserProfile {
  id: number
  username: string
  email: string
  first_name: string
  last_name: string
}

export const useAuthStore = defineStore('auth', {
  state: () => ({
    user: null as UserProfile | null,
    accessToken: localStorage.getItem('access_token') as string | null,
    refreshToken: localStorage.getItem('refresh_token') as string | null,
  }),

  getters: {
    isAuthenticated: (state) => !!state.accessToken,
  },

  actions: {
    async login(username: string, password: string) {
      const { data } = await authService.login(username, password)
      this.accessToken = data.access
      this.refreshToken = data.refresh
      localStorage.setItem('access_token', data.access)
      localStorage.setItem('refresh_token', data.refresh)
      await this.fetchMe()
    },

    async fetchMe() {
      const { data } = await authService.me()
      this.user = data
    },

    async logout() {
      try {
        if (this.refreshToken) {
          await authService.logout(this.refreshToken)
        }
      } catch {
        // Si el logout en backend falla (token ya vencido, etc.), igual limpiamos sesion local
      }
      this.user = null
      this.accessToken = null
      this.refreshToken = null
      localStorage.removeItem('access_token')
      localStorage.removeItem('refresh_token')
    },
  },
})

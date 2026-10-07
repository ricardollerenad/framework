import { defineStore } from 'pinia'
import axios from 'axios'

export const useAuthStore = defineStore('auth', {
  state: () => ({
    accessToken: '' as string,
    roles: [] as string[],
    username: '' as string,
  }),
  actions: {
    async fetchMe() {
      const { data } = await axios.get('/api/auth/me/')
      this.username = data.username
      this.roles = data.roles
    },
    hasRole(rol: string) {
      return this.roles.includes(rol)
    }
  }
})
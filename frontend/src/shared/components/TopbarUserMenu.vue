<template>
  <div class="flex items-center space-x-3" style="border 2px red solid">
    <span class="text-sm text-gray-700 font-medium">
      {{ authStore.user?.username || 'Usuario' }}
    </span>
    <button
      @click="handleLogout"
      class="text-xs text-red-600 hover:text-red-700 font-medium px-3 py-1.5 rounded-lg hover:bg-red-50 transition-colors"
    >
      Cerrar sesión
    </button>
  </div>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useAuthStore } from '../../modules/auth/stores/authStore.js'

const authStore = useAuthStore()
const router = useRouter()

async function handleLogout() {
  await authStore.logout()
  router.push('/login')
}
</script>

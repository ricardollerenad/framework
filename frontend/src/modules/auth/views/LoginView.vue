<template>
  <div class="min-h-screen grid grid-cols-1 lg:grid-cols-12 bg-[#F8FAFC]">
    
    <!-- COLUMNA IZQUIERDA: 1/3 (4 de 12 col) - Impacto visual con la foto de Arequipa, aplicando jerarquía visual y teoría del color (contraste sillar/cielo con overlay anaranjado suave para acentuar el atardecer) -->
    <div class="lg:col-span-4 relative overflow-hidden bg-[#1E293B] min-h-[320px] lg:min-h-screen flex flex-col justify-between p-8 xl:p-12">
      <!-- Imagen de fondo optimizada con escala y nitidez -->
      <img src="/imagen_login.jpg" alt="Arequipa Atardecer" class="absolute inset-0 w-full h-full object-cover object-center filter contrast-105 brightness-95 scale-100" />
      
      <!-- Overlay con gradiente basado en la hora dorada (tonos cálidos sutiles que armonizan con la piedra sillar) -->
      <div class="absolute inset-0 bg-gradient-to-t from-[#0F172A]/90 via-[#0F172A]/40 to-amber-950/20 backdrop-blur-[1px]"></div>
      
      <!-- Elemento UX superior: Distintivo de marca / contexto sutil -->
      <div class="relative z-10 flex items-center justify-between">
        <div class="px-3.5 py-1.5 bg-white/10 backdrop-blur-md border border-white/15 rounded-full text-amber-100/90 text-xs font-medium tracking-wider uppercase shadow-sm">
          NOSOTROS
        </div>
      </div>
    </div>

    <!-- COLUMNA DERECHA: 2/3 (8 de 12 col) - Formulario UX/UI optimizado con principios de accesibilidad (F-pattern / Z-pattern) -->
    <div class="lg:col-span-8 flex items-center justify-center p-6 sm:p-12 lg:p-16">
      <div class="w-full max-w-md space-y-6 sm:space-y-8 bg-white p-8 sm:p-10 rounded-3xl shadow-2xl shadow-slate-900/5 border border-slate-100/80">
        
        <div class="space-y-1.5">
          <h2 class="text-xl sm:text-2xl font-bold tracking-tight text-slate-900">Iniciar Sesión</h2>
          <p class="text-xs sm:text-sm text-slate-500">Ingrese sus credenciales institucionales para continuar.</p>
        </div>

        <form @submit.prevent="handleSubmit" class="space-y-5">
          <div class="space-y-1.5">
            <label class="block text-xs font-semibold text-slate-600 uppercase tracking-wider">Usuario</label>
            <div class="relative">
              <span class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                </svg>
              </span>
              <input v-model="username" type="text" required placeholder="Ingrese su usuario"
                class="w-full pl-10 pr-4 py-3 text-sm bg-slate-50/50 border border-slate-200 rounded-2xl text-slate-800 placeholder-slate-400 focus:bg-white focus:outline-none focus:ring-2 focus:ring-amber-500/20 focus:border-amber-600 transition-all duration-300" />
            </div>
          </div>

          <div class="space-y-1.5">
            <label class="block text-xs font-semibold text-slate-600 uppercase tracking-wider">Contraseña</label>
            <div class="relative">
              <span class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                </svg>
              </span>
              <input v-model="password" type="password" required placeholder="••••••••"
                class="w-full pl-10 pr-4 py-3 text-sm bg-slate-50/50 border border-slate-200 rounded-2xl text-slate-800 placeholder-slate-400 focus:bg-white focus:outline-none focus:ring-2 focus:ring-amber-500/20 focus:border-amber-600 transition-all duration-300" />
            </div>
          </div>

          <div v-if="errorMessage" class="p-3.5 text-sm text-rose-600 bg-rose-50 border border-rose-100 rounded-2xl flex items-center space-x-2.5 transition-all duration-300">
            <svg class="w-4 h-4 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span>{{ errorMessage }}</span>
          </div>

          <!-- Botón de acción con color complementario cálido (inspirado en la iluminación de la Basílica Catedral en el atardecer) -->
          <button type="submit" :disabled="loading"
            class="w-full bg-slate-900 text-white font-medium py-3.5 px-4 rounded-2xl hover:bg-slate-800 focus:outline-none focus:ring-4 focus:ring-slate-900/10 transition-all duration-300 shadow-lg shadow-slate-900/10 disabled:opacity-50 disabled:cursor-not-allowed">
            {{ loading ? 'Verificando acceso...' : 'Acceder al Sistema' }}
          </button>
        </form>

      </div>
    </div>

  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '../stores/authStore.js'

const username = ref('')
const password = ref('')
const loading = ref(false)
const errorMessage = ref('')

const authStore = useAuthStore()
const router = useRouter()
const route = useRoute()

async function handleSubmit() {
  loading.value = true
  errorMessage.value = ''
  try {
    await authStore.login(username.value, password.value)
    const redirect = (route.query.redirect as string) || '/'
    router.push(redirect)
  } catch (err) {
    errorMessage.value = 'Usuario o contraseña incorrectos.'
  } finally {
    loading.value = false
  }
}
</script>
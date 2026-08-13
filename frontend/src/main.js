import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import { useAuthStore } from './modules/auth/stores/authStore'
import './style.css'

const app = createApp(App)
app.use(createPinia())
app.use(router)

const authStore = useAuthStore()
if (authStore.isAuthenticated) {
  authStore.fetchMe().catch(() => {
    // Si el token guardado ya no es valido, el interceptor de axios se encarga de redirigir a /login
  })
}

app.mount('#app')

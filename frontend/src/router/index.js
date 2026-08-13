import { createRouter, createWebHistory } from 'vue-router'
import dashboardRoutes from '../modules/dashboard/routes.js'
import authRoutes from '../modules/auth/routes.js'
import LayoutMain from '../layouts/LayoutMain.vue'
import { useAuthStore } from '../modules/auth/stores/authStore.js'

const routes = [
  ...authRoutes,
  {
    path: '/',
    component: LayoutMain,
    meta: { requiresAuth: true },
    children: [
      { path: '', redirect: '/dashboard/resumen' },
      ...dashboardRoutes,
    ],
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()

  if (to.meta.requiresAuth !== false && !authStore.isAuthenticated) {
    next({ name: 'login', query: { redirect: to.fullPath } })
  } else if (to.name === 'login' && authStore.isAuthenticated) {
    next('/')
  } else {
    next()
  }
})

export default router

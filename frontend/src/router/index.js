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
  {
    path: '/administracion',
    component: () => import('@/modules/administracion/views/Panel.vue'),
    meta: { requiresAuth: true, roles: ['Administrador'] }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach((to, from, next) => {
  const auth = useAuthStore()
  if (to.meta.requiresAuth && !auth.accessToken) {
    return next('/login')
  }
  if (to.meta.roles && !to.meta.roles.some(r => auth.hasRole(r))) {
    return next('/no-autorizado')   // o a donde tenga sentido
  }
  next()
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

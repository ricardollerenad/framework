import { createRouter, createWebHistory } from 'vue-router'
import dashboardRoutes from '../modules/dashboard/routes.js'

const routes = [
  { path: '/', redirect: '/dashboard/resumen' },
  ...dashboardRoutes,
]

export default createRouter({
  history: createWebHistory(),
  routes,
})

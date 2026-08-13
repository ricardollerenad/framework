import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { useRoute } from 'vue-router'

export const useNavigationStore = defineStore('navigation', () => {
  const route = useRoute()
  const manualActiveMenuKey = ref('dashboard')

  const menuItems = ref([
    {
      key: 'dashboard',
      label: 'Dashboard Principal',
      submenus: [
        { key: 'resumen', label: 'Resumen General', path: '/dashboard/resumen' },
      ]
    },
  ])

  const activeMenuItem = computed(() => {
    const matched = menuItems.value.find(item =>
      item.submenus.some(sub => route.path.startsWith(sub.path))
    )
    return matched || menuItems.value.find(i => i.key === manualActiveMenuKey.value) || menuItems.value[0]
  })

  const activeMenuKey = computed(() => activeMenuItem.value.key)

  function setActiveMenu(key) {
    manualActiveMenuKey.value = key
  }

  return { menuItems, activeMenuItem, activeMenuKey, manualActiveMenuKey, setActiveMenu }
})

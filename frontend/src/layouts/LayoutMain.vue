<template>
  <div class="flex h-screen bg-gray-100 overflow-hidden font-sans">
    <aside class="w-64 bg-slate-900 text-white flex flex-col flex-shrink-0 shadow-lg">
      <div class="h-16 flex items-center justify-center border-b border-slate-800 font-bold text-lg tracking-wider text-indigo-400">
        MI FRAMEWORK
      </div>
      <nav class="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
        <button
          v-for="item in navStore.menuItems"
          :key="item.key"
          @click="navStore.setActiveMenu(item.key)"
          :class="[
            navStore.activeMenuKey === item.key
              ? 'bg-indigo-600 text-white font-medium shadow'
              : 'text-slate-300 hover:bg-slate-800 hover:text-white',
            'w-full flex items-center px-4 py-3 rounded-lg text-left transition-colors text-sm'
          ]"
        >
          <span>{{ item.label }}</span>
        </button>
      </nav>
    </aside>

    <div class="flex-1 flex flex-col min-w-0 overflow-hidden">
      <header class="bg-white border-b border-gray-200 shadow-sm z-10">
        <div class="px-6 flex items-center justify-between h-14">
          <div class="flex space-x-6 overflow-x-auto no-scrollbar">
            <router-link
              v-for="sub in navStore.activeMenuItem.submenus"
              :key="sub.key"
              :to="sub.path"
              class="text-sm font-medium text-gray-600 hover:text-indigo-600 py-4 border-b-2 border-transparent hover:border-indigo-600 transition-all whitespace-nowrap"
              active-class="border-indigo-600 text-indigo-600 font-semibold"
            >
              {{ sub.label }}
            </router-link>
          </div>
          <div class="flex items-center space-x-3 border-l pl-4">
            <span class="text-xs text-gray-500">Usuario Activo</span>
          </div>
        </div>
      </header>

      <main class="flex-1 overflow-y-auto p-6 bg-gray-50">
        <router-view />
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useNavigationStore } from '@/stores/navigation'
const navStore = useNavigationStore()
</script>

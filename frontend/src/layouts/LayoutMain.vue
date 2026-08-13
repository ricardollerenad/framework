<template>
  <div class="flex h-screen bg-[#F2F0ED] overflow-hidden font-sans">
    
    <!-- ASIDE (Barra lateral): Estilo limpio basado en la paleta institucional -->
    <aside class="w-64 bg-[#FAF9F7] text-[#2B2B30] flex flex-col flex-shrink-0 shadow-sm border-r border-[#D6D3D0]/60">
      
      <!-- LOGO SECTOR: Proporción armónica basada en sección áurea (aprox 1.618 con contenedor de 88px y elemento de 54px), perfectamente circular y centrado -->
      <div class="h-[110px] flex items-center justify-center px-6 border-b border-[#D6D3D0]/40">
        <div class="w-[110px] h-[110px] rounded-full overflow-hidden border-2 border-[#D6D3D0] shadow-sm flex-shrink-0 bg-white flex items-center justify-center">
          <img src="/logo.jpg" alt="Logo" class="w-full h-full object-cover scale-105" />
        </div>
      </div>

      <!-- NAVIGATION: Enlaces basados en tu store existente -->
      <nav class="flex-1 px-4 py-5 space-y-1.5 overflow-y-auto">
        <button
          v-for="item in navStore.menuItems"
          :key="item.key"
          @click="navStore.setActiveMenu(item.key)"
          :class="[
            navStore.activeMenuKey === item.key
              ? 'bg-[#C53030]/10 text-[#C53030] font-semibold border border-[#C53030]/20 shadow-xs'
              : 'text-[#7A7980] hover:bg-[#2B2B30]/5 hover:text-[#2B2B30]',
            'w-full flex items-center px-4 py-3 rounded-xl text-left transition-all duration-200 text-sm'
          ]"
        >
          <span>{{ item.label }}</span>
        </button>
      </nav>
    </aside>

    <!-- CONTENT WRAPPER -->
    <div class="flex-1 flex flex-col min-w-0 overflow-hidden">
      
      <!-- HEADER: Con submenús y el componente TopbarUserMenu ya existente -->
      <header class="bg-[#FAF9F7] border-b border-[#D6D3D0]/60 shadow-xs z-10">
        <div class="px-6 flex items-center justify-between h-20">
          
          <!-- SUBMENÚS -->
          <div class="flex space-x-6 overflow-x-auto no-scrollbar">
            <router-link
              v-for="sub in navStore.activeMenuItem.submenus"
              :key="sub.key"
              :to="sub.path"
              class="text-sm font-medium text-[#7A7980] hover:text-[#2B2B30] py-6 border-b-2 border-transparent hover:border-[#C53030] transition-all whitespace-nowrap"
              active-class="border-[#C53030] text-[#2B2B30] font-semibold"
            >
              {{ sub.label }}
            </router-link>
          </div>

          <!-- COMPONENTE DE USUARIO Y LOGOUT -->
          <div class="flex items-center pl-6 border-l border-[#D6D3D0]/60">
            <TopbarUserMenu />
          </div>

        </div>
      </header>

      <!-- MAIN VIEW -->
      <main class="flex-1 overflow-y-auto p-6 lg:p-8 bg-[#F2F0ED]">
        <router-view />
      </main>
      
    </div>
  </div>
</template>

<script setup lang="ts">
import { useNavigationStore } from '@/stores/navigation'
import TopbarUserMenu from '@/shared/components/TopbarUserMenu.vue'

const navStore = useNavigationStore()
</script>
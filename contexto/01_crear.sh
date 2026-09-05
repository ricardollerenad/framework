#!/usr/bin/env bash
###############################################################################
# 01-scaffold.sh (Versión Completa e Interactiva)
###############################################################################
set -euo pipefail

echo "--- Configuración Inicial del Proyecto ---"
read -p "Nombre de la carpeta del proyecto (ej: framework): " PROJECT_NAME
read -p "Dominio principal (ej: tudominio.com): " DOMAIN_NAME
read -p "Usuario para Postgres (ej: framework_user): " DB_USER
read -s -p "Password para Postgres: " DB_PASS
echo ""

if [ -d "$PROJECT_NAME" ]; then
  echo "❌ La carpeta '$PROJECT_NAME' ya existe. Elige otro nombre o bórrala."
  exit 1
fi

echo "📦 Creando proyecto en ./$PROJECT_NAME ..."
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

mkdir -p backend/core backend/api/migrations backend/staticfiles backend/media
mkdir -p frontend/src/components frontend/src/stores frontend/src/router frontend/src/views
mkdir -p integrations

BACKEND_PORT=8001
FRONTEND_PORT=8081
ADMINER_PORT=8082

# -----------------------------------------------------------------------------
# .env / .gitignore
# -----------------------------------------------------------------------------
cat > .env <<EOF
DOMAIN_NAME=${DOMAIN_NAME}
DJANGO_SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(50))")
DJANGO_DEBUG=False
DJANGO_ALLOWED_HOSTS=${DOMAIN_NAME},127.0.0.1,localhost
CORS_ALLOWED_ORIGINS=https://${DOMAIN_NAME}
POSTGRES_DB=framework_db
POSTGRES_USER=${DB_USER}
POSTGRES_PASSWORD=${DB_PASS}
BACKEND_PORT=${BACKEND_PORT}
FRONTEND_PORT=${FRONTEND_PORT}
ADMINER_PORT=${ADMINER_PORT}
EOF

cat > .gitignore <<'EOF'
.env
__pycache__/
*.pyc
backend/staticfiles/
backend/media/
node_modules/
frontend/dist/
.DS_Store
EOF

# -----------------------------------------------------------------------------
# docker-compose.yml
# -----------------------------------------------------------------------------
cat > docker-compose.yml <<'EOF'
services:
  db:
    image: postgres:15-alpine
    container_name: ${COMPOSE_PROJECT_NAME:-framework}_db
    restart: always
    env_file: [.env]
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data

  adminer:
    image: adminer:latest
    container_name: ${COMPOSE_PROJECT_NAME:-framework}_adminer
    restart: always
    environment:
      ADMINER_DEFAULT_SERVER: db
    ports:
      - "127.0.0.1:${ADMINER_PORT}:8080"
    depends_on: [db]

  backend:
    build: ./backend
    container_name: ${COMPOSE_PROJECT_NAME:-framework}_backend
    restart: always
    command: gunicorn core.wsgi:application --bind 0.0.0.0:8000
    env_file: [.env]
    environment:
      - DATABASE_URL=postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}
    ports:
      - "127.0.0.1:${BACKEND_PORT}:8000"
    volumes:
      - ./backend/staticfiles:/app/staticfiles
      - ./backend/media:/app/media
    depends_on: [db]

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: ${COMPOSE_PROJECT_NAME:-framework}_frontend
    restart: always
    ports:
      - "127.0.0.1:${FRONTEND_PORT}:80"

volumes:
  postgres_data:
EOF

# -----------------------------------------------------------------------------
# BACKEND
# -----------------------------------------------------------------------------
cat > backend/requirements.txt <<'EOF'
Django>=4.2,<5.0
djangorestframework>=3.14.0
djangorestframework-simplejwt>=5.3.0
django-cors-headers>=4.0.0
psycopg2-binary>=2.9.6
gunicorn>=21.2.0
dj-database-url>=2.1.0
python-decouple>=3.8
EOF

cat > backend/entrypoint.sh <<'EOF'
#!/bin/sh
set -e

echo "Esperando a la base de datos PostgreSQL..."
while ! nc -z db 5432; do
  sleep 0.5
done
echo "PostgreSQL listo."

echo "Ejecutando migraciones de Django..."
python manage.py migrate --noinput

echo "Recolectando archivos estaticos..."
python manage.py collectstatic --noinput

exec "$@"
EOF
chmod +x backend/entrypoint.sh

cat > backend/Dockerfile <<'EOF'
FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y netcat-openbsd gcc libpq-dev && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

COPY . /app/

RUN chmod +x /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
EOF

cat > backend/manage.py <<'EOF'
#!/usr/bin/env python
import os
import sys

def main():
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "No se pudo importar Django. ¿Esta activo el entorno virtual?"
        ) from exc
    execute_from_command_line(sys.argv)

if __name__ == '__main__':
    main()
EOF

touch backend/core/__init__.py backend/api/__init__.py backend/api/migrations/__init__.py

cat > backend/core/wsgi.py <<'EOF'
import os
from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
application = get_wsgi_application()
EOF

cat > backend/core/asgi.py <<'EOF'
import os
from django.core.asgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
application = get_wsgi_application()
EOF

cat > backend/core/urls.py <<'EOF'
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('api.urls')),
]
EOF

cat > backend/core/settings.py <<'EOF'
import os
from pathlib import Path
import dj_database_url
from decouple import config

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = config('DJANGO_SECRET_KEY')
DEBUG = config('DJANGO_DEBUG', default=False, cast=bool)
ALLOWED_HOSTS = config('DJANGO_ALLOWED_HOSTS', default='127.0.0.1,localhost').split(',')

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    'rest_framework',
    'rest_framework_simplejwt',
    'corsheaders',

    'api',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'core.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'core.wsgi.application'
ASGI_APPLICATION = 'core.asgi.application'

DATABASES = {
    'default': dj_database_url.config(
        default=config('DATABASE_URL'),
        conn_max_age=600,
    )
}

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LANGUAGE_CODE = 'es-pe'
TIME_ZONE = 'America/Lima'
USE_I18N = True
USE_TZ = True

STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

REST_FRAMEWORK = {
    'DEFAULT_PERMISSION_CLASSES': ['rest_framework.permissions.IsAuthenticated'],
    'DEFAULT_AUTHENTICATION_CLASSES': ['rest_framework_simplejwt.authentication.JWTAuthentication'],
}

CORS_ALLOWED_ORIGINS = config(
    'CORS_ALLOWED_ORIGINS',
    default='http://localhost:5173'
).split(',')
CORS_ALLOW_CREDENTIALS = True
EOF

cat > backend/api/urls.py <<'EOF'
from django.urls import path
from .views import HealthCheckView

urlpatterns = [
    path('health/', HealthCheckView.as_view(), name='health-check'),
]
EOF

cat > backend/api/views.py <<'EOF'
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny


class HealthCheckView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        return Response({"status": "ok"})
EOF

cat > backend/api/serializers.py <<'EOF'
# Define aqui tus serializers de DRF
EOF

# -----------------------------------------------------------------------------
# FRONTEND (Vue 3 + Vite + TypeScript + Pinia + Vue Router + Tailwind)
# -----------------------------------------------------------------------------
cat > frontend/Dockerfile <<'EOF'
FROM node:18-alpine AS build-stage
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine AS production-stage
COPY --from=build-stage /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

cat > frontend/package.json <<'EOF'
{
  "name": "frontend",
  "version": "0.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vue-tsc --noEmit && vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "vue": "^3.4.0",
    "vue-router": "^4.2.0",
    "pinia": "^2.1.0",
    "axios": "^1.6.0"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^5.0.0",
    "vite": "^5.0.0",
    "typescript": "^5.4.0",
    "vue-tsc": "^2.0.0",
    "tailwindcss": "^3.4.0",
    "autoprefixer": "^10.4.0",
    "postcss": "^8.4.0"
  }
}
EOF

cat > frontend/vite.config.js <<'EOF'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import path from 'path'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src')
    }
  },
  server: {
    port: 5173,
    host: true
  }
})
EOF

cat > frontend/tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "jsx": "preserve",
    "baseUrl": ".",
    "paths": { "@/*": ["src/*"] },
    "allowJs": true
  },
  "include": ["src/**/*.ts", "src/**/*.vue", "src/**/*.js"]
}
EOF

cat > frontend/tailwind.config.js <<'EOF'
export default {
  content: ["./index.html", "./src/**/*.{vue,js,ts,jsx,tsx}"],
  theme: { extend: {} },
  plugins: [],
}
EOF

cat > frontend/postcss.config.js <<'EOF'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

cat > frontend/index.html <<'EOF'
<!DOCTYPE html>
<html lang="es">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Aplicacion Framework</title>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/src/main.ts"></script>
  </body>
</html>
EOF

cat > frontend/src/main.ts <<'EOF'
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import './style.css'

const app = createApp(App)
app.use(createPinia())
app.use(router)
app.mount('#app')
EOF

cat > frontend/src/style.css <<'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF

cat > frontend/src/App.vue <<'EOF'
<template>
  <LayoutMain />
</template>

<script setup lang="ts">
import LayoutMain from './components/LayoutMain.vue'
</script>
EOF

mkdir -p frontend/src/views
cat > frontend/src/views/DashboardView.vue <<'EOF'
<template>
  <div>
    <h1 class="text-xl font-bold">Dashboard</h1>
  </div>
</template>
EOF

cat > frontend/src/router/index.js <<'EOF'
import { createRouter, createWebHistory } from 'vue-router'
import DashboardView from '../views/DashboardView.vue'

const routes = [
  { path: '/', redirect: '/dashboard/resumen' },
  { path: '/dashboard/resumen', name: 'resumen', component: DashboardView },
]

export default createRouter({
  history: createWebHistory(),
  routes,
})
EOF

cat > frontend/src/stores/navigation.js <<'EOF'
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
EOF

cat > frontend/src/components/LayoutMain.vue <<'EOF'
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
EOF

mkdir -p nginx-host
cat > nginx-host/vhost.conf.template <<'EOF'
server {
    listen 80;
    server_name __DOMAIN__;

    location /static/ {
        alias __PROJECT_DIR__/backend/staticfiles/;
    }

    location /media/ {
        alias __PROJECT_DIR__/backend/media/;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:__BACKEND_PORT__;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /adminer/ {
        proxy_pass http://127.0.0.1:__ADMINER_PORT__/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location / {
        proxy_pass http://127.0.0.1:__FRONTEND_PORT__;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

echo ""
echo "✅ Proyecto '$PROJECT_NAME' creado exitosamente con todas sus líneas."
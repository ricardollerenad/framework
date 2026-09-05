# 🏗️ Arquitectura y convenciones

Reglas de dónde va cada cosa. Si vas a crear un archivo nuevo y no sabes dónde ponerlo, este documento responde.

## Backend (Django)

```
backend/
├── core/                  # SOLO configuración global. Nada de lógica de negocio aquí.
│   ├── settings.py
│   ├── urls.py             # Únicamente incluye las urls de cada app: path('api/auth/', include('apps.authentication.urls'))
│   └── wsgi.py / asgi.py
│
├── apps/                  # Cada módulo de negocio = una carpeta = una Django app
│   ├── authentication/
│   │   ├── models.py        # User extendido, UserSession, etc.
│   │   ├── serializers.py
│   │   ├── views.py
│   │   ├── urls.py
│   │   └── migrations/
│   └── <siguiente_modulo>/  # ej: apps/inventory/, apps/billing/, etc.
│
└── common/                # Código reutilizable ENTRE apps (no es una app en sí)
    ├── permissions.py       # Permisos custom de DRF reutilizables
    ├── pagination.py
    ├── mixins.py
    └── middleware.py         # Ej: middleware de trazabilidad de sesión
```

**Regla de oro:** si el código es específico de un dominio (autenticación, inventario, facturación...) va en `apps/<dominio>/`. Si lo usan 2+ apps, va en `common/`.

## Frontend (Vue 3)

```
frontend/src/
├── modules/                # Cada feature = una carpeta autocontenida
│   ├── auth/
│   │   ├── views/            # LoginView.vue, etc.
│   │   ├── components/        # Componentes SOLO usados dentro de auth
│   │   ├── stores/             # authStore.js (Pinia)
│   │   ├── services/            # authService.js (llamadas a la API)
│   │   └── routes.js             # Rutas propias del módulo, se importan en router/index.js
│   └── <siguiente_modulo>/
│
├── shared/                 # Reutilizable ENTRE módulos
│   ├── components/           # Botones, modales, tablas genéricas, BaseIcon.vue
│   ├── composables/            # useAuth.js, usePagination.js, etc.
│   └── utils/                    # formatters, validators
│
├── layouts/                # Estructuras de página completas
│   └── LayoutMain.vue        # Sidebar + Topbar (el "shell" tipo Odoo)
│
├── router/
│   └── index.js               # Importa las rutas de cada módulo, no las define todas aquí
│
└── stores/
    └── navigation.js           # Estructura del menú lateral (items + submenús)
```

**Regla de oro:** si un componente/vista solo lo usa un módulo, vive dentro de ese módulo. Si lo usan 2+ módulos (un botón genérico, un ícono base), va a `shared/`.

## Convención de nombres
- Componentes Vue: `PascalCase.vue` (ej. `TopbarUserMenu.vue`)
- Composables: `useAlgo.js`
- Stores Pinia: `algoStore.js`
- Apps Django: `snake_case`, en plural cuando aplique (`authentication`, no `auth_app`)

## Sistema de menú lateral (referencia rápida — se detalla en Fase 3 del ROADMAP)

El menú vive en `stores/navigation.js` como un array de objetos:
```js
{
  key: 'ventas',
  label: 'Ventas',
  icon: 'ShoppingCartIcon',       // nombre del ícono de Heroicons
  submenus: [
    { key: 'pedidos', label: 'Pedidos', path: '/ventas/pedidos' },
    { key: 'clientes', label: 'Clientes', path: '/ventas/clientes' },
  ]
}
```
Cuando quieras agregar un ítem nuevo al sidebar, solo agregas un objeto a este array — no tocas el `LayoutMain.vue`. Esto se explica paso a paso en la Fase 3.
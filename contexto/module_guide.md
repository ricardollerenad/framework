# 🧩 Guía de módulos — "cada tab del sidebar es un módulo encapsulado"

Este es el principio de diseño central de toda la plantilla: el proyecto está pensado para que puedas montar sistemas complejos (inventario, facturación, CRM, lo que sea) agregando **módulos independientes**, sin nunca tener que modificar código de otro módulo ya existente. Este documento es la receta a seguir cada vez que agregues uno nuevo.

## Regla de oro

> Un módulo nuevo solo se "engancha" al sistema en 2 puntos centrales: el **router** y el **store de navegación**. Todo lo demás vive aislado dentro de su propia carpeta.

Si algún día necesitas eliminar un módulo completo, deberías poder: borrar su carpeta + quitar 2 líneas (una en `router/index.js`, otra en `stores/navigation.js`) = cero rastro en el resto del código.

## Anatomía de un módulo

```
frontend/src/modules/<nombre_modulo>/
├── views/              # Las páginas del módulo (una por cada submenu/tab)
│   ├── ListadoView.vue
│   └── DetalleView.vue
├── components/          # Componentes SOLO usados dentro de este módulo
│   └── TablaAlgo.vue
├── stores/                # Estado propio del módulo (Pinia), si lo necesita
│   └── algoStore.js
├── services/               # Llamadas a la API de este módulo — SIEMPRE via shared/utils/http.js
│   └── algoService.js
└── routes.js                # Rutas del módulo, exportadas como array
```

## Receta paso a paso — ejemplo con un módulo hipotético "Inventario"

**1. Crea la estructura de carpetas**
```bash
mkdir -p frontend/src/modules/inventario/{views,components,stores,services}
```

**2. Crea el/los servicio(s)** — SIEMPRE reutilizando el cliente HTTP compartido, nunca creando uno nuevo:
```js
// modules/inventario/services/inventarioService.js
import http from '../../../shared/utils/http.js'

export default {
  listarProductos() {
    return http.get('/inventario/productos/')
  },
}
```

**3. Crea las vistas** en `views/`, usando Tailwind directo en el template (sin CSS aparte).

**4. Crea `routes.js`** del módulo:
```js
// modules/inventario/routes.js
import ProductosView from './views/ProductosView.vue'

export default [
  { path: '/inventario/productos', name: 'inventario-productos', component: ProductosView },
]
```

**5. Enganche al router global** (único archivo central que se toca, `router/index.js`):
```js
import inventarioRoutes from '../modules/inventario/routes.js'
// dentro del array de children de la ruta '/':
...inventarioRoutes,
```

**6. Enganche al sidebar** (`stores/navigation.js`) — agrega un objeto nuevo al array de `menuItems`:
```js
{
  key: 'inventario',
  label: 'Inventario',
  icon: 'CubeIcon',           // nombre del ícono de Heroicons (ver docs/MODULES_GUIDE.md Fase 3)
  submenus: [
    { key: 'productos', label: 'Productos', path: '/inventario/productos' },
  ]
}
```

Con eso, el ítem aparece en el sidebar, sus submenús en la barra superior al seleccionarlo, y las rutas ya resuelven — **sin tocar `LayoutMain.vue` ni ningún otro módulo**.

## Backend — el mismo principio, aplicado a Django

```
backend/apps/<nombre_modulo>/
├── models.py
├── serializers.py
├── views.py
├── urls.py            # rutas RELATIVAS, ej. path('productos/', ...) no 'inventario/productos/'
├── apps.py             # AppConfig con name='apps.<nombre_modulo>', label='<nombre_modulo>'
└── migrations/
```

Enganche: agregar `'apps.<nombre_modulo>'` a `INSTALLED_APPS` en `settings.py`, y una línea en `core/urls.py`:
```python
path('api/inventario/', include('apps.inventario.urls')),
```

## Checklist rápido al crear un módulo nuevo

- [ ] ¿El servicio usa `shared/utils/http.js` (frontend) o hereda permisos/paginación de `common/` (backend)? — nunca dupliques esa lógica
- [ ] ¿El `routes.js` del módulo tiene rutas absolutas empezando con `/<nombre_modulo>/...`?
- [ ] ¿El `urls.py` del backend tiene rutas relativas (sin repetir el prefijo)?
- [ ] ¿Agregaste la entrada en `stores/navigation.js` con su ícono?
- [ ] ¿Nada de este módulo importa código de otro módulo directamente? (si dos módulos necesitan compartir algo, ese algo debería vivir en `shared/` o `common/`, no importado cruzado entre módulos)

## Próximo paso evolutivo (Fase 3, pendiente)

Un script `scripts/new-module.sh <nombre>` que genere automáticamente toda esta estructura (carpetas + archivos base con el nombre ya interpolado), para no repetir estos pasos a mano cada vez. Se arma una vez que definamos bien la Fase 3.
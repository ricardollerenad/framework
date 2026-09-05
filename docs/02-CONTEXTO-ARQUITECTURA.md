# Contexto de arquitectura — Mi Framework

> Pega este archivo completo al inicio de cualquier conversación con una IA antes de pedirle que programe un módulo nuevo. Es el "contrato" que define cómo está organizado el proyecto para que el código generado encaje sin fricción.

## Stack

- **Backend**: Django 4.2 + Django REST Framework + SimpleJWT (autenticación por JWT) + PostgreSQL.
- **Frontend**: Vue 3 (Composition API) + Vite + TypeScript + Pinia (estado) + Vue Router + Tailwind CSS + Heroicons.
- **Infra**: Docker Compose (db, backend, frontend, adminer), Nginx (reverse proxy) + Certbot para SSL.

## Estructura de carpetas (regla de oro: cada feature vive en su propia carpeta)

```
framework/
├── backend/
│   ├── core/                  # settings, urls raíz, wsgi — NO poner lógica de negocio aquí
│   ├── apps/                  # cada módulo de negocio es una app Django independiente
│   │   └── authentication/    # ejemplo: login JWT, sesiones, trazabilidad de usuario
│   └── common/                 # utilidades compartidas entre apps (no lógica específica de un módulo)
├── frontend/
│   └── src/
│       ├── modules/            # cada feature del frontend vive en su propia carpeta
│       │   └── auth/
│       ├── shared/              # componentes/composables/iconos reutilizables entre módulos
│       ├── layouts/              # LayoutMain (sidebar + topbar)
│       ├── router/
│       └── stores/
├── nginx-host/                # plantilla de vhost para el Nginx del servidor
├── docker-compose.yml
└── .env
```

## Reglas que cualquier código nuevo debe respetar

1. **No mezclar módulos.** Un módulo de negocio nuevo (ej. "facturación") es una carpeta nueva en `backend/apps/facturacion/` y otra en `frontend/src/modules/facturacion/`. Nunca se agregan archivos sueltos de un módulo dentro de otro.
2. **`common/` y `shared/` son solo para código verdaderamente transversal.** Si algo se usa en un único módulo, vive dentro de ese módulo, no en `common/`/`shared/`.
3. **Autenticación centralizada.** Cualquier endpoint que requiera usuario autenticado usa el mecanismo JWT ya existente en `apps/authentication/` — no se reinventa autenticación por módulo.
4. **Contrato de infraestructura.** El backend debe exponer siempre un endpoint `GET /api/health/` que responda 200 sin autenticación — el script de despliegue depende de que exista para verificar que el backend arrancó correctamente. Si se cambia su ruta o comportamiento, hay que actualizar también la guía de despliegue.
5. **Variables de entorno, nunca valores hardcodeados.** Cualquier configuración sensible o dependiente del entorno (URLs, credenciales, dominios, puertos) se lee de variables definidas en `.env`, siguiendo los nombres ya usados por `docker-compose.yml`: `DOMAIN_NAME`, `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `BACKEND_PORT`, `FRONTEND_PORT`, `ADMINER_PORT`, `COMPOSE_PROJECT_NAME`.
6. **Puertos de servicios internos nunca se exponen directamente.** En `docker-compose.yml`, todo `ports:` de un servicio interno se publica como `127.0.0.1:<puerto>:<puerto>`, nunca sin el `127.0.0.1:`. Solo Nginx decide qué llega a internet.
7. **Migraciones y estáticos son parte del contrato de despliegue.** Cualquier cambio de modelos debe generar su migración correspondiente (`makemigrations`), y cualquier asset estático nuevo debe funcionar con `collectstatic`.

## Cómo usar este documento

Cuando le pidas a una IA que programe algo nuevo, dile explícitamente: *"Sigue las convenciones de CONTEXTO-ARQUITECTURA.md"* y pégalo junto con el pedido específico (usa `03-CONTEXTO-MODULO-NEGOCIO.md` o `03-CONTEXTO-MODULO-INFRA.md` según el tipo de módulo).

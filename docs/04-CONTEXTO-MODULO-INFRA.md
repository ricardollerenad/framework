# Contexto para programar un módulo de INFRAESTRUCTURA

> Úsalo junto con `02-CONTEXTO-ARQUITECTURA.md`. Este archivo lista los módulos de infraestructura pendientes detectados en el análisis del repo, con el porqué de cada uno, para que se los asignes a una IA uno por uno.

## Reglas no negociables para cualquier cambio de infraestructura

- Nunca exponer puertos de contenedores directamente — siempre `127.0.0.1:<puerto>:<puerto>` en `docker-compose.yml`.
- Cualquier script de despliegue debe funcionar tanto si el VPS es **exclusivo** para este proyecto como si es **compartido** con otros — evitar asumir que Nginx/puertos 80-443 están libres para uso exclusivo.
- Todo dato sensible (contraseñas, dominios, puertos) viene de `.env`, nunca hardcodeado en scripts o configs versionadas.
- Cualquier script nuevo debe ser idempotente: ejecutarlo dos veces no debe romper nada ni duplicar configuración.

## Módulos pendientes (en orden sugerido de prioridad)

### 1. Corregir la detección de distro en la instalación de Docker
**Problema actual**: `deploy.sh` hardcodea `download.docker.com/linux/debian` sin importar la distro real detectada.
**Qué pedirle a la IA**: modificar el bloque de instalación de Docker para leer `$ID` de `/etc/os-release` y usarlo en la URL del repositorio y en la key GPG, soportando al menos `debian` y `ubuntu`.

### 2. Healthcheck de Postgres + arranque ordenado
**Problema actual**: `backend` depende de `db` solo por orden de arranque, no por disponibilidad real.
**Qué pedirle a la IA**: agregar un `healthcheck` al servicio `db` en `docker-compose.yml` (usando `pg_isready`) y cambiar `depends_on` de `backend` a la forma extendida con `condition: service_healthy`.

### 3. Script de re-despliegue (`update.sh`)
**Problema actual**: solo existe un script de primer despliegue; actualizar el proyecto requiere repetir pasos manualmente.
**Qué pedirle a la IA**: un script que haga `git pull`, reconstruya solo lo necesario (`docker compose up -d --build`), corra `migrate` y `collectstatic`, y verifique el healthcheck antes de terminar — con salida clara de qué paso falló si algo sale mal.

### 4. Backup automático de PostgreSQL
**Problema actual**: no existe ningún respaldo del volumen de base de datos.
**Qué pedirle a la IA**: un script `backup.sh` que haga `pg_dump` del contenedor `db`, guarde el archivo con fecha en el nombre, rote respaldos más antiguos que N días, y un cronjob de ejemplo para automatizarlo.

### 5. Rotación de logs de Docker
**Problema actual**: los contenedores usan la configuración de logging por defecto, que puede crecer sin límite.
**Qué pedirle a la IA**: agregar `logging: driver: json-file, options: max-size/max-file` a cada servicio relevante en `docker-compose.yml`.

### 6. (Opcional, cuando el proyecto crezca) Pipeline CI/CD a GHCR
**Problema actual**: las imágenes se construyen siempre en el VPS de producción.
**Qué pedirle a la IA**: un workflow de GitHub Actions que construya las imágenes de `backend` y `frontend` en cada push a `main`, las publique en GitHub Container Registry, y un script de despliegue alternativo que haga `docker compose pull` en vez de `--build`.

## Plantilla de prompt para pedirle un módulo de infra a la IA

```
Sigue las convenciones de 02-CONTEXTO-ARQUITECTURA.md y las reglas de 04-CONTEXTO-MODULO-INFRA.md.

Módulo de infraestructura: <nombre, ej. "healthcheck de Postgres">
Problema que resuelve: <descripción>
Restricciones: debe funcionar igual en VPS compartido y exclusivo, no debe romper el despliegue existente, debe ser idempotente.

Muéstrame el diff exacto de los archivos que cambian (docker-compose.yml, deploy.sh, o script nuevo) y explica qué prueba manual debo hacer para confirmar que funciona.
```

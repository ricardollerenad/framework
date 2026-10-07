# Prompt maestro: proyecto modular por fases

Pega todo lo que está debajo de la línea en un chat nuevo.

---

Actúa como arquitecto de software senior y mentor. Voy a construir un proyecto grande por módulos, trabajando en varios chats, así que todo debe quedar documentado en archivos .md. Sigue estas FASES EN ORDEN. En cada fase, haz solo lo indicado y espera mi confirmación antes de pasar a la siguiente. Haz una pregunta a la vez.

## FASE 1 – Tipo de proyecto
Pregúntame qué tipo de proyecto quiero crear (propósito, usuarios, funciones principales). Haz las preguntas necesarias, de una en una, hasta tenerlo claro. Stack base por defecto: Django (backend), Vue (frontend), Docker. Pregúntame mi sistema operativo local.

## FASE 2 – Arquitectura
Pregúntame qué arquitectura prefiero. Explica en 2-3 líneas cada opción viable (monolito modular, API + SPA, microservicios, etc.) con pros y contras para mi caso, recomienda una y justifícala.

## FASE 3 – Módulos y patrón de diseño
Propón la lista de módulos con objetivo de una línea y dependencias entre ellos, ordenados por orden de construcción. Sugiere el patrón de diseño (por ejemplo capas, servicios + repositorios, etc.) y explica por qué. Ajusto y confirmo.

## FASE 4 – Archivos .md
Genera, cada uno en su propio bloque de código y con contenido real adaptado a mi proyecto:

- `docs/PROJECT.md` (visión, stack, reglas generales, "un módulo a la vez, no tocar otros")
- `docs/ARCHITECTURE.md` (mapa de módulos, puertos, Nginx)
- `docs/CONVENTIONS.md` (estilo, nombres, estructura, reglas técnicas)
- `docs/BUSINESS_RULES.md` (reglas globales con ID, formato RN-MODULO-01 y campo "Afecta a")
- `docs/STATUS.md` (módulo en curso, hecho, pendiente, próximo paso exacto)
- `docs/DECISIONS.md` (fecha, cambio, motivo)
- `docs/modules/<modulo>.md` por cada módulo (objetivo, alcance, modelos, endpoints, dependencias, reglas, checklist)

Incluye en PROJECT.md un "Protocolo de chat nuevo": qué archivos pegar, trabajar solo el módulo actual, y al terminar actualizar STATUS.md y el .md del módulo. Las reglas obsoletas se marcan [DEPRECADA], nunca se borran.

## FASE 5 – Tutorial paso a paso
Dame una secuencia numerada con comandos exactos, adaptada a mi sistema operativo:

1. Entorno local (Git, Python, Node, Docker, estructura de carpetas, docker-compose, integración con mi Nginx local).
2. Orden de construcción módulo por módulo, con un punto de verificación tras cada paso (comando + resultado esperado) para detectar errores antes de seguir.
3. Subir a GitHub (repositorio, .gitignore, .env fuera del repo, ramas, commits).
4. Despliegue en mi VPS con dominio: pregúntame antes distro, acceso SSH y dominio. Incluye usuario no-root, firewall, Docker, DNS, Nginx como proxy inverso, HTTPS con Certbot, variables de entorno de producción, migraciones, y cómo actualizar después.

Si algo depende de un dato que no te di, pregúntame en vez de suponerlo.

## Reglas generales
Respuestas concisas, sin relleno, no repitas lo ya acordado, y avísame si una decisión mía puede causar problemas más adelante.

Empieza con la FASE 1.

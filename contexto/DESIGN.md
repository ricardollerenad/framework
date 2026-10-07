# DESIGN — paleta y tokens

Definidos en `frontend/tailwind.config.js` (`theme.extend.colors`). Úsalos por nombre; no uses hex sueltos.

| Token Tailwind | Hex | Nombre | Uso |
|---|---|---|---|
| `humo` | `#F2F0ED` | Humo cálido | Fondo principal de la página |
| `perla` | `#FAF9F7` | Perla suave | Tarjetas, barra superior |
| `carbon` | `#2B2B30` | Carbón profundo | Texto principal, botón de acción, sidebar |
| `piedra` | `#D6D3D0` | Gris piedra | Bordes de inputs y separadores |
| `paloma` | `#7A7980` | Gris paloma | Etiquetas y texto secundario |
| `quemado` | `#C53030` | Rojo quemado | Acento (barra vertical del título), errores, acciones destructivas |
| `shadow-humo` | `rgba(0,0,0,0.10)` (`#0000001A`) | Sombra humo | Sombra de tarjetas |

## Patrones
- **Título de tarjeta:** `border-l-4 border-quemado pl-3 font-bold`.
- **Etiqueta de campo:** `text-xs font-medium uppercase tracking-wide text-paloma`.
- **Input:** `rounded border border-piedra bg-white px-3 py-2 text-sm`.
- **Botón primario:** `rounded bg-carbon text-perla`. **Destructivo:** `border border-quemado text-quemado`.
- **Tarjeta:** `rounded-lg bg-perla shadow-humo`.
- Íconos: Heroicons (`@heroicons/vue/24/outline`), importados en el `manifest.js` de cada módulo.

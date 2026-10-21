# VibaraChokiT · Estudio Creativo — cómo publicar esta versión

## 1. Actualiza la base de datos (una sola vez)
1. Entra a Supabase → **SQL Editor**.
2. Pega y ejecuta **`actualizacion-apps-resenas.sql`**.
   - Crea las tablas de **apps** y **reseñas**.
   - Cambia las rutas de las imágenes de `img/` de `.png/.jpg` a `.webp`.
   - No toca tus libros, precios ni capítulos.
3. **No vuelvas a ejecutar `database.sql`**: es solo para una instalación desde cero
   y reinicia los capítulos de los 4 libros iniciales.

## 2. Sube los archivos a tu hosting / GitHub
Reemplaza `index.html`, `admin.html`, `database.sql` y la carpeta `img/` completa.
Las imágenes antiguas `.png/.jpg` ya no se usan (las nuevas `.webp` pesan ~10 veces menos).

## 2b. Versión digital
Ejecuta también **`actualizacion-digital.sql`** (una vez). Luego, en el panel, agrega el precio digital a cada capítulo:
`Capítulo 1 | 3500 | 1990` (físico | digital). Sin precio digital, el capítulo se vende solo en físico.
Los pedidos digitales llegan por WhatsApp separados de los físicos; tú cobras y envías el PDF.

## 3. Usa el panel (`admin.html`)
- **Libros**: igual que antes. Las categorías que escribas se convierten en los filtros de la tienda.
  Las imágenes que subas se reducen y convierten a WebP automáticamente.
- **Apps y juegos**: agrega cada app con estado *Próximamente*, *En prueba* o *Disponible*,
  y los enlaces a Google Play, App Store o web. Mientras no haya ninguna, la tienda muestra
  dos ideas "En desarrollo" (Chanchini por Chile y Chinowon: el juego).
- **Reseñas**: solo reales y con permiso. La sección aparece en la tienda cuando hay al menos una visible.

## Archivos del logo (carpeta `img/`)
| Archivo | Uso |
|---|---|
| `logo-vibarachokit.png` | Logo completo, fondo transparente (para fondos claros) |
| `logo-vibarachokit-claro.png` | Logo completo para fondos oscuros |
| `logo-icono.png` | Solo el libro‑control |
| `icono-512.png`, `apple-touch-icon.png`, `favicon.png` | Íconos de pestaña, celular y redes |

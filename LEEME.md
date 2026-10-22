# VibaraChokiT · Estudio Creativo — cómo publicar esta versión

## 1. Sube los archivos a tu hosting / GitHub
Reemplaza `index.html`, `admin.html`, `database.sql`, la carpeta `img/` completa (incluye `img/apps/`) y la carpeta nueva `video/`.

## 2. Completa el paso de Supabase (una sola vez)
Entra a `admin.html`. Si falta algo, verás un recuadro amarillo con el botón **Copiar código** y el enlace
**Abrir el editor de Supabase**: pega el código, presiona **Run** y luego **Ya lo hice**.
(Es el mismo contenido de `actualizacion-completa.sql`.) Crea las tablas de apps y reseñas, agrega los
precios digitales, pasa las imágenes a WebP y carga los 5 juegos. No borra nada.

**No ejecutes `database.sql`**: es solo para una instalación desde cero.

**¿Ya habías hecho este paso antes?** Ejecuta también `actualizacion-precios.sql` (SQL Editor → New query →
pegar → Run). Carga los precios físico y digital de la planilla, marca los juegos como disponibles y asigna los videos.
Al final muestra una tabla para revisar cada libro. Si nunca hiciste el paso, el botón del panel ya lo incluye.

## 2b. Versión digital
En el panel, agrega el precio digital a cada capítulo: `Capítulo 1 | 3500 | 1990` (físico | digital).
Sin precio digital, el capítulo se vende solo en físico. Los pedidos digitales llegan por WhatsApp
separados de los físicos; tú cobras y envías el libro en HTML protegido.
Antes de enviar, el carrito pide el nombre, cómo recibe los libros físicos (retiro o envío con dirección)
y dónde enviar los digitales (este WhatsApp o un correo).

## 3. Usa el panel (`admin.html`)
- **Libros**: igual que antes. Las categorías que escribas se convierten en los filtros de la tienda.
  Las imágenes que subas se reducen y convierten a WebP automáticamente.
- **Apps y juegos**: agrega cada app con estado *Próximamente*, *En prueba* o *Disponible*,
  y los enlaces a Google Play, App Store o web. Los 5 juegos vienen como *Disponible*: muestran
  "Descargar por WhatsApp" y, mientras no haya enlace de App Store, "iPhone: en desarrollo".
- **Videos**: cada libro y juego puede tener un video de ~10 s (MP4, menos de 15 MB). Al tocar el libro
  se reproduce y luego se abre la compra; en los juegos, al terminar aparecen las opciones de descarga.
  Los 7 videos actuales están en la carpeta `video/`.
- **Reseñas**: solo reales y con permiso. La sección aparece en la tienda cuando hay al menos una visible.

## Archivos del logo (carpeta `img/`)
| Archivo | Uso |
|---|---|
| `logo-vibarachokit.png` | Logo completo, fondo transparente (para fondos claros) |
| `logo-vibarachokit-claro.png` | Logo completo para fondos oscuros |
| `logo-icono.png` | Solo el libro‑control |
| `icono-512.png`, `apple-touch-icon.png`, `favicon.png` | Íconos de pestaña, celular y redes |

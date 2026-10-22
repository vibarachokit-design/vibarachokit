-- =====================================================================
-- ACTUALIZACIÓN COMPLETA (apps y juegos, reseñas, imágenes WebP, venta digital)
--
-- Cómo ejecutarlo:
--   1. Entra a https://supabase.com/dashboard y abre tu proyecto.
--   2. Menú izquierdo: "SQL Editor" -> botón "New query".
--   3. Pega TODO este archivo y presiona "Run" (o Ctrl + Enter).
--   4. Debe decir "Success. No rows returned".
--
-- Se puede ejecutar más de una vez sin problema. No borra libros, precios ni capítulos.
-- =====================================================================

-- ---------- APPS Y JUEGOS ----------
create table if not exists public.apps (
  id text primary key default gen_random_uuid()::text,
  slug text not null unique check (slug ~ '^[a-z0-9-]+$'),
  name text not null,
  tagline text not null default '',
  description text not null default '',
  icon_url text not null default '',
  screenshots jsonb not null default '[]'::jsonb,
  links jsonb not null default '{}'::jsonb,          -- {"android": "...", "ios": "...", "web": "..."}
  status text not null default 'proximamente' check (status in ('disponible','beta','proximamente')),
  color_key text not null default 'teal' check (color_key in ('coral','teal','sun','grape')),
  published boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists apps_touch_updated_at on public.apps;
create trigger apps_touch_updated_at before update on public.apps
for each row execute function public.touch_updated_at();

alter table public.apps enable row level security;
drop policy if exists "Public can read published apps" on public.apps;
create policy "Public can read published apps" on public.apps for select
using (published or public.is_admin());
drop policy if exists "Admins manage apps" on public.apps;
create policy "Admins manage apps" on public.apps for all
using (public.is_admin()) with check (public.is_admin());

-- ---------- RESEÑAS (solo reales, ingresadas desde el panel) ----------
create table if not exists public.reviews (
  id text primary key default gen_random_uuid()::text,
  author_name text not null,
  location text not null default '',
  book_slug text,                                    -- opcional: slug del libro reseñado
  rating integer not null default 5 check (rating between 1 and 5),
  body text not null,
  published boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

alter table public.reviews enable row level security;
drop policy if exists "Public can read published reviews" on public.reviews;
create policy "Public can read published reviews" on public.reviews for select
using (published or public.is_admin());
drop policy if exists "Admins manage reviews" on public.reviews;
create policy "Admins manage reviews" on public.reviews for all
using (public.is_admin()) with check (public.is_admin());

-- ---------- IMÁGENES: de PNG/JPG a WebP ----------
-- Las imágenes de la carpeta img/ se convirtieron a .webp (10 veces más livianas).
-- Las imágenes subidas desde el panel (Supabase Storage) no se tocan.
update public.books
set image_url = regexp_replace(image_url, '\.(png|jpe?g)$', '.webp', 'i')
where image_url like 'img/%';

update public.books
set preview_images = (
  select coalesce(jsonb_agg(
    case when p like 'img/%' then to_jsonb(regexp_replace(p, '\.(png|jpe?g)$', '.webp', 'i')) else to_jsonb(p) end
  ), '[]'::jsonb)
  from jsonb_array_elements_text(preview_images) as p
)
where preview_images::text like '%img/%';

-- ---------- VENTA DIGITAL ----------
-- Precio digital vacío o 0 = ese capítulo/libro NO se vende en digital.
alter table public.chapters add column if not exists price_digital integer check (price_digital >= 0);
alter table public.books    add column if not exists price_digital integer check (price_digital >= 0);

-- ---------- JUEGOS INICIALES ----------
-- Quedan como "Disponible" (descarga por WhatsApp). Agrega el enlace de Google Play en el panel.
insert into public.apps (slug, name, tagline, description, screenshots, status, color_key, sort_order) values
('turron-go-home', 'Turrón Go Home!', 'Una aventura de caminos en Mejillones', '¡Ayuda a Turrón a volver a su casita! Une los caminos por la costa de Mejillones en 48 niveles y 4 mundos.', '["img/apps/turron-go-home.webp"]'::jsonb, 'disponible', 'sun', 1),
('turron-kofy-run', 'Turrón Kofy Run', 'Una carrera del Espacio Kihnally', 'Corre con Turrón por el borde costero, junta granos de café y llega a la cafetería Kihnally.', '["img/apps/turron-kofy-run.webp"]'::jsonb, 'disponible', 'coral', 2),
('vector-beat', 'Vector Beat', 'Salta al ritmo entre islas flotantes', 'Un robot tejido a crochet salta por anillos y mundos de lana bajo un cielo de tormenta.', '["img/apps/vector-beat.webp"]'::jsonb, 'disponible', 'grape', 3),
('antuan-soccer-player', 'Antuan Soccer Player', 'Fútbol para pequeños cracks', 'Antuan, el número 10, sale a la cancha a llenar el estadio de goles.', '["img/apps/antuan-soccer-player.webp"]'::jsonb, 'disponible', 'teal', 4),
('mano-arana-mutante', 'La Mano Araña Mutante', 'Escapa del laboratorio', 'Una mano con patas de araña escapa del laboratorio esquivando zapatos, matamoscas y spray.', '["img/apps/mano-arana-mutante.webp"]'::jsonb, 'disponible', 'grape', 5)
on conflict (slug) do nothing;

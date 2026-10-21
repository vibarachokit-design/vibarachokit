-- =====================================================================
-- ACTUALIZACIÓN: Apps y juegos + Reseñas + imágenes WebP
-- Ejecutar UNA vez en Supabase > SQL Editor (sobre la base que ya tienes).
-- No borra ni modifica tus libros ni capítulos, salvo las rutas de imagen.
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

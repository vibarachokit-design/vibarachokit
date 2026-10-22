-- INSTALACIÓN DESDE CERO. Ejecutar una sola vez en Supabase > SQL Editor.
-- ¿Ya tienes la base funcionando? NO ejecutes este archivo de nuevo (reinicia los capítulos
-- de los 4 libros iniciales). Usa solo actualizacion-apps-resenas.sql.
-- Después crea el usuario ibar.araya@gmail.com desde Authentication > Users.

create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists public.books (
  id text primary key default gen_random_uuid()::text,
  slug text not null unique check (slug ~ '^[a-z0-9-]+$'),
  title text not null,
  subtitle text not null default '',
  description text not null default '',
  image_url text not null default '',
  preview_images jsonb not null default '[]'::jsonb,
  badge text not null default 'Libro',
  color_key text not null default 'coral' check (color_key in ('coral','teal','sun','grape')),
  price_physical integer not null default 0 check (price_physical >= 0),
  price_digital integer check (price_digital >= 0),
  video_url text not null default '',
  tags jsonb not null default '[]'::jsonb,
  published boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Compatibilidad con instalaciones anteriores de Kihnally.
alter table public.books add column if not exists slug text;
alter table public.books add column if not exists subtitle text not null default '';
alter table public.books add column if not exists description text not null default '';
alter table public.books add column if not exists image_url text not null default '';
alter table public.books add column if not exists preview_images jsonb not null default '[]'::jsonb;
alter table public.books add column if not exists badge text not null default 'Libro';
alter table public.books add column if not exists color_key text not null default 'coral';
alter table public.books add column if not exists price_physical integer not null default 0;
alter table public.books add column if not exists price_digital integer check (price_digital >= 0);
alter table public.books add column if not exists tags jsonb not null default '[]'::jsonb;
alter table public.books add column if not exists published boolean not null default true;
alter table public.books add column if not exists sort_order integer not null default 0;
alter table public.books add column if not exists created_at timestamptz not null default now();
alter table public.books add column if not exists updated_at timestamptz not null default now();
alter table public.books alter column id set default gen_random_uuid()::text;
update public.books
set slug = lower(regexp_replace(coalesce(nullif(id, ''), gen_random_uuid()::text), '[^a-zA-Z0-9]+', '-', 'g'))
where slug is null or slug = '';
create unique index if not exists books_slug_unique_idx on public.books(slug);

do $$
begin
  if exists (select 1 from information_schema.columns where table_schema='public' and table_name='books' and column_name='img') then
    execute 'update public.books set image_url = img where image_url = '''' and img is not null';
  end if;
end $$;

create table if not exists public.chapters (
  id text primary key default gen_random_uuid()::text,
  book_id text not null references public.books(id) on delete cascade,
  code text not null,
  name text not null,
  price integer not null default 0 check (price >= 0),
  price_digital integer check (price_digital >= 0),
  published boolean not null default true,
  sort_order integer not null default 0,
  unique (book_id, code)
);

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists(select 1 from public.admin_users where user_id = auth.uid());
$$;

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

drop trigger if exists books_touch_updated_at on public.books;
create trigger books_touch_updated_at before update on public.books
for each row execute function public.touch_updated_at();

alter table public.admin_users enable row level security;
alter table public.books enable row level security;
alter table public.chapters enable row level security;

drop policy if exists "Public can read published books" on public.books;
create policy "Public can read published books" on public.books for select
using (published or public.is_admin());
drop policy if exists "Admins manage books" on public.books;
create policy "Admins manage books" on public.books for all
using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Public can read published chapters" on public.chapters;
create policy "Public can read published chapters" on public.chapters for select
using (published or public.is_admin());
drop policy if exists "Admins manage chapters" on public.chapters;
create policy "Admins manage chapters" on public.chapters for all
using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Admins can view their role" on public.admin_users;
create policy "Admins can view their role" on public.admin_users for select
using (user_id = auth.uid());

insert into storage.buckets (id, name, public)
values ('book-images', 'book-images', true)
on conflict (id) do update set public = true;

drop policy if exists "Public reads book images" on storage.objects;
create policy "Public reads book images" on storage.objects for select
using (bucket_id = 'book-images');
drop policy if exists "Admins upload book images" on storage.objects;
create policy "Admins upload book images" on storage.objects for insert
with check (bucket_id = 'book-images' and public.is_admin());
drop policy if exists "Admins update book images" on storage.objects;
create policy "Admins update book images" on storage.objects for update
using (bucket_id = 'book-images' and public.is_admin());
drop policy if exists "Admins delete book images" on storage.objects;
create policy "Admins delete book images" on storage.objects for delete
using (bucket_id = 'book-images' and public.is_admin());

-- ---------- APPS Y JUEGOS ----------
create table if not exists public.apps (
  id text primary key default gen_random_uuid()::text,
  slug text not null unique check (slug ~ '^[a-z0-9-]+$'),
  name text not null,
  tagline text not null default '',
  description text not null default '',
  icon_url text not null default '',
  screenshots jsonb not null default '[]'::jsonb,
  links jsonb not null default '{}'::jsonb,
  video_url text not null default '',          -- {"android": "...", "ios": "...", "web": "..."}
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

-- Catálogo inicial. Puedes modificarlo después desde admin.html.
insert into public.books (slug,title,subtitle,description,image_url,preview_images,badge,color_key,price_physical,tags,published,sort_order) values
('chanchini','¿Dónde está Chanchini?','Aventura · Viajes · Infantil','Conoce a Chanchini, la viajera más pequeña de Chile. Este cerdito soñador vive en la cafetería Kihnally y quiere recorrer cada rincón del país, desde Arica hasta Punta Arenas.','img/chanchini.webp','["img/chanchini-pagina1.webp","img/chanchini-pagina2.webp"]'::jsonb,'Aventura','coral',5990,'["Viajes","Infantil","Chile","Aventura"]'::jsonb,true,1),
('chinowon','Chinowon','El diccionario menos confiable del mundo','Traducciones que jamás encontrarás en una academia. Humor absurdo 100% garantizado. Si no tiene sentido… ¡es Chinowon!','img/chinowon.webp','["img/chinowon-pagina1.webp","img/chinowon-pagina2.webp"]'::jsonb,'Humor','sun',5990,'["Humor","Absurdo","Diccionario","Risa"]'::jsonb,true,2),
('barista','Barista Kihnally','Temporada 1 — Café · Cultura · Aventura','6 aventuras en Mejillones como nunca antes las viste. Gaviotas con actitud, fantasmas en el faro y el mejor café del puerto.','img/barista.webp','["img/barista-pagina1.webp","img/barista-pagina2.webp"]'::jsonb,'Serie','teal',4990,'["Aventura","Mejillones","Café","6 episodios"]'::jsonb,true,3),
('turon','Turón: El perro con carita de ratón','Amistad · Sueños · Un camarón muy especial','Una historia sobre amistad, sueños y un camarón muy especial. Turón te robará el corazón con esa carita imposible.','img/turon.webp','["img/turon-pagina1.webp","img/turon-pagina2.webp"]'::jsonb,'Infantil','grape',4990,'["Infantil","Amistad","Sueños","Emoción"]'::jsonb,true,4)
on conflict (slug) do nothing;

delete from public.chapters where book_id in (select id from public.books where slug in ('chanchini','chinowon','barista','turon'));
insert into public.chapters (book_id,code,name,price,sort_order)
select b.id, c.code, c.name, c.price, c.sort_order
from public.books b
join (values
 ('chanchini','c1','Capítulo 1',5990,1),('chanchini','c2','Capítulo 2',5990,2),
 ('chinowon','c1','Capítulo 1',5990,1),('chinowon','c2','Capítulo 2',5990,2),('chinowon','c3','Capítulo 3',5990,3),('chinowon','c4','Capítulo 4',5990,4),
 ('barista','c1','Capítulo 1',3500,1),('barista','c2','Capítulo 2',3500,2),('barista','c3','Capítulo 3',3500,3),('barista','c4','Capítulo 4',3500,4),('barista','c5','Capítulo 5',3500,5),('barista','c6','Capítulo 6',3500,6),
 ('turon','c1','Capítulo 1',3500,1),('turon','c2','Capítulo 2',3500,2),('turon','c3','Capítulo 3',3500,3),('turon','c4','Capítulo 4',3500,4)
) as c(slug,code,name,price,sort_order) on c.slug = b.slug;

-- Autoriza el usuario administrador. El usuario debe existir primero en Authentication > Users.
insert into public.admin_users (user_id, email)
select id, email from auth.users where lower(email) = lower('ibar.araya@gmail.com')
on conflict (user_id) do update set email = excluded.email;

-- ---------- JUEGOS INICIALES ----------
-- Quedan como "Disponible" (descarga por WhatsApp). Agrega el enlace de Google Play en el panel.
insert into public.apps (slug, name, tagline, description, screenshots, status, color_key, sort_order) values
('turron-go-home', 'Turrón Go Home!', 'Una aventura de caminos en Mejillones', '¡Ayuda a Turrón a volver a su casita! Une los caminos por la costa de Mejillones en 48 niveles y 4 mundos.', '["img/apps/turron-go-home.webp"]'::jsonb, 'disponible', 'sun', 1),
('turron-kofy-run', 'Turrón Kofy Run', 'Una carrera del Espacio Kihnally', 'Corre con Turrón por el borde costero, junta granos de café y llega a la cafetería Kihnally.', '["img/apps/turron-kofy-run.webp"]'::jsonb, 'disponible', 'coral', 2),
('vector-beat', 'Vector Beat', 'Salta al ritmo entre islas flotantes', 'Un robot tejido a crochet salta por anillos y mundos de lana bajo un cielo de tormenta.', '["img/apps/vector-beat.webp"]'::jsonb, 'disponible', 'grape', 3),
('antuan-soccer-player', 'Antuan Soccer Player', 'Fútbol para pequeños cracks', 'Antuan, el número 10, sale a la cancha a llenar el estadio de goles.', '["img/apps/antuan-soccer-player.webp"]'::jsonb, 'disponible', 'teal', 4),
('mano-arana-mutante', 'La Mano Araña Mutante', 'Escapa del laboratorio', 'Una mano con patas de araña escapa del laboratorio esquivando zapatos, matamoscas y spray.', '["img/apps/mano-arana-mutante.webp"]'::jsonb, 'disponible', 'grape', 5)
on conflict (slug) do nothing;

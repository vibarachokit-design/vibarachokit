-- Ejecutar una sola vez en Supabase > SQL Editor.
-- Después crea el usuario desde Authentication > Users y reemplaza
-- ADMIN@EJEMPLO.COM al final de este archivo por su correo real.

create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists public.books (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9-]+$'),
  title text not null,
  subtitle text not null default '',
  description text not null default '',
  image_url text not null default '',
  preview_images text[] not null default '{}',
  badge text not null default 'Libro',
  color_key text not null default 'coral' check (color_key in ('coral','teal','sun','grape')),
  price_physical integer not null default 0 check (price_physical >= 0),
  tags text[] not null default '{}',
  published boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.chapters (
  id uuid primary key default gen_random_uuid(),
  book_id uuid not null references public.books(id) on delete cascade,
  code text not null,
  name text not null,
  price integer not null default 0 check (price >= 0),
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

-- Catálogo inicial. Puedes modificarlo después desde admin.html.
insert into public.books (slug,title,subtitle,description,image_url,preview_images,badge,color_key,price_physical,tags,published,sort_order) values
('chanchini','¿Dónde está Chanchini?','Aventura · Viajes · Infantil','Conoce a Chanchini, la viajera más pequeña de Chile. Este cerdito soñador vive en la cafetería Kihnally y quiere recorrer cada rincón del país, desde Arica hasta Punta Arenas.','img/chanchini.png',array['img/chanchini-pagina1.png','img/chanchini-pagina2.png'],'Aventura','coral',5990,array['Viajes','Infantil','Chile','Aventura'],true,1),
('chinowon','Chinowon','El diccionario menos confiable del mundo','Traducciones que jamás encontrarás en una academia. Humor absurdo 100% garantizado. Si no tiene sentido… ¡es Chinowon!','img/chinowon.png',array['img/chinowon-pagina1.png','img/chinowon-pagina2.png'],'Humor','sun',5990,array['Humor','Absurdo','Diccionario','Risa'],true,2),
('barista','Barista Kihnally','Temporada 1 — Café · Cultura · Aventura','6 aventuras en Mejillones como nunca antes las viste. Gaviotas con actitud, fantasmas en el faro y el mejor café del puerto.','img/barista.png',array['img/barista-pagina1.png','img/barista-pagina2.png'],'Serie','teal',4990,array['Aventura','Mejillones','Café','6 episodios'],true,3),
('turon','Turón: El perro con carita de ratón','Amistad · Sueños · Un camarón muy especial','Una historia sobre amistad, sueños y un camarón muy especial. Turón te robará el corazón con esa carita imposible.','img/turon.jpg',array['img/turon-pagina1.png','img/turon-pagina2.png'],'Infantil','grape',4990,array['Infantil','Amistad','Sueños','Emoción'],true,4)
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

-- Reemplaza el correo y ejecuta esta sentencia después de crear el usuario:
-- insert into public.admin_users (user_id, email)
-- select id, email from auth.users where lower(email) = lower('ADMIN@EJEMPLO.COM')
-- on conflict (user_id) do update set email = excluded.email;

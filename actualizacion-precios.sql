-- =====================================================================
-- PRECIOS FÍSICO Y DIGITAL (22-10-2026) + JUEGOS DISPONIBLES + VIDEOS
--
-- Cómo ejecutarlo (igual que el paso anterior):
--   Supabase -> SQL Editor -> New query -> pega TODO este archivo -> Run.
-- Al final aparece una tabla para revisar que cada libro quedó con su precio.
-- Se puede ejecutar más de una vez. Si un libro no aparece en la tabla final,
-- su título en el panel es distinto: avísame o cambia el precio en el panel.
-- =====================================================================

-- Por si aún no se ejecutó actualizacion-completa.sql
alter table public.chapters add column if not exists price_digital integer check (price_digital >= 0);
alter table public.books    add column if not exists price_digital integer check (price_digital >= 0);

-- Precios por libro: todos los capítulos de cada libro tienen el mismo valor.
-- Los libros se buscan por título (y subtítulo en La Princesa Gato), sin importar mayúsculas.
with precios(titulo, subtitulo, fisico, digital) as (values
  ('%chanchini%',          '%',                 5990, 3500),
  ('chinowon%',            '%',                 5990, 3500),
  ('%barista%',            '%',                 3500, 3000),
  ('tur%n%',               '%',                 3500, 3000),
  ('%princesa gato%',      '%camanchaca%',      5990, 4990),
  ('%princesa gato%',      '%nubes%',           5990, 4990),
  ('%princesa gato%',      '%intercambio%',     5990, 4990),
  ('%princesa gato%',      '%termales%',        5990, 4990),
  ('%princesa gato%',      '%mar%ritual%',      5990, 4990),
  ('update%',              '%',                 8990, 7990),
  ('%cozy%',               '%',                 3500, 3200),
  ('%colorea mejillones%', '%',                 3500, 3200)
)
update public.chapters ch
set price = p.fisico, price_digital = p.digital
from public.books b, precios p
where ch.book_id = b.id
  and b.title ilike p.titulo
  and b.subtitle ilike p.subtitulo;

-- Mi Yo Interior no tiene capítulos: se vende como libro completo
update public.books
set price_physical = 12990, price_digital = 8900
where title ilike '%yo interior%';

-- Juegos: ya se pueden descargar (WhatsApp / Google Play). iPhone en desarrollo.
do $$
begin
  if to_regclass('public.apps') is not null then
    update public.apps set status = 'disponible'
    where slug in ('turron-go-home','turron-kofy-run','vector-beat','antuan-soccer-player','mano-arana-mutante');
  end if;
end $$;

-- Videos promocionales de 10 segundos (carpeta video/ del sitio)
alter table public.books add column if not exists video_url text not null default '';
do $$
begin
  if to_regclass('public.apps') is not null then
    alter table public.apps add column if not exists video_url text not null default '';
    update public.apps set video_url = 'video/' || slug || '.mp4'
    where slug in ('turron-go-home','vector-beat','antuan-soccer-player') and video_url = '';
  end if;
end $$;
update public.books set video_url = 'video/chanchini.mp4'     where title ilike '%chanchini%'     and video_url = '';
update public.books set video_url = 'video/chinowon.mp4'      where title ilike 'chinowon%'       and video_url = '';
update public.books set video_url = 'video/barista.mp4'       where title ilike '%barista%'       and video_url = '';
update public.books set video_url = 'video/princesa-gato.mp4' where title ilike '%princesa gato%' and video_url = '';

-- Revisión: cada libro con sus precios
select b.title as libro, b.subtitle as subtitulo,
       count(ch.id) as capitulos,
       coalesce(min(ch.price), b.price_physical) as fisico,
       coalesce(min(ch.price_digital), b.price_digital) as digital
from public.books b
left join public.chapters ch on ch.book_id = b.id
group by b.id, b.title, b.subtitle, b.price_physical, b.price_digital, b.sort_order
order by b.sort_order;

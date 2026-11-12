-- =====================================================================
-- APLICACIONES EMPRESARIALES (página empresas.html)
-- Supabase -> SQL Editor -> New query -> pega TODO este archivo -> Run.
-- Se puede ejecutar más de una vez. No borra nada.
-- =====================================================================
-- ---------- PROTECCIÓN: solo se ejecuta en el proyecto de la tienda ----------
do $$
begin
  if to_regclass('public.books') is null
     or not exists (select 1 from information_schema.columns
                    where table_schema = 'public' and table_name = 'books' and column_name = 'image_url')
     or to_regclass('public.chapters') is null then
    raise exception 'PROYECTO EQUIVOCADO: aquí no está la tienda VibaraChokiT. No se cambió nada. Abre el proyecto lpjuwxywvuifjqoudglp en Supabase y vuelve a ejecutar.';
  end if;
end $$;

do $$
begin
  if to_regclass('public.apps') is not null then
    alter table public.apps add column if not exists segment text not null default 'juegos';
    alter table public.apps add column if not exists features jsonb not null default '[]'::jsonb;
    alter table public.apps add column if not exists audience text not null default '';
    alter table public.apps add column if not exists video_url text not null default '';
    alter table public.apps drop constraint if exists apps_segment_check;
    alter table public.apps add constraint apps_segment_check check (segment in ('juegos','empresas'));
  end if;
end $$;

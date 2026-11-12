-- =====================================================================
-- APLICACIONES EMPRESARIALES (página empresas.html)
-- Supabase -> SQL Editor -> New query -> pega TODO este archivo -> Run.
-- Se puede ejecutar más de una vez. No borra nada.
-- =====================================================================
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

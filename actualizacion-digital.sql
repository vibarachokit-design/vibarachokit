-- =====================================================================
-- ACTUALIZACIÓN: venta de libros en versión digital (PDF)
-- Ejecutar UNA vez en Supabase > SQL Editor. No modifica precios existentes.
-- Precio digital vacío o 0 = ese capítulo/libro NO se vende en digital.
-- =====================================================================
alter table public.chapters add column if not exists price_digital integer check (price_digital >= 0);
alter table public.books    add column if not exists price_digital integer check (price_digital >= 0);

-- =====================================================================
-- MiPo - Tahap 2: profil pengguna + pengaturan per akun
-- Jalankan sekali di Supabase: SQL Editor > New query > paste > Run
-- =====================================================================

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  name text not null default '',
  age int,
  education_level text not null default '',
  pet_name text not null default 'Mipo',
  language text not null default 'id' check (language in ('id', 'en')),
  dark_mode boolean not null default false,
  notifications_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Keamanan: setiap akun hanya bisa melihat dan mengubah barisnya sendiri.
alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles
  for insert with check (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

-- Otomatis membuat profil saat ada akun baru (data dari form Register).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, name, age, education_level, pet_name, language)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'name', ''),
    nullif(new.raw_user_meta_data ->> 'age', '')::int,
    coalesce(new.raw_user_meta_data ->> 'education_level', ''),
    coalesce(nullif(new.raw_user_meta_data ->> 'pet_name', ''), 'Mipo'),
    case when new.raw_user_meta_data ->> 'language' = 'en' then 'en' else 'id' end
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Memperbarui kolom updated_at otomatis.
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at
  before update on public.profiles
  for each row execute function public.touch_updated_at();

-- Hapus akun sendiri (dipakai tombol "Delete Account").
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

-- PoskoTrack schema: jalankan di Supabase > SQL Editor.
-- Pendaftaran publik default menjadi anggota. Admin mengubah role ketua/sekretaris secara manual.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default 'Anggota KKN',
  role text not null default 'anggota' check (role in ('anggota','ketua','sekretaris')),
  created_at timestamptz not null default now()
);

create table if not exists public.exit_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  out_date date not null default current_date,
  reason text not null,
  destination text not null,
  out_time time not null,
  return_time time,
  proof_path text,
  proof_url text,
  status text not null default 'di_luar' check (status in ('di_luar','selesai')),
  created_at timestamptz not null default now(),
  constraint return_after_exit check (return_time is null or return_time >= out_time)
);

create index if not exists exit_logs_out_date_idx on public.exit_logs(out_date desc);
create index if not exists exit_logs_user_date_idx on public.exit_logs(user_id, out_date desc);

alter table public.profiles enable row level security;
alter table public.exit_logs enable row level security;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name','Anggota KKN'), 'anggota')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.current_user_role()
returns text language sql stable security definer set search_path = public
as $$ select role from public.profiles where id = auth.uid() $$;

-- Semua pengguna terautentikasi bisa melihat rekap bersama. Anggota hanya boleh
-- membuat dan memperbarui catatannya sendiri. Ketua/sekretaris bisa melihat semua data.
drop policy if exists "profiles readable by authenticated" on public.profiles;
create policy "profiles readable by authenticated" on public.profiles
for select to authenticated using (true);

-- Profil dibaca oleh pengguna yang login, tetapi perubahan role hanya dilakukan
-- melalui Supabase Dashboard oleh pengelola proyek.
drop policy if exists "profile update own" on public.profiles;

drop policy if exists "exit logs visible to authenticated" on public.exit_logs;
create policy "exit logs visible to authenticated" on public.exit_logs
for select to authenticated using (
  user_id = auth.uid() or public.current_user_role() in ('ketua','sekretaris')
);

drop policy if exists "users create own logs" on public.exit_logs;
create policy "users create own logs" on public.exit_logs
for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "users update own logs" on public.exit_logs;
create policy "users update own logs" on public.exit_logs
for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Batas dua catatan per tanggal per pengguna, dicek di database agar tidak bisa
-- dilewati hanya dengan membuka dua tab/perangkat. Hitungan mengunci lewat trigger.
create or replace function public.enforce_two_daily_exits()
returns trigger language plpgsql security definer set search_path = public
as $$
declare n integer;
begin
  if tg_op = 'INSERT' then
    perform pg_advisory_xact_lock(hashtext(new.user_id::text || new.out_date::text));
    select count(*) into n from public.exit_logs
      where user_id = new.user_id and out_date = new.out_date;
    if n >= 2 then
      raise exception 'Batas maksimal dua kali keluar posko per hari telah tercapai.';
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists check_daily_exit_quota on public.exit_logs;
create trigger check_daily_exit_quota before insert on public.exit_logs
for each row execute procedure public.enforce_two_daily_exits();

-- Buat bucket bukti foto (public untuk kemudahan demo; gunakan bucket private + signed URLs
-- jika foto memuat informasi sensitif). Supabase Dashboard > Storage > New bucket:
-- name: exit-proofs, public: true
-- Policy storage: allow authenticated uploads only to own folder. Jalankan:
drop policy if exists "upload own proof" on storage.objects;
create policy "upload own proof" on storage.objects
for insert to authenticated with check (
  bucket_id = 'exit-proofs' and (storage.foldername(name))[1] = auth.uid()::text
);
drop policy if exists "read proof photos" on storage.objects;
create policy "read proof photos" on storage.objects
for select to authenticated using (bucket_id = 'exit-proofs');

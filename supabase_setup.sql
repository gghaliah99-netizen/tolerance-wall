-- نفذي هذا النص مرة واحدة في Supabase SQL Editor.
create table if not exists public.wall_settings (
 id integer primary key default 1 check (id=1),
 is_open boolean not null default false,
 starts_at timestamptz,
 ends_at timestamptz
);
insert into public.wall_settings(id,is_open) values (1,false) on conflict(id) do nothing;
create table if not exists public.wall_admins (
 user_id uuid primary key references auth.users(id) on delete cascade
);
create table if not exists public.wall_notes (
 id bigint generated always as identity primary key,
 name text not null default 'رسالة من القلب 💗' check(char_length(name) between 1 and 50),
 message text not null check(char_length(trim(message)) between 3 and 240),
 color text not null check(color in ('#ffe3ef','#eee1ff','#fff0b9','#ddf6e5','#e0f2ff')),
 created_at timestamptz not null default now()
);
create index if not exists wall_notes_created_idx on public.wall_notes(created_at desc);
alter table public.wall_settings enable row level security;
alter table public.wall_notes enable row level security;
alter table public.wall_admins enable row level security;
create policy "everyone can view settings" on public.wall_settings for select to anon, authenticated using (true);
create policy "everyone can view notes" on public.wall_notes for select to anon, authenticated using (true);
create policy "admins see their own record" on public.wall_admins for select to authenticated using (user_id = (select auth.uid()));
create policy "admins update settings" on public.wall_settings for update to authenticated
 using (exists(select 1 from public.wall_admins where user_id=(select auth.uid())))
 with check (exists(select 1 from public.wall_admins where user_id=(select auth.uid())));
create policy "admins delete notes" on public.wall_notes for delete to authenticated
 using (exists(select 1 from public.wall_admins where user_id=(select auth.uid())));
create policy "public can post only during active period" on public.wall_notes for insert to anon, authenticated
 with check (exists(select 1 from public.wall_settings s where s.id=1 and s.is_open=true and (s.starts_at is null or now()>=s.starts_at) and (s.ends_at is null or now()<s.ends_at)));
-- بعد إنشاء حساب المعلمة من Authentication > Users، ضعي UUID الحقيقي هنا وشغّلي السطر التالي منفصلًا:
-- insert into public.wall_admins(user_id) values ('REPLACE_WITH_TEACHER_USER_UUID');

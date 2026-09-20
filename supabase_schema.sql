-- =====================================================================
-- أكاديمية قرطبة لتعليم القرآن الكريم — منصة قاف لمتابعة الحفظ
-- كود إنشاء وتحديث جداول قاعدة بيانات Supabase (SQL Schema)
-- انسخ هذا الكود بالكامل وضعه في: Supabase Dashboard -> SQL Editor -> New query -> RUN
-- =====================================================================

-- 1. جدول حسابات المستخدمين الموحد (Users Accounts)
create table if not exists public.users_accounts (
  id uuid default gen_random_uuid() primary key,
  username text unique not null,
  password_hash text not null,
  name text not null,
  role text not null check (role in ('admin', 'moderator', 'teacher', 'student')),
  phone text,
  status text default 'نشط',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. جدول المعلمين
create table if not exists public.teachers (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users_accounts(id) on delete cascade,
  username text unique,
  name text not null,
  area text default 'معلم قرآن وتجويد بالقراءات',
  students_count integer default 0,
  rating text default 'ممتاز',
  status text default 'نشط',
  phone text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. جدول المشرفين (Moderators)
create table if not exists public.moderators (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users_accounts(id) on delete cascade,
  username text unique,
  name text not null,
  area text default 'متابعة جودة التسميع والحصص',
  phone text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 4. جدول الطلاب
create table if not exists public.students (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users_accounts(id) on delete cascade,
  username text unique,
  name text not null,
  teacher_name text,
  program text default 'أطفال',
  monthly_sessions integer default 8,
  session_schedule text default 'السبت والثلاثاء',
  progress_juz integer default 0,
  current_surah_new text,
  current_surah_rev text,
  last_rating text default 'ممتاز',
  phone text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 5. جدول الحصص والمواعيد (Sessions)
create table if not exists public.sessions (
  id uuid default gen_random_uuid() primary key,
  student_name text not null,
  teacher_name text not null,
  date_text text not null,
  time_text text not null,
  platform text default 'Zoom',
  link text default 'https://meet.google.com/new',
  status text default 'upcoming',
  attendance text default '',
  makeup_required boolean default false,
  makeup_status text default '',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 6. جدول التقييمات التخصصي الثلاثي (Triple Evaluations)
create table if not exists public.evaluations (
  id uuid default gen_random_uuid() primary key,
  session_id uuid references public.sessions(id) on delete set null,
  student_name text not null,
  teacher_name text not null,
  date_text text not null,
  month_key text not null, -- e.g. '2026-09'

  -- الحفظ الجديد
  new_surah_from integer,
  new_ayah_from integer,
  new_surah_to integer,
  new_ayah_to integer,
  new_ayahs_count integer default 0,
  new_pages_count numeric(4,1) default 0,
  new_score numeric(5,2) default 100,
  new_notes jsonb default '[]'::jsonb,

  -- المراجعة
  rev_surah_from integer,
  rev_ayah_from integer,
  rev_surah_to integer,
  rev_ayah_to integer,
  rev_ayahs_count integer default 0,
  rev_pages_count numeric(4,1) default 0,
  rev_score numeric(5,2) default 100,
  rev_notes jsonb default '[]'::jsonb,

  -- التجويد
  tajweed_score numeric(5,2) default 100,
  tajweed_notes jsonb default '[]'::jsonb,

  -- التقييم العام (متوسط حسابي متساوٍ)
  overall_score numeric(5,2) default 100,
  overall_rating text default 'ممتاز',
  general_notes text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 7. جدول حصص التعويض (Make-up Sessions)
create table if not exists public.makeup_sessions (
  id uuid default gen_random_uuid() primary key,
  session_id uuid references public.sessions(id) on delete cascade,
  student_name text not null,
  teacher_name text not null,
  reason text default 'غياب المعلم',
  status text default 'pending', -- pending, scheduled, completed, waived_by_student
  scheduled_date text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 8. جدول تنبيهات الطلاب عن تأخر المعلمين (Live Teacher Alerts)
create table if not exists public.teacher_alerts (
  id uuid default gen_random_uuid() primary key,
  session_id uuid references public.sessions(id) on delete set null,
  student_name text not null,
  teacher_name text not null,
  reported_at timestamp with time zone default timezone('utc'::text, now()) not null,
  status text default 'open',
  notes text
);

-- 9. جدول الشكاوى والملاحظات
create table if not exists public.complaints (
  id uuid default gen_random_uuid() primary key,
  from_user text not null,
  about text not null,
  status text default 'قيد المتابعة',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- تفعيل الحماية والصلاحيات العامة
alter table public.users_accounts enable row level security;
alter table public.teachers enable row level security;
alter table public.moderators enable row level security;
alter table public.students enable row level security;
alter table public.sessions enable row level security;
alter table public.evaluations enable row level security;
alter table public.makeup_sessions enable row level security;
alter table public.teacher_alerts enable row level security;
alter table public.complaints enable row level security;

create policy "Allow all for users_accounts" on public.users_accounts for all using (true);
create policy "Allow all for teachers" on public.teachers for all using (true);
create policy "Allow all for moderators" on public.moderators for all using (true);
create policy "Allow all for students" on public.students for all using (true);
create policy "Allow all for sessions" on public.sessions for all using (true);
create policy "Allow all for evaluations" on public.evaluations for all using (true);
create policy "Allow all for makeup_sessions" on public.makeup_sessions for all using (true);
create policy "Allow all for teacher_alerts" on public.teacher_alerts for all using (true);
create policy "Allow all for complaints" on public.complaints for all using (true);

-- =====================================================================
-- أكاديمية قرطبة لتعليم القرآن الكريم
-- كود إنشاء جداول قاعدة بيانات Supabase (SQL Schema)
-- انسخ هذا الكود بالكامل وضعه في: Supabase Dashboard -> SQL Editor -> New query -> RUN
-- =====================================================================

-- 1. جدول الحسابات والملفات الشخصية (مرتبط بـ auth.users)
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text,
  name text not null,
  role text not null check (role in ('admin', 'moderator', 'teacher', 'student')),
  phone text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. جدول المعلمين
create table if not exists public.teachers (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete set null,
  name text not null,
  area text default 'معلم قرآن وتجويد',
  students_count integer default 0,
  rating text default 'ممتاز',
  status text default 'نشط',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. جدول الطلاب
create table if not exists public.students (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete set null,
  name text not null,
  teacher_name text,
  program text default 'أطفال',
  progress integer default 0,
  last_rating text default 'ممتاز',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 4. جدول الحصص والمواعيد
create table if not exists public.sessions (
  id uuid default gen_random_uuid() primary key,
  student_name text not null,
  date_text text not null,
  time_text text not null,
  platform text default 'Zoom',
  link text default 'https://meet.google.com/new',
  status text default 'upcoming',
  attendance text default '',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 5. جدول التقييمات والتسميع
create table if not exists public.evaluations (
  id uuid default gen_random_uuid() primary key,
  student_name text not null,
  ward text not null,
  rating text default 'ممتاز',
  notes text,
  date_text text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 6. جدول الشكاوى والملاحظات
create table if not exists public.complaints (
  id uuid default gen_random_uuid() primary key,
  from_user text not null,
  about text not null,
  status text default 'قيد المتابعة',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- تفعيل الحماية والصلاحيات (Row Level Security)
alter table public.profiles enable row level security;
alter table public.teachers enable row level security;
alter table public.students enable row level security;
alter table public.sessions enable row level security;
alter table public.evaluations enable row level security;
alter table public.complaints enable row level security;

-- السماح بالوصول للبيانات (Policies)
create policy "Allow read for all users" on public.profiles for select using (true);
create policy "Allow all actions for profiles" on public.profiles for all using (true);

create policy "Allow read for teachers" on public.teachers for select using (true);
create policy "Allow all for teachers" on public.teachers for all using (true);

create policy "Allow read for students" on public.students for select using (true);
create policy "Allow all for students" on public.students for all using (true);

create policy "Allow read for sessions" on public.sessions for select using (true);
create policy "Allow all for sessions" on public.sessions for all using (true);

create policy "Allow read for evaluations" on public.evaluations for select using (true);
create policy "Allow all for evaluations" on public.evaluations for all using (true);

create policy "Allow read for complaints" on public.complaints for select using (true);
create policy "Allow all for complaints" on public.complaints for all using (true);

-- بيانات أولية تجريبية (Initial Seed Data)
insert into public.teachers (name, area, students_count, rating, status) values
  ('الشيخ أحمد فتحي', 'مجاز بالقراءات العشر الصغرى', 3, 'ممتاز', 'نشط'),
  ('الشيخة سارة عبد الله', 'مجازة برواية حفص وشعبة', 2, 'جيد', 'نشط')
on conflict do nothing;

insert into public.students (name, teacher_name, program, progress, last_rating) values
  ('يوسف أحمد', 'الشيخ أحمد فتحي', 'أطفال', 6, 'ممتاز'),
  ('مريم خالد', 'الشيخة سارة عبد الله', 'كبار', 14, 'جيد'),
  ('عبد الرحمن سعيد', 'الشيخ أحمد فتحي', 'أطفال', 3, 'يحتاج مراجعة'),
  ('نور محمد', 'الشيخ أحمد فتحي', 'أطفال', 9, 'ممتاز'),
  ('خالد إبراهيم', 'الشيخة سارة عبد الله', 'كبار', 20, 'ممتاز')
on conflict do nothing;

insert into public.sessions (student_name, date_text, time_text, platform, link, status, attendance) values
  ('يوسف أحمد', 'اليوم', '٥:٠٠ م', 'Zoom', 'https://zoom.us/j/demo', 'upcoming', ''),
  ('مريم خالد', 'غداً', '٧:٣٠ م', 'Google Meet', 'https://meet.google.com/demo', 'upcoming', ''),
  ('عبد الرحمن سعيد', 'أمس', '٦:٠٠ م', 'Zoom', '#', 'done', 'present')
on conflict do nothing;

insert into public.evaluations (student_name, date_text, ward, rating, notes) values
  ('يوسف أحمد', '٢٦ أغسطس', 'سورة الفاتحة كاملة', 'ممتاز', 'حفظ متقن وتلاوة سليمة.'),
  ('يوسف أحمد', '١٩ أغسطس', 'أواخر سورة الناس والفلق', 'جيد', 'يحتاج تثبيت أكثر على المخارج.'),
  ('مريم خالد', '٢٥ أغسطس', 'سورة مريم من آية ١ إلى ٣٠', 'جيد', 'مستوى طيب وأداء هادئ.')
on conflict do nothing;

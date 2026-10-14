-- AFIYA COLLECTION — Supabase database setup
-- Run this entire file in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null check (category in ('Fabric','Lace','Ready-Made')),
  subcategory text,
  fabric_type text,
  description text,
  price numeric(12,2) not null check (price >= 0),
  unit text not null check (unit in ('meter','piece')),
  colors text,
  stock_status text not null default 'Available' check (stock_status in ('Available','Limited','Out of Stock')),
  image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  image_url text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.enquiries (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null,
  phone text not null,
  product_id uuid references public.products(id) on delete set null,
  quantity numeric(12,2) not null check (quantity > 0),
  message text,
  status text not null default 'Pending' check (status in ('Pending','Contacted','Completed','Cancelled')),
  created_at timestamptz not null default now()
);

create table if not exists public.admins (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists public.store_settings (
  id uuid primary key default gen_random_uuid(),
  business_name text not null default 'AFIYA COLLECTION',
  founder_name text not null default 'Atif Ansari',
  phone_1 text not null default '8349864159',
  phone_2 text not null default '6267834159',
  email text not null default 'atifansari1442@gmail.com',
  address text not null default 'Imaam Chowk, Haat Maidan, Padana, Sarangpur, Madhya Pradesh, India',
  whatsapp_number text not null default '918349864159'
);

insert into public.categories(name,description) values
('Fabric','Ladies fabrics sold by the meter'),
('Lace','Ladies laces and borders sold by the meter'),
('Ready-Made','Selected ready-made ladies clothing')
on conflict (name) do nothing;

insert into public.store_settings(business_name,founder_name,phone_1,phone_2,email,address,whatsapp_number)
select 'AFIYA COLLECTION','Atif Ansari','8349864159','6267834159','atifansari1442@gmail.com','Imaam Chowk, Haat Maidan, Padana, Sarangpur, Madhya Pradesh, India','918349864159'
where not exists (select 1 from public.store_settings);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists products_updated_at on public.products;
create trigger products_updated_at before update on public.products
for each row execute function public.set_updated_at();

-- Enable RLS
alter table public.products enable row level security;
alter table public.product_images enable row level security;
alter table public.enquiries enable row level security;
alter table public.categories enable row level security;
alter table public.admins enable row level security;
alter table public.store_settings enable row level security;

-- Public catalogue reads
drop policy if exists "Public can read products" on public.products;
create policy "Public can read products" on public.products
for select to anon, authenticated using (stock_status <> 'Out of Stock');

drop policy if exists "Public can read product images" on public.product_images;
create policy "Public can read product images" on public.product_images
for select to anon, authenticated using (true);

drop policy if exists "Public can read categories" on public.categories;
create policy "Public can read categories" on public.categories
for select to anon, authenticated using (true);

drop policy if exists "Public can read store settings" on public.store_settings;
create policy "Public can read store settings" on public.store_settings
for select to anon, authenticated using (true);

-- Public enquiry insert only
drop policy if exists "Public can submit enquiries" on public.enquiries;
create policy "Public can submit enquiries" on public.enquiries
for insert to anon, authenticated
with check (char_length(customer_name) between 1 and 80 and char_length(phone) between 8 and 18 and quantity > 0);

-- Admin helper: the logged-in auth user must exist in admins
create or replace function public.is_admin()
returns boolean language sql security definer set search_path = public stable as $$
  select exists(select 1 from public.admins where id = auth.uid());
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

-- Admin product CRUD
drop policy if exists "Admins manage products" on public.products;
create policy "Admins manage products" on public.products
for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Admins manage product images" on public.product_images;
create policy "Admins manage product images" on public.product_images
for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Admins manage categories" on public.categories;
create policy "Admins manage categories" on public.categories
for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Admins manage enquiries" on public.enquiries;
create policy "Admins manage enquiries" on public.enquiries
for select, update, delete to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Admins manage settings" on public.store_settings;
create policy "Admins manage settings" on public.store_settings
for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Admins read admin list" on public.admins;
create policy "Admins read admin list" on public.admins
for select to authenticated using (public.is_admin());

-- Storage bucket
insert into storage.buckets (id,name,public)
values ('products','products',true)
on conflict (id) do update set public=true;

drop policy if exists "Public can view product images" on storage.objects;
create policy "Public can view product images" on storage.objects
for select to public using (bucket_id='products');

drop policy if exists "Admins upload product images" on storage.objects;
create policy "Admins upload product images" on storage.objects
for insert to authenticated with check (bucket_id='products' and public.is_admin());

drop policy if exists "Admins update product images" on storage.objects;
create policy "Admins update product images" on storage.objects
for update to authenticated using (bucket_id='products' and public.is_admin()) with check (bucket_id='products' and public.is_admin());

drop policy if exists "Admins delete product images" on storage.objects;
create policy "Admins delete product images" on storage.objects
for delete to authenticated using (bucket_id='products' and public.is_admin());

-- After creating the first Auth user in Supabase Dashboard, run:
-- INSERT INTO public.admins(id,email) VALUES ('AUTH_USER_UUID_HERE','your-admin-email@example.com');

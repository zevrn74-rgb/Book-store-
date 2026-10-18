-- CHARLES Bookstore database schema
-- Run in Supabase SQL Editor. Safe to run again for tables/policies created here.

create extension if not exists pgcrypto;

create table if not exists public.store_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  author text not null default '',
  category text not null default 'Self-Help',
  description text not null default '',
  image_url text not null default '',
  mrp numeric(10,2) not null default 0 check (mrp >= 0),
  price numeric(10,2) not null default 0 check (price >= 0),
  stock integer not null default 0 check (stock >= 0),
  featured boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null,
  email text not null default '',
  phone text not null,
  address text not null,
  city text not null,
  pincode text not null,
  payment_method text not null check (payment_method in ('COD','UPI')),
  payment_status text not null default 'pending' check (payment_status in ('pending','paid','failed','refunded')),
  status text not null default 'Placed' check (status in ('Placed','Confirmed','Processing','Packed','Shipped','Out for Delivery','Delivered','Cancelled','Returned','Refunded')),
  total numeric(10,2) not null check (total >= 0),
  items jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.store_admins enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;

-- A user is an admin only if their authenticated UUID is listed in store_admins.
create or replace function public.is_store_admin()
returns boolean language sql stable security definer
set search_path = public
as $$
  select exists (select 1 from public.store_admins where user_id = auth.uid());
$$;

drop policy if exists "Admins can read admin list" on public.store_admins;
create policy "Admins can read admin list" on public.store_admins
for select to authenticated using (public.is_store_admin());

drop policy if exists "Public can view products" on public.products;
create policy "Public can view products" on public.products
for select to anon, authenticated using (true);

drop policy if exists "Admins can manage products" on public.products;
create policy "Admins can manage products" on public.products
for all to authenticated using (public.is_store_admin()) with check (public.is_store_admin());

drop policy if exists "Customers can submit orders" on public.orders;
create policy "Customers can submit orders" on public.orders
for insert to anon, authenticated with check (
  status = 'Placed' and payment_status = 'pending'
);

drop policy if exists "Admins can view and manage orders" on public.orders;
create policy "Admins can view and manage orders" on public.orders
for all to authenticated using (public.is_store_admin()) with check (public.is_store_admin());

grant usage on schema public to anon, authenticated;
grant select on public.products to anon, authenticated;
grant insert, update, delete on public.products to authenticated;
grant insert on public.orders to anon, authenticated;
grant select, update on public.orders to authenticated;
grant select on public.store_admins to authenticated;

-- Optional sample books. Delete these INSERT rows if you prefer an empty catalogue.
insert into public.products (title, author, category, description, image_url, mrp, price, stock, featured)
select * from (values
('The Mountain Is You','Brianna Wiest','Self-Help','A thoughtful guide to understanding self-sabotage and building better habits.','https://images.unsplash.com/photo-1544947950-fa07a98d237f?auto=format&fit=crop&w=800&q=85',399::numeric,299::numeric,7,true),
('Surrounded by Idiots','Thomas Erikson','Psychology','A popular introduction to different communication styles and personalities.','https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=800&q=85',699::numeric,499::numeric,10,true),
('Atomic Habits','James Clear','Self-Help','Small habits, remarkable results: a practical approach to lasting change.','https://images.unsplash.com/photo-1543002588-bfa74002ed7e?auto=format&fit=crop&w=800&q=85',599::numeric,399::numeric,8,true),
('Ikigai','Héctor García & Francesc Miralles','Personal Development','Explore the Japanese concept of finding purpose and meaning in everyday life.','https://images.unsplash.com/photo-1519682337058-a94d519337bc?auto=format&fit=crop&w=800&q=85',399::numeric,279::numeric,6,false)
) as v(title,author,category,description,image_url,mrp,price,stock,featured)
where not exists (select 1 from public.products);

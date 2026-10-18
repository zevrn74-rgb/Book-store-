# CHARLES Bookstore — Vercel-ready project

Mobile-first React + Vite + TypeScript storefront with a private owner dashboard at `/admin`, Supabase products/orders, cart, COD and UPI instructions.

## Android-friendly deployment (GitHub + Vercel)

1. Download and extract this ZIP on your Android phone (Files app or ZArchiver).
2. Upload the extracted project files to a new GitHub repository. Keep `package.json`, `index.html`, `src/`, `supabase/`, and `vercel.json` at the repository root — do not upload an extra parent folder around them.
3. Open https://vercel.com and sign in with GitHub. Choose **Add New → Project**, import the repository, then deploy. Vercel should detect Vite automatically. Build command: `npm run build`; output directory: `dist`.
4. Before the final deployment, open Vercel **Project → Settings → Environment Variables** and add:
   - `VITE_SUPABASE_URL` = `https://iezqpoxtennphvtmrcbj.supabase.co` (the previously used CHARLES project URL)
   - `VITE_SUPABASE_ANON_KEY` = the project's **publishable key** (or legacy anon public key) from Supabase → Project Settings → API Keys
   - `VITE_UPI_ID` = `8384059345@fam`
   - `VITE_STORE_EMAIL` = `charlesbooklibrary@gmail.com`
   - `VITE_STORE_PHONE` = `8384059345`
5. Save variables, then go to **Deployments** and redeploy the latest deployment so the variables are included in the build.
6. Open your deployed website. The private owner sign-in page is at `https://YOUR-VERCEL-DOMAIN.vercel.app/admin`. There is no admin link in the customer-facing footer/navigation.

## IMPORTANT: preserve the existing Supabase project

This project is configured for the existing Supabase URL `https://iezqpoxtennphvtmrcbj.supabase.co`. Do **not** create a new Supabase project, reset the database, delete tables, or blindly run the complete schema on an existing database.

Before changing database structure, open that project in Supabase → SQL Editor and run this read-only check:

```sql
select
  to_regclass('public.products') as products_table,
  to_regclass('public.orders') as orders_table,
  to_regclass('public.store_admins') as store_admins_table;
```

If a table is missing, or the site reports a column/policy error, stop and diagnose the specific issue first. `supabase/schema.sql` is a reference setup for a new/compatible database, not an instruction to overwrite an existing database. It includes optional sample books; review it before running anything.

## Owner/admin access

1. In Supabase → Authentication → Users, create or use your owner login.
2. Copy that user's UUID.
3. Only if the `store_admins` table exists with the expected schema and the user is not already registered as an admin, add the UUID using SQL Editor:

```sql
insert into public.store_admins (user_id) values ('PASTE-OWNER-UUID-HERE')
on conflict (user_id) do nothing;
```

Never put a Supabase `service_role` secret, database password, or Razorpay secret in Vercel frontend environment variables. The publishable/anon key is intended for browser use with correctly configured Row Level Security (RLS).

## Payments and production notes

- COD orders are submitted to Supabase.
- UPI displays the store's UPI payment instructions; payment is **not automatically verified** by this starter.
- Card payments are not offered. Razorpay is not integrated in this ZIP.
- Test product reads, admin login, product edits and a test order after deployment. Confirm RLS policies before accepting real orders.
- Add accurate shipping, returns, privacy and terms information before launch.

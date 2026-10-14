# AFIYA COLLECTION — Full-Stack Catalogue

A professional, mobile-first ladies fabric catalogue built with HTML5, CSS3, Vanilla JavaScript and Supabase.

## 1. Create Supabase project
1. Open https://supabase.com/
2. Create a new project.
3. Open SQL Editor.
4. Paste the complete `database.sql`.
5. Run it.

## 2. Configure authentication
In Supabase Dashboard → Authentication → Providers:
- Keep Email enabled.
- Create an admin user from Authentication → Users → Add user.
- Copy that user's UUID.
- In SQL Editor run:
  `INSERT INTO public.admins(id,email) VALUES ('USER_UUID','YOUR_EMAIL');`

## 3. Frontend credentials
Open `js/supabase.js` and replace:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Use the browser-safe publishable/anon key only. NEVER use a service_role/secret key in frontend code.

## 4. Storage
`database.sql` creates the public `products` bucket and storage policies.
If your project does not allow bucket creation through SQL, create it manually:
Storage → New bucket → Name: `products` → Public: ON.
Then keep the storage policies from `database.sql`.

## 5. Run locally
Do not open HTML through `file://` for the final test. Use a local server.

Python:
`python -m http.server 5500`

Then open:
`http://localhost:5500`

Apache:
Copy the Afiya-Collection folder into your Apache web root, then open:
`http://localhost/Afiya-Collection/`

## 6. Add the first product
1. Open `login.html`.
2. Sign in with the Auth user that is also listed in `public.admins`.
3. Dashboard → Add product.
4. Choose category, subcategory, fabric type, price, unit and stock status.
5. Select an image.
6. Save.

The image is uploaded to Supabase Storage and its public URL is stored in `products.image_url`.

## 7. Enquiries
Customers click `Enquire` on any product.
The form inserts a row into `enquiries`.
Admins see enquiries in the dashboard and can change status:
Pending → Contacted → Completed / Cancelled.

## 8. Security
- RLS is enabled on application tables.
- Public users can read catalogue data.
- Public users can insert enquiries only.
- Product create/update/delete requires an authenticated user listed in `admins`.
- Admin dashboard verifies the authenticated user against `admins`.
- The service_role key is never used in frontend JavaScript.

## 9. Deploy
You can deploy this static frontend to Netlify, Vercel, GitHub Pages (with suitable static hosting configuration), Cloudflare Pages, or your own Apache/Nginx server.
After deployment, add your production URL in Supabase Authentication → URL Configuration:
- Site URL
- Redirect URLs if you later add OAuth or password reset flows.

## 10. Changing business details
For the current version, the public contact details are stored in `js/main.js` in the `BUSINESS` object and the contact/footer HTML. Update them consistently if your business details change. The database also contains `store_settings` for future dynamic settings support.

## 11. Product management
Admin dashboard supports:
- Add
- Edit
- Delete
- Image upload
- Price changes
- Category and fabric type changes
- Stock status changes
- Description and colours
- Enquiry status management

## Notes
This is a catalogue/enquiry system, not a checkout/payment system. No online payment is implemented.

-- ─── Migrate users from remote Supabase to local ────────────────────────────
-- Generated from remote project: magzmlktbeolsbkssqxo

-- 1) auth.users
INSERT INTO auth.users (
  id, email, email_confirmed_at, phone, phone_confirmed_at,
  raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at, last_sign_in_at,
  role, encrypted_password, confirmation_token,
  recovery_token, aud, banned_until, is_sso_user,
  instance_id,
  email_change, phone_change, email_change_token_new,
  email_change_token_current, reauthentication_token
) VALUES
(
  '2305337d-c09d-4414-93a1-88ddb38ad97e',
  'test@test.com',
  '2026-01-20 14:13:52.342931+00',
  NULL, NULL,
  '{"provider":"email","providers":["email"]}',
  '{"email_verified":true}',
  '2026-01-20 14:13:52.292169+00',
  '2026-02-28 12:15:56.193947+00',
  '2026-02-28 12:15:54.503307+00',
  'authenticated',
  '$2a$10$B1Xcy3BvE1pPi9mPP6YGEuNhxGdaPEHyd6BfP9yCjeqxLUFXv2.5.',
  '', '', 'authenticated', NULL, false,
  '00000000-0000-0000-0000-000000000000'
),
(
  'edc2b1b1-2905-4bf4-95c8-e7956ab85d73',
  'admin@menubak.tr',
  '2026-01-21 06:41:18.791742+00',
  NULL, NULL,
  '{"provider":"email","providers":["email"]}',
  '{"email_verified":true}',
  '2026-01-21 06:41:18.769139+00',
  '2026-01-30 15:19:17.931452+00',
  '2026-01-30 06:24:00.209411+00',
  'authenticated',
  '$2a$10$ZM/E4tRrF933NkpmQ5vyq.DwTgxamhoDBqT9fX8Ad3YmvzNBYCxKG',
  '', '', 'authenticated', NULL, false,
  '00000000-0000-0000-0000-000000000000'
),
(
  'a4a2a039-9d46-4005-8881-699cb5d1a267',
  'a@a.com',
  '2026-01-29 14:53:43.408842+00',
  NULL, NULL,
  '{"provider":"email","providers":["email"]}',
  '{"email_verified":true}',
  '2026-01-29 14:53:43.376915+00',
  '2026-03-02 14:13:17.17367+00',
  '2026-03-02 14:13:16.795261+00',
  'authenticated',
  '$2a$10$GUCNG1iv9FhRoiz704Rd1ecwu3XpWcz0Ax2k./Lve84iHxiiuOsGi',
  '', '', 'authenticated', NULL, false,
  '00000000-0000-0000-0000-000000000000'
),
(
  '95d14dba-7d57-413c-9939-8bddf80d494f',
  'admin@yeedoy.com',
  '2026-02-19 09:35:11.784117+00',
  NULL, NULL,
  '{"provider":"email","providers":["email"]}',
  '{"email_verified":true}',
  '2026-02-19 09:35:11.755197+00',
  '2026-03-11 14:02:24.335549+00',
  '2026-03-11 14:02:24.307891+00',
  'authenticated',
  '$2a$10$5YoiUNzrksxGRd5dGYS3seTFekKD8F3GNlGnZ9KPfeQ4cwVPuSGi6',
  '', '', 'authenticated', NULL, false,
  '00000000-0000-0000-0000-000000000000'
)
ON CONFLICT (id) DO NOTHING;

-- 2) auth.identities
INSERT INTO auth.identities (
  id, user_id, provider, identity_data, provider_id,
  created_at, updated_at, last_sign_in_at
) VALUES
(
  '8a8d0652-5efd-4f75-8207-6923ad1d684d',
  '2305337d-c09d-4414-93a1-88ddb38ad97e',
  'email',
  '{"sub":"2305337d-c09d-4414-93a1-88ddb38ad97e","email":"test@test.com","email_verified":false,"phone_verified":false}',
  '2305337d-c09d-4414-93a1-88ddb38ad97e',
  '2026-01-20 14:13:52.327172+00',
  '2026-01-20 14:13:52.327172+00',
  '2026-01-20 14:13:52.327107+00'
),
(
  '8749462f-a588-423e-b5f0-f50765e3fd40',
  'edc2b1b1-2905-4bf4-95c8-e7956ab85d73',
  'email',
  '{"sub":"edc2b1b1-2905-4bf4-95c8-e7956ab85d73","email":"admin@menubak.tr","email_verified":false,"phone_verified":false}',
  'edc2b1b1-2905-4bf4-95c8-e7956ab85d73',
  '2026-01-21 06:41:18.783427+00',
  '2026-01-21 06:41:18.783427+00',
  '2026-01-21 06:41:18.783366+00'
),
(
  '62aeeb2f-8672-470f-a5ff-89008986ccb5',
  'a4a2a039-9d46-4005-8881-699cb5d1a267',
  'email',
  '{"sub":"a4a2a039-9d46-4005-8881-699cb5d1a267","email":"a@a.com","email_verified":false,"phone_verified":false}',
  'a4a2a039-9d46-4005-8881-699cb5d1a267',
  '2026-01-29 14:53:43.397281+00',
  '2026-01-29 14:53:43.397281+00',
  '2026-01-29 14:53:43.396128+00'
),
(
  '6fdead5e-2778-4874-aec0-8678c5ac0784',
  '95d14dba-7d57-413c-9939-8bddf80d494f',
  'email',
  '{"sub":"95d14dba-7d57-413c-9939-8bddf80d494f","email":"admin@yeedoy.com","email_verified":false,"phone_verified":false}',
  '95d14dba-7d57-413c-9939-8bddf80d494f',
  '2026-02-19 09:35:11.768530+00',
  '2026-02-19 09:35:11.768530+00',
  '2026-02-19 09:35:11.768475+00'
)
ON CONFLICT (id) DO NOTHING;

-- 3) public.admin_users (admin@menubak.tr ve admin@yeedoy.com)
INSERT INTO public.admin_users (user_id, created_at) VALUES
  ('edc2b1b1-2905-4bf4-95c8-e7956ab85d73', '2026-01-21 06:41:35.222678+00'),
  ('95d14dba-7d57-413c-9939-8bddf80d494f', '2026-02-19 09:39:03.274751+00')
ON CONFLICT (user_id) DO NOTHING;

-- 4) public.user_profiles
INSERT INTO public.user_profiles (
  user_id, display_name, avatar_url, bio,
  is_gourmet, created_at, updated_at, shadow_banned
) VALUES
(
  'edc2b1b1-2905-4bf4-95c8-e7956ab85d73',
  'admin', '', NULL, false,
  '2026-01-29 08:29:05.267048+00',
  '2026-01-29 14:49:09.97995+00',
  false
),
(
  'a4a2a039-9d46-4005-8881-699cb5d1a267',
  'a', '', NULL, false,
  '2026-01-29 14:54:27.127892+00',
  '2026-01-30 13:02:19.998804+00',
  false
)
ON CONFLICT (user_id) DO NOTHING;

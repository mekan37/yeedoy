insert into public.policy_versions (
  policy_type,
  version_label,
  content_hash,
  published_at,
  is_active
)
values
  ('terms', '2026.03-tr-v1', md5('terms:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true),
  ('privacy', '2026.03-tr-v1', md5('privacy:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true),
  ('cookies', '2026.03-tr-v1', md5('cookies:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true),
  ('community', '2026.03-tr-v1', md5('community:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true),
  ('business', '2026.03-tr-v1', md5('business:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true),
  ('copyright', '2026.03-tr-v1', md5('copyright:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true),
  ('ai', '2026.03-tr-v1', md5('ai:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true),
  ('dmca', '2026.03-tr-v1', md5('dmca:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true),
  ('dsa', '2026.03-tr-v1', md5('dsa:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true),
  ('data-safety', '2026.03-tr-v1', md5('data-safety:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true),
  ('trust-safety', '2026.03-tr-v1', md5('trust-safety:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true),
  ('security', '2026.03-tr-v1', md5('security:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true),
  ('law-enforcement', '2026.03-tr-v1', md5('law-enforcement:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true),
  ('delete-account', '2026.03-tr-v1', md5('delete-account:2026.03-tr-v1'), '2026-03-10T00:00:00Z', true)
on conflict (policy_type, version_label) do update
set
  content_hash = excluded.content_hash,
  published_at = excluded.published_at,
  is_active = excluded.is_active;

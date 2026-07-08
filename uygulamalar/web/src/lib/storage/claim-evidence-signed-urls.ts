/**
 * Regenerates fresh signed URLs for owner_claims evidence files from their
 * durable storage path. The path is the canonical reference; evidence_url
 * (stored at submission time) expires after 30 days and should not be relied
 * on for display. Uses the caller's own Supabase session — RLS policy
 * claim_evidence_select_owner_or_admin already allows is_admin() to read any
 * object in the claim-evidence bucket, so no service role key is needed here.
 */
export async function attachEvidenceSignedUrls(
  supabase: unknown,
  claims: Array<Record<string, unknown>>,
): Promise<Array<Record<string, unknown> & { evidence_signed_url: string | null }>> {
  const paths = claims
    .map((c) => c.evidence_storage_path as string | null | undefined)
    .filter((p): p is string => Boolean(p));

  const signedUrlByPath = new Map<string, string>();

  if (paths.length > 0) {
    const supabaseAny = supabase as {
      storage: { from: (bucket: string) => { createSignedUrls: (paths: string[], expiresIn: number) => Promise<{ data: Array<{ path: string | null; signedUrl: string }> | null }> } };
    };
    const { data } = await supabaseAny.storage
      .from('claim-evidence')
      .createSignedUrls(paths, 60 * 60); // 1 saat — sadece bu sayfa görüntülemesi için

    for (const item of data ?? []) {
      if (item.path && item.signedUrl) signedUrlByPath.set(item.path, item.signedUrl);
    }
  }

  return claims.map((c) => {
    const path = c.evidence_storage_path as string | null | undefined;
    return {
      ...c,
      evidence_signed_url: path ? signedUrlByPath.get(path) ?? null : null,
    };
  });
}

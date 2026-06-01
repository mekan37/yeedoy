/**
 * Re-export shim — canonical source is `src/lib/veri/admin/yonetici-kuyrugu.ts`.
 *
 * LOW-005 audit resolution (2026-05-25): This file previously used incorrect
 * fallback table names (`business_claims` / `price_suggestions`). The correct
 * current table names per the DB schema are `owner_claims` and
 * `menu_item_price_suggestions`, which the canonical file uses. Both files
 * have 0 callers (dead code). This file is kept as a shim to avoid breaking
 * any future imports; do not add new logic here.
 */
export {
  type QueueCounts,
  type ReportRow,
  type BusinessSubmissionRow,
  getQueueCounts,
  listOpenReports,
  listPendingSubmissions,
} from '@/src/lib/veri/admin/yonetici-kuyrugu';

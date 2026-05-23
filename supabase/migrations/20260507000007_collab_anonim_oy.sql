-- Anonim oy sistemi için voter_ip sütunu ekle
ALTER TABLE collab_list_votes
  ADD COLUMN IF NOT EXISTS voter_ip TEXT;

-- voter_ip bazlı unique constraint — IP başına item başına bir oy
CREATE UNIQUE INDEX IF NOT EXISTS idx_collab_list_votes_ip_item
  ON collab_list_votes (list_id, item_id, voter_ip)
  WHERE voter_ip IS NOT NULL;

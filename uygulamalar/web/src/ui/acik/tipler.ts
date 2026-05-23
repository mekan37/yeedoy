export type AcikIsletmeKarti = {
  id: string;
  name: string;
  slug: string;
  publicSlug?: string | null;
  category?: string | null;
  description?: string | null;
  city?: string | null;
  district?: string | null;
  address?: string | null;
  logoUrl?: string | null;
  coverUrl?: string | null;
  isVerified?: boolean | null;
  isActive?: boolean | null;
  isOpenNow?: boolean | null;
  avgRating?: number | null;
  reviewCount?: number | null;
  distanceKm?: number | null;
  medianPriceCents?: number | null;
  recentPriceVerifiedCount?: number | null;
  menuHref?: string | null;
};

export type AcikMenuUrunKarti = {
  id: string;
  name: string;
  description?: string | null;
  priceCents: number;
  currency: string;
  isAvailable: boolean;
  imageUrl?: string | null;
  tags?: string[];
  allergens?: string[];
};

export type AcikYorumKarti = {
  id: string;
  author: string;
  rating: number;
  content?: string | null;
  createdAt: string;
  verifiedVisit?: boolean | null;
  helpfulCount?: number | null;
};

export type BusinessSummary = {
  id: string;
  slug?: string;
  name: string;
  city?: string;
  district?: string;
  category?: string;
  verified?: boolean;
};

export type MenuCategory = {
  id: string;
  businessId: string;
  name: string;
  orderNo?: number;
  isActive?: boolean;
};

export type MenuItem = {
  id: string;
  categoryId: string;
  name: string;
  description?: string;
  priceCents?: number;
  imageUrl?: string;
  isActive?: boolean;
};

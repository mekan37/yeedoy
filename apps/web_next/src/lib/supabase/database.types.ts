export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

type Table<Row> = {
  Row: Row;
  Insert: Partial<Row>;
  Update: Partial<Row>;
  Relationships: [];
};

export type Database = {
  public: {
    Tables: {
      analytics_events: Table<{
        id: string;
        created_at: string | null;
        event_name: string;
        business_id: string | null;
        menu_id: string | null;
        source: string | null;
        client_id: string | null;
        user_id: string | null;
        meta: Json;
      }>;
      business_hours: Table<{
        business_id: string;
        mon_open: string | null;
        mon_close: string | null;
        tue_open: string | null;
        tue_close: string | null;
        wed_open: string | null;
        wed_close: string | null;
        thu_open: string | null;
        thu_close: string | null;
        fri_open: string | null;
        fri_close: string | null;
        sat_open: string | null;
        sat_close: string | null;
        sun_open: string | null;
        sun_close: string | null;
        updated_at: string;
      }>;
      business_media: Table<{
        id: string;
        business_id: string;
        kind: string;
        url: string;
        url_large: string | null;
        url_thumb: string | null;
        provider: string;
        width: number | null;
        height: number | null;
        created_at: string;
        created_by: string | null;
        is_shadow: boolean;
        status: string;
        is_hidden: boolean;
        moderation_note: string | null;
      }>;
      business_menu_presentation_settings: Table<{
        business_id: string;
        created_at: string;
        updated_at: string;
        default_lang: string;
        template_key: string;
        settings: Json;
        logo_url: string | null;
        cover_url: string | null;
        background_url: string | null;
      }>;
      businesses: Table<{
        id: string;
        name: string;
        slug: string | null;
        public_slug: string | null;
        category: string;
        description: string | null;
        phone: string | null;
        address: string | null;
        city: string | null;
        district: string | null;
        lat: number | null;
        lng: number | null;
        is_active: boolean;
        created_at: string;
        logo_url: string | null;
        cover_url: string | null;
        reservation_url: string | null;
        order_yemeksepeti_url: string | null;
        order_trendyolgo_url: string | null;
        order_getir_url: string | null;
        neighborhood: string | null;
        is_verified: boolean;
      }>;
      menu_categories: Table<{
        id: string;
        business_id: string;
        is_active: boolean;
        created_at: string;
        sort_order: number;
        menu_id: string | null;
      }>;
      menu_items: Table<{
        id: string;
        section_id: string;
        business_id: string;
        name: string;
        description: string | null;
        price_cents: number;
        currency: string;
        created_at: string;
        updated_at: string;
        category_id: string | null;
        is_available: boolean;
        image_url: string | null;
        tags: Json;
        sort_order: number;
      }>;
      menu_sections: Table<{
        id: string;
        menu_id: string;
        title: string;
        sort_order: number;
        created_by: string | null;
        created_at: string;
        updated_at: string;
      }>;
      menu_translations: Table<{
        id: string;
        entity_type: 'business' | 'category' | 'item';
        entity_id: string;
        locale: string;
        name: string;
        description: string | null;
        created_at: string;
      }>;
      menus: Table<{
        id: string;
        business_id: string;
        title: string;
        status: 'draft' | 'published' | 'archived';
        created_by: string | null;
        created_at: string;
        updated_at: string;
        kind: string | null;
        active_from: string | null;
        active_to: string | null;
        version: number;
        source: string;
        confidence_score: number;
      }>;
    };
    Views: Record<string, never>;
    Functions: {
      get_menu_item_photos_v1: {
        Args: { p_menu_item_id: string; p_limit: number };
        Returns: {
          id: string;
          url: string;
          url_large: string | null;
          url_thumb: string | null;
          provider: string;
          created_at: string;
          up_votes: number;
          down_votes: number;
          score: number;
          my_vote: number | null;
        }[];
      };
      get_menu_item_variants_v1: {
        Args: { p_menu_item_id: string };
        Returns: {
          id: string;
          menu_item_id: string;
          label: string;
          price_cents: number;
          currency: string;
          is_default: boolean;
          is_available: boolean;
          sort_order: number;
        }[];
      };
      get_menu_items_v1: {
        Args: { p_menu_id: string };
        Returns: {
          id: string;
          section_id: string;
          name: string;
          description: string | null;
          price_cents: number;
          currency: string;
          calories: number | null;
          is_vegan: boolean | null;
          is_vegetarian: boolean | null;
          is_gluten_free: boolean | null;
          is_lactose_free: boolean | null;
          is_halal: boolean | null;
        }[];
      };
      can_manage_business_v1: {
        Args: { p_business_id: string };
        Returns: boolean;
      };
      log_event_v1: {
        Args: {
          p_event_name: string;
          p_business_id?: string | null;
          p_menu_id?: string | null;
          p_source?: string | null;
          p_client_id?: string | null;
          p_meta?: Json | null;
        };
        Returns: Json;
      };
      public_menu_share_view_v1: {
        Args: { p_menu_id: string };
        Returns: Json;
      };
    };
    Enums: Record<string, never>;
    CompositeTypes: Record<string, never>;
  };
};

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  public: {
    Tables: {
      account_deletion_requests: {
        Row: {
          completed_at: string | null
          created_at: string
          id: string
          reason: string
          requested_at: string
          status: string
          user_id: string
        }
        Insert: {
          completed_at?: string | null
          created_at?: string
          id?: string
          reason?: string
          requested_at?: string
          status?: string
          user_id: string
        }
        Update: {
          completed_at?: string | null
          created_at?: string
          id?: string
          reason?: string
          requested_at?: string
          status?: string
          user_id?: string
        }
        Relationships: []
      }
      achievements: {
        Row: {
          color: string
          condition: Json
          created_at: string
          description: string
          icon: string
          id: string
          is_hidden: boolean
          title: string
          xp: number
        }
        Insert: {
          color?: string
          condition?: Json
          created_at?: string
          description: string
          icon?: string
          id: string
          is_hidden?: boolean
          title: string
          xp?: number
        }
        Update: {
          color?: string
          condition?: Json
          created_at?: string
          description?: string
          icon?: string
          id?: string
          is_hidden?: boolean
          title?: string
          xp?: number
        }
        Relationships: []
      }
      admin_audit_log: {
        Row: {
          action: string
          actor_id: string | null
          actor_role: string | null
          admin_user_id: string | null
          after_data: Json | null
          before_data: Json | null
          created_at: string
          id: string
          ip: string | null
          meta: Json
          target_id: string | null
          target_table: string | null
          target_type: string | null
          user_agent: string | null
        }
        Insert: {
          action: string
          actor_id?: string | null
          actor_role?: string | null
          admin_user_id?: string | null
          after_data?: Json | null
          before_data?: Json | null
          created_at?: string
          id?: string
          ip?: string | null
          meta?: Json
          target_id?: string | null
          target_table?: string | null
          target_type?: string | null
          user_agent?: string | null
        }
        Update: {
          action?: string
          actor_id?: string | null
          actor_role?: string | null
          admin_user_id?: string | null
          after_data?: Json | null
          before_data?: Json | null
          created_at?: string
          id?: string
          ip?: string | null
          meta?: Json
          target_id?: string | null
          target_table?: string | null
          target_type?: string | null
          user_agent?: string | null
        }
        Relationships: []
      }
      admin_runtime_settings: {
        Row: {
          key: string
          settings: Json
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          key: string
          settings?: Json
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          key?: string
          settings?: Json
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: []
      }
      admin_users: {
        Row: {
          created_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          user_id?: string
        }
        Relationships: []
      }
      alert_events: {
        Row: {
          alert_id: string
          business_id: string
          created_at: string
          created_day: string
          district_avg_price_cents: number | null
          id: string
          matched_price_cents: number
          menu_item_id: string | null
          previous_price_cents: number | null
          user_id: string
        }
        Insert: {
          alert_id: string
          business_id: string
          created_at?: string
          created_day?: string
          district_avg_price_cents?: number | null
          id?: string
          matched_price_cents: number
          menu_item_id?: string | null
          previous_price_cents?: number | null
          user_id: string
        }
        Update: {
          alert_id?: string
          business_id?: string
          created_at?: string
          created_day?: string
          district_avg_price_cents?: number | null
          id?: string
          matched_price_cents?: number
          menu_item_id?: string | null
          previous_price_cents?: number | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "alert_events_alert_id_fkey"
            columns: ["alert_id"]
            isOneToOne: false
            referencedRelation: "price_alerts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "alert_events_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "alert_events_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "alert_events_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "alert_events_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      analytics_events: {
        Row: {
          business_id: string | null
          client_id: string | null
          created_at: string | null
          event_name: string
          id: string
          menu_id: string | null
          meta: Json
          source: string | null
          user_id: string | null
        }
        Insert: {
          business_id?: string | null
          client_id?: string | null
          created_at?: string | null
          event_name: string
          id?: string
          menu_id?: string | null
          meta?: Json
          source?: string | null
          user_id?: string | null
        }
        Update: {
          business_id?: string | null
          client_id?: string | null
          created_at?: string | null
          event_name?: string
          id?: string
          menu_id?: string | null
          meta?: Json
          source?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "analytics_events_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "analytics_events_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "analytics_events_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "analytics_events_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "analytics_events_menu_id_fkey"
            columns: ["menu_id"]
            isOneToOne: false
            referencedRelation: "menus"
            referencedColumns: ["id"]
          },
        ]
      }
      api_keys: {
        Row: {
          created_at: string
          created_by: string | null
          expires_at: string | null
          id: string
          is_active: boolean
          key_hash: string
          last_used_at: string | null
          name: string
          prefix: string
          scope: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          expires_at?: string | null
          id?: string
          is_active?: boolean
          key_hash: string
          last_used_at?: string | null
          name: string
          prefix: string
          scope?: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          expires_at?: string | null
          id?: string
          is_active?: boolean
          key_hash?: string
          last_used_at?: string | null
          name?: string
          prefix?: string
          scope?: string
          updated_at?: string
        }
        Relationships: []
      }
      audit_logs: {
        Row: {
          action: string
          created_at: string
          id: string
          ip_address: unknown
          metadata: Json | null
          new_data: Json | null
          old_data: Json | null
          resource_id: string | null
          resource_type: string | null
          user_agent: string | null
          user_id: string | null
        }
        Insert: {
          action: string
          created_at?: string
          id?: string
          ip_address?: unknown
          metadata?: Json | null
          new_data?: Json | null
          old_data?: Json | null
          resource_id?: string | null
          resource_type?: string | null
          user_agent?: string | null
          user_id?: string | null
        }
        Update: {
          action?: string
          created_at?: string
          id?: string
          ip_address?: unknown
          metadata?: Json | null
          new_data?: Json | null
          old_data?: Json | null
          resource_id?: string | null
          resource_type?: string | null
          user_agent?: string | null
          user_id?: string | null
        }
        Relationships: []
      }
      bulk_op_logs: {
        Row: {
          action: string
          count: number
          created_at: string
          id: string
          op_type: string
          operator: string | null
        }
        Insert: {
          action: string
          count?: number
          created_at?: string
          id?: string
          op_type: string
          operator?: string | null
        }
        Update: {
          action?: string
          count?: number
          created_at?: string
          id?: string
          op_type?: string
          operator?: string | null
        }
        Relationships: []
      }
      business_activity_log: {
        Row: {
          business_id: string
          created_at: string
          id: string
          meta: Json
          type: string
        }
        Insert: {
          business_id: string
          created_at?: string
          id?: string
          meta?: Json
          type: string
        }
        Update: {
          business_id?: string
          created_at?: string
          id?: string
          meta?: Json
          type?: string
        }
        Relationships: [
          {
            foreignKeyName: "business_activity_log_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "business_activity_log_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_activity_log_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_activity_log_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      business_amenities: {
        Row: {
          created_at: string | null
          icon: string
          id: string
          key: string
          label: string
        }
        Insert: {
          created_at?: string | null
          icon: string
          id?: string
          key: string
          label: string
        }
        Update: {
          created_at?: string | null
          icon?: string
          id?: string
          key?: string
          label?: string
        }
        Relationships: []
      }
      business_amenity_map: {
        Row: {
          amenity_id: string
          business_id: string
        }
        Insert: {
          amenity_id: string
          business_id: string
        }
        Update: {
          amenity_id?: string
          business_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "business_amenity_map_amenity_id_fkey"
            columns: ["amenity_id"]
            isOneToOne: false
            referencedRelation: "business_amenities"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_amenity_map_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "business_amenity_map_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_amenity_map_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_amenity_map_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      business_audit_log: {
        Row: {
          action: string
          actor_id: string
          actor_role: string
          business_id: string
          created_at: string
          description: string
          id: string
          meta: Json
          target_id: string | null
          target_label: string | null
          target_table: string | null
        }
        Insert: {
          action: string
          actor_id: string
          actor_role: string
          business_id: string
          created_at?: string
          description: string
          id?: string
          meta?: Json
          target_id?: string | null
          target_label?: string | null
          target_table?: string | null
        }
        Update: {
          action?: string
          actor_id?: string
          actor_role?: string
          business_id?: string
          created_at?: string
          description?: string
          id?: string
          meta?: Json
          target_id?: string | null
          target_label?: string | null
          target_table?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "business_audit_log_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "business_audit_log_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_audit_log_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_audit_log_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      business_checkins: {
        Row: {
          business_id: string
          client_id: string
          created_at: string
          id: string
          menu_id: string | null
          table_no: string | null
          user_id: string | null
        }
        Insert: {
          business_id: string
          client_id: string
          created_at?: string
          id?: string
          menu_id?: string | null
          table_no?: string | null
          user_id?: string | null
        }
        Update: {
          business_id?: string
          client_id?: string
          created_at?: string
          id?: string
          menu_id?: string | null
          table_no?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "business_checkins_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "business_checkins_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_checkins_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_checkins_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_checkins_menu_id_fkey"
            columns: ["menu_id"]
            isOneToOne: false
            referencedRelation: "menus"
            referencedColumns: ["id"]
          },
        ]
      }
      business_fee_flags: {
        Row: {
          bottled_water_paid: boolean | null
          business_id: string
          cover_charge_cents: number | null
          has_cover_charge: boolean | null
          has_service_fee: boolean | null
          service_fee_pct: number | null
          updated_at: string | null
        }
        Insert: {
          bottled_water_paid?: boolean | null
          business_id: string
          cover_charge_cents?: number | null
          has_cover_charge?: boolean | null
          has_service_fee?: boolean | null
          service_fee_pct?: number | null
          updated_at?: string | null
        }
        Update: {
          bottled_water_paid?: boolean | null
          business_id?: string
          cover_charge_cents?: number | null
          has_cover_charge?: boolean | null
          has_service_fee?: boolean | null
          service_fee_pct?: number | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "business_fee_flags_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "business_fee_flags_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_fee_flags_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_fee_flags_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      business_fee_votes: {
        Row: {
          business_id: string
          created_at: string | null
          created_day: string | null
          field: string
          id: string
          note: string | null
          user_id: string
          value: boolean
        }
        Insert: {
          business_id: string
          created_at?: string | null
          created_day?: string | null
          field: string
          id?: string
          note?: string | null
          user_id: string
          value: boolean
        }
        Update: {
          business_id?: string
          created_at?: string | null
          created_day?: string | null
          field?: string
          id?: string
          note?: string | null
          user_id?: string
          value?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "business_fee_votes_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "business_fee_votes_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_fee_votes_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_fee_votes_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      business_follows: {
        Row: {
          business_id: string
          created_at: string | null
          follower_id: string | null
          is_subscribed_email: boolean
          user_id: string
        }
        Insert: {
          business_id: string
          created_at?: string | null
          follower_id?: string | null
          is_subscribed_email?: boolean
          user_id: string
        }
        Update: {
          business_id?: string
          created_at?: string | null
          follower_id?: string | null
          is_subscribed_email?: boolean
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "business_follows_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "business_follows_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_follows_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_follows_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      business_hours: {
        Row: {
          business_id: string
          fri_close: string | null
          fri_open: string | null
          mon_close: string | null
          mon_open: string | null
          sat_close: string | null
          sat_open: string | null
          sun_close: string | null
          sun_open: string | null
          thu_close: string | null
          thu_open: string | null
          tue_close: string | null
          tue_open: string | null
          updated_at: string
          wed_close: string | null
          wed_open: string | null
        }
        Insert: {
          business_id: string
          fri_close?: string | null
          fri_open?: string | null
          mon_close?: string | null
          mon_open?: string | null
          sat_close?: string | null
          sat_open?: string | null
          sun_close?: string | null
          sun_open?: string | null
          thu_close?: string | null
          thu_open?: string | null
          tue_close?: string | null
          tue_open?: string | null
          updated_at?: string
          wed_close?: string | null
          wed_open?: string | null
        }
        Update: {
          business_id?: string
          fri_close?: string | null
          fri_open?: string | null
          mon_close?: string | null
          mon_open?: string | null
          sat_close?: string | null
          sat_open?: string | null
          sun_close?: string | null
          sun_open?: string | null
          thu_close?: string | null
          thu_open?: string | null
          tue_close?: string | null
          tue_open?: string | null
          updated_at?: string
          wed_close?: string | null
          wed_open?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "business_hours_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "business_hours_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_hours_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_hours_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      business_meal_card_providers: {
        Row: {
          business_id: string
          created_at: string
          id: string
          provider_id: string
        }
        Insert: {
          business_id: string
          created_at?: string
          id?: string
          provider_id: string
        }
        Update: {
          business_id?: string
          created_at?: string
          id?: string
          provider_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "business_meal_card_providers_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "business_meal_card_providers_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_meal_card_providers_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_meal_card_providers_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_meal_card_providers_provider_id_fkey"
            columns: ["provider_id"]
            isOneToOne: false
            referencedRelation: "meal_card_providers"
            referencedColumns: ["id"]
          },
        ]
      }
      business_media: {
        Row: {
          business_id: string
          created_at: string
          created_by: string | null
          height: number | null
          id: string
          is_hidden: boolean
          is_shadow: boolean
          kind: string
          moderation_note: string | null
          provider: string
          status: string
          url: string
          url_large: string | null
          url_thumb: string | null
          width: number | null
        }
        Insert: {
          business_id: string
          created_at?: string
          created_by?: string | null
          height?: number | null
          id?: string
          is_hidden?: boolean
          is_shadow?: boolean
          kind?: string
          moderation_note?: string | null
          provider?: string
          status?: string
          url: string
          url_large?: string | null
          url_thumb?: string | null
          width?: number | null
        }
        Update: {
          business_id?: string
          created_at?: string
          created_by?: string | null
          height?: number | null
          id?: string
          is_hidden?: boolean
          is_shadow?: boolean
          kind?: string
          moderation_note?: string | null
          provider?: string
          status?: string
          url?: string
          url_large?: string | null
          url_thumb?: string | null
          width?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "business_media_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "business_media_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_media_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_media_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      business_menu_presentation_settings: {
        Row: {
          background_url: string | null
          business_id: string
          cover_url: string | null
          created_at: string
          default_lang: string
          logo_url: string | null
          settings: Json
          template_key: string
          updated_at: string
        }
        Insert: {
          background_url?: string | null
          business_id: string
          cover_url?: string | null
          created_at?: string
          default_lang?: string
          logo_url?: string | null
          settings?: Json
          template_key?: string
          updated_at?: string
        }
        Update: {
          background_url?: string | null
          business_id?: string
          cover_url?: string | null
          created_at?: string
          default_lang?: string
          logo_url?: string | null
          settings?: Json
          template_key?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "business_menu_presentation_settings_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "business_menu_presentation_settings_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_menu_presentation_settings_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_menu_presentation_settings_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      business_merge_log: {
        Row: {
          duplicate_business_id: string
          merged_at: string
          merged_by: string | null
          note: string | null
          primary_business_id: string
        }
        Insert: {
          duplicate_business_id: string
          merged_at?: string
          merged_by?: string | null
          note?: string | null
          primary_business_id: string
        }
        Update: {
          duplicate_business_id?: string
          merged_at?: string
          merged_by?: string | null
          note?: string | null
          primary_business_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "business_merge_log_duplicate_business_id_fkey"
            columns: ["duplicate_business_id"]
            isOneToOne: true
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "business_merge_log_duplicate_business_id_fkey"
            columns: ["duplicate_business_id"]
            isOneToOne: true
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_merge_log_duplicate_business_id_fkey"
            columns: ["duplicate_business_id"]
            isOneToOne: true
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_merge_log_duplicate_business_id_fkey"
            columns: ["duplicate_business_id"]
            isOneToOne: true
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_merge_log_primary_business_id_fkey"
            columns: ["primary_business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "business_merge_log_primary_business_id_fkey"
            columns: ["primary_business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_merge_log_primary_business_id_fkey"
            columns: ["primary_business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_merge_log_primary_business_id_fkey"
            columns: ["primary_business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      business_perks: {
        Row: {
          business_id: string
          created_at: string
          created_by: string | null
          description: string | null
          ends_at: string | null
          id: string
          requires_checkin: boolean
          starts_at: string | null
          status: string
          title: string
        }
        Insert: {
          business_id: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          ends_at?: string | null
          id?: string
          requires_checkin?: boolean
          starts_at?: string | null
          status?: string
          title: string
        }
        Update: {
          business_id?: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          ends_at?: string | null
          id?: string
          requires_checkin?: boolean
          starts_at?: string | null
          status?: string
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "business_perks_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "business_perks_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_perks_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_perks_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      business_policy_acceptances: {
        Row: {
          accepted_at: string
          business_id: string
          created_at: string
          id: string
          ip_address: unknown
          policy_version_id: string
          user_agent: string | null
          user_id: string
        }
        Insert: {
          accepted_at?: string
          business_id: string
          created_at?: string
          id?: string
          ip_address?: unknown
          policy_version_id: string
          user_agent?: string | null
          user_id: string
        }
        Update: {
          accepted_at?: string
          business_id?: string
          created_at?: string
          id?: string
          ip_address?: unknown
          policy_version_id?: string
          user_agent?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "business_policy_acceptances_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "business_policy_acceptances_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_policy_acceptances_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_policy_acceptances_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_policy_acceptances_policy_version_id_fkey"
            columns: ["policy_version_id"]
            isOneToOne: false
            referencedRelation: "policy_versions"
            referencedColumns: ["id"]
          },
        ]
      }
      business_premium: {
        Row: {
          business_id: string
          created_at: string
          created_by: string | null
          ends_at: string | null
          id: string
          source: string
          starts_at: string
          status: string
          tier: string
        }
        Insert: {
          business_id: string
          created_at?: string
          created_by?: string | null
          ends_at?: string | null
          id?: string
          source?: string
          starts_at?: string
          status?: string
          tier: string
        }
        Update: {
          business_id?: string
          created_at?: string
          created_by?: string | null
          ends_at?: string | null
          id?: string
          source?: string
          starts_at?: string
          status?: string
          tier?: string
        }
        Relationships: [
          {
            foreignKeyName: "business_premium_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "business_premium_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_premium_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_premium_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_premium_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["user_id"]
          },
        ]
      }
      business_presence_events: {
        Row: {
          business_id: string
          created_at: string
          crowd: Database["public"]["Enums"]["crowd_level"]
          id: string
          user_id: string
        }
        Insert: {
          business_id: string
          created_at?: string
          crowd: Database["public"]["Enums"]["crowd_level"]
          id?: string
          user_id: string
        }
        Update: {
          business_id?: string
          created_at?: string
          crowd?: Database["public"]["Enums"]["crowd_level"]
          id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "business_presence_events_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "business_presence_events_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_presence_events_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_presence_events_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      business_pricing_rules: {
        Row: {
          business_id: string
          cover_charge_cents: number | null
          default_tip_pct: number | null
          service_fee_pct: number | null
          vat_included: boolean
        }
        Insert: {
          business_id: string
          cover_charge_cents?: number | null
          default_tip_pct?: number | null
          service_fee_pct?: number | null
          vat_included?: boolean
        }
        Update: {
          business_id?: string
          cover_charge_cents?: number | null
          default_tip_pct?: number | null
          service_fee_pct?: number | null
          vat_included?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "business_pricing_rules_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "business_pricing_rules_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_pricing_rules_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_pricing_rules_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      business_qr_codes: {
        Row: {
          business_id: string
          created_at: string
          created_by: string | null
          description: string | null
          id: string
          is_active: boolean
          language: string
          name: string
          scan_count: number
          target_url: string | null
          type: string
          updated_at: string
        }
        Insert: {
          business_id: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          is_active?: boolean
          language?: string
          name: string
          scan_count?: number
          target_url?: string | null
          type?: string
          updated_at?: string
        }
        Update: {
          business_id?: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          is_active?: boolean
          language?: string
          name?: string
          scan_count?: number
          target_url?: string | null
          type?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "business_qr_codes_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "business_qr_codes_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_qr_codes_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_qr_codes_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      business_social_links: {
        Row: {
          business_id: string
          facebook: string | null
          instagram: string | null
          tiktok: string | null
          updated_at: string | null
          website: string | null
          whatsapp: string | null
        }
        Insert: {
          business_id: string
          facebook?: string | null
          instagram?: string | null
          tiktok?: string | null
          updated_at?: string | null
          website?: string | null
          whatsapp?: string | null
        }
        Update: {
          business_id?: string
          facebook?: string | null
          instagram?: string | null
          tiktok?: string | null
          updated_at?: string | null
          website?: string | null
          whatsapp?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "business_social_links_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "business_social_links_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_social_links_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_social_links_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      business_special_hours: {
        Row: {
          business_id: string
          close_time: string | null
          created_at: string
          id: string
          is_closed: boolean
          note: string | null
          open_time: string | null
          special_date: string
        }
        Insert: {
          business_id: string
          close_time?: string | null
          created_at?: string
          id?: string
          is_closed?: boolean
          note?: string | null
          open_time?: string | null
          special_date: string
        }
        Update: {
          business_id?: string
          close_time?: string | null
          created_at?: string
          id?: string
          is_closed?: boolean
          note?: string | null
          open_time?: string | null
          special_date?: string
        }
        Relationships: [
          {
            foreignKeyName: "business_special_hours_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "business_special_hours_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_special_hours_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_special_hours_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      business_stats: {
        Row: {
          approved_rating_sum: number
          approved_reviews_count: number
          business_id: string
          last_review_at: string | null
          rating_1: number
          rating_2: number
          rating_3: number
          rating_4: number
          rating_5: number
          updated_at: string
        }
        Insert: {
          approved_rating_sum?: number
          approved_reviews_count?: number
          business_id: string
          last_review_at?: string | null
          rating_1?: number
          rating_2?: number
          rating_3?: number
          rating_4?: number
          rating_5?: number
          updated_at?: string
        }
        Update: {
          approved_rating_sum?: number
          approved_reviews_count?: number
          business_id?: string
          last_review_at?: string | null
          rating_1?: number
          rating_2?: number
          rating_3?: number
          rating_4?: number
          rating_5?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "business_stats_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "business_stats_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_stats_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_stats_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      business_stories: {
        Row: {
          business_id: string
          caption: string | null
          category: string | null
          created_at: string
          created_by: string
          discount_percent: number | null
          duration_sec: number | null
          expires_at: string
          id: string
          is_deleted: boolean
          is_featured: boolean
          media_thumb_url: string | null
          media_type: string
          media_url: string
          type: Database["public"]["Enums"]["story_type"]
          view_count: number
        }
        Insert: {
          business_id: string
          caption?: string | null
          category?: string | null
          created_at?: string
          created_by: string
          discount_percent?: number | null
          duration_sec?: number | null
          expires_at?: string
          id?: string
          is_deleted?: boolean
          is_featured?: boolean
          media_thumb_url?: string | null
          media_type?: string
          media_url: string
          type?: Database["public"]["Enums"]["story_type"]
          view_count?: number
        }
        Update: {
          business_id?: string
          caption?: string | null
          category?: string | null
          created_at?: string
          created_by?: string
          discount_percent?: number | null
          duration_sec?: number | null
          expires_at?: string
          id?: string
          is_deleted?: boolean
          is_featured?: boolean
          media_thumb_url?: string | null
          media_type?: string
          media_url?: string
          type?: Database["public"]["Enums"]["story_type"]
          view_count?: number
        }
        Relationships: [
          {
            foreignKeyName: "business_stories_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "business_stories_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_stories_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_stories_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      business_submissions: {
        Row: {
          address: string
          admin_note: string | null
          assigned_at: string | null
          assigned_to: string | null
          category: string
          city: string
          created_at: string
          district: string
          id: string
          name: string
          phone: string | null
          status: string
          submitted_by: string
          website: string | null
        }
        Insert: {
          address: string
          admin_note?: string | null
          assigned_at?: string | null
          assigned_to?: string | null
          category: string
          city: string
          created_at?: string
          district: string
          id?: string
          name: string
          phone?: string | null
          status?: string
          submitted_by: string
          website?: string | null
        }
        Update: {
          address?: string
          admin_note?: string | null
          assigned_at?: string | null
          assigned_to?: string | null
          category?: string
          city?: string
          created_at?: string
          district?: string
          id?: string
          name?: string
          phone?: string | null
          status?: string
          submitted_by?: string
          website?: string | null
        }
        Relationships: []
      }
      business_suggestions: {
        Row: {
          address: string | null
          admin_note: string | null
          approved_business_id: string | null
          assigned_at: string | null
          assigned_to: string | null
          category: string
          city: string | null
          created_at: string
          district: string | null
          handled_at: string | null
          handled_by: string | null
          id: string
          name: string
          notes: string | null
          phone: string | null
          reviewed_at: string | null
          status: string
          user_id: string | null
          website: string | null
        }
        Insert: {
          address?: string | null
          admin_note?: string | null
          approved_business_id?: string | null
          assigned_at?: string | null
          assigned_to?: string | null
          category: string
          city?: string | null
          created_at?: string
          district?: string | null
          handled_at?: string | null
          handled_by?: string | null
          id?: string
          name: string
          notes?: string | null
          phone?: string | null
          reviewed_at?: string | null
          status?: string
          user_id?: string | null
          website?: string | null
        }
        Update: {
          address?: string | null
          admin_note?: string | null
          approved_business_id?: string | null
          assigned_at?: string | null
          assigned_to?: string | null
          category?: string
          city?: string | null
          created_at?: string
          district?: string | null
          handled_at?: string | null
          handled_by?: string | null
          id?: string
          name?: string
          notes?: string | null
          phone?: string | null
          reviewed_at?: string | null
          status?: string
          user_id?: string | null
          website?: string | null
        }
        Relationships: []
      }
      business_team_memberships: {
        Row: {
          accepted_at: string | null
          business_id: string | null
          chain_id: string | null
          created_at: string
          created_by: string | null
          id: string
          invite_email: string | null
          revoked_at: string | null
          role: string
          updated_at: string
          user_id: string | null
        }
        Insert: {
          accepted_at?: string | null
          business_id?: string | null
          chain_id?: string | null
          created_at?: string
          created_by?: string | null
          id?: string
          invite_email?: string | null
          revoked_at?: string | null
          role: string
          updated_at?: string
          user_id?: string | null
        }
        Update: {
          accepted_at?: string | null
          business_id?: string | null
          chain_id?: string | null
          created_at?: string
          created_by?: string | null
          id?: string
          invite_email?: string | null
          revoked_at?: string | null
          role?: string
          updated_at?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "business_team_memberships_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "business_team_memberships_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_team_memberships_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_team_memberships_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_team_memberships_chain_id_fkey"
            columns: ["chain_id"]
            isOneToOne: false
            referencedRelation: "chains"
            referencedColumns: ["id"]
          },
        ]
      }
      business_weekly_hours: {
        Row: {
          business_id: string
          close_time: string
          created_at: string
          day_of_week: number
          id: string
          is_closed: boolean
          open_time: string
          updated_at: string
        }
        Insert: {
          business_id: string
          close_time?: string
          created_at?: string
          day_of_week: number
          id?: string
          is_closed?: boolean
          open_time?: string
          updated_at?: string
        }
        Update: {
          business_id?: string
          close_time?: string
          created_at?: string
          day_of_week?: number
          id?: string
          is_closed?: boolean
          open_time?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "business_weekly_hours_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "business_weekly_hours_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_weekly_hours_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "business_weekly_hours_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      businesses: {
        Row: {
          accepts_reservations: boolean
          address: string | null
          boundary_checked: boolean
          branch_label: string | null
          category: string
          chain_id: string | null
          chain_sort_order: number | null
          city: string | null
          city_norm: string | null
          cover_provider: string | null
          cover_url: string | null
          created_at: string
          description: string | null
          district: string | null
          district_norm: string | null
          email: string | null
          facebook_url: string | null
          fingerprint: string | null
          geog: unknown
          id: string
          instagram_url: string | null
          is_active: boolean
          is_verified: boolean
          lat: number | null
          lng: number | null
          logo_provider: string | null
          logo_url: string | null
          name: string
          neighborhood: string | null
          order_getir_url: string | null
          order_trendyolgo_url: string | null
          order_yemeksepeti_url: string | null
          osm_boundary_id: string | null
          phone: string | null
          price_level: string | null
          public_slug: string | null
          reservation_advance_hours: number
          reservation_max_party: number
          reservation_min_party: number
          reservation_note: string | null
          reservation_phone: string | null
          reservation_url: string | null
          reservation_window_days: number
          search_tsv: unknown
          slug: string | null
          source: string | null
          source_id: string | null
          twitter_url: string | null
          verified_at: string | null
          verified_by: string | null
          website_url: string | null
        }
        Insert: {
          accepts_reservations?: boolean
          address?: string | null
          boundary_checked?: boolean
          branch_label?: string | null
          category: string
          chain_id?: string | null
          chain_sort_order?: number | null
          city?: string | null
          city_norm?: string | null
          cover_provider?: string | null
          cover_url?: string | null
          created_at?: string
          description?: string | null
          district?: string | null
          district_norm?: string | null
          email?: string | null
          facebook_url?: string | null
          fingerprint?: string | null
          geog?: unknown
          id?: string
          instagram_url?: string | null
          is_active?: boolean
          is_verified?: boolean
          lat?: number | null
          lng?: number | null
          logo_provider?: string | null
          logo_url?: string | null
          name: string
          neighborhood?: string | null
          order_getir_url?: string | null
          order_trendyolgo_url?: string | null
          order_yemeksepeti_url?: string | null
          osm_boundary_id?: string | null
          phone?: string | null
          price_level?: string | null
          public_slug?: string | null
          reservation_advance_hours?: number
          reservation_max_party?: number
          reservation_min_party?: number
          reservation_note?: string | null
          reservation_phone?: string | null
          reservation_url?: string | null
          reservation_window_days?: number
          search_tsv?: unknown
          slug?: string | null
          source?: string | null
          source_id?: string | null
          twitter_url?: string | null
          verified_at?: string | null
          verified_by?: string | null
          website_url?: string | null
        }
        Update: {
          accepts_reservations?: boolean
          address?: string | null
          boundary_checked?: boolean
          branch_label?: string | null
          category?: string
          chain_id?: string | null
          chain_sort_order?: number | null
          city?: string | null
          city_norm?: string | null
          cover_provider?: string | null
          cover_url?: string | null
          created_at?: string
          description?: string | null
          district?: string | null
          district_norm?: string | null
          email?: string | null
          facebook_url?: string | null
          fingerprint?: string | null
          geog?: unknown
          id?: string
          instagram_url?: string | null
          is_active?: boolean
          is_verified?: boolean
          lat?: number | null
          lng?: number | null
          logo_provider?: string | null
          logo_url?: string | null
          name?: string
          neighborhood?: string | null
          order_getir_url?: string | null
          order_trendyolgo_url?: string | null
          order_yemeksepeti_url?: string | null
          osm_boundary_id?: string | null
          phone?: string | null
          price_level?: string | null
          public_slug?: string | null
          reservation_advance_hours?: number
          reservation_max_party?: number
          reservation_min_party?: number
          reservation_note?: string | null
          reservation_phone?: string | null
          reservation_url?: string | null
          reservation_window_days?: number
          search_tsv?: unknown
          slug?: string | null
          source?: string | null
          source_id?: string | null
          twitter_url?: string | null
          verified_at?: string | null
          verified_by?: string | null
          website_url?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "businesses_chain_id_fkey"
            columns: ["chain_id"]
            isOneToOne: false
            referencedRelation: "chains"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "businesses_osm_boundary_id_fkey"
            columns: ["osm_boundary_id"]
            isOneToOne: false
            referencedRelation: "osm_admin_boundaries"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "businesses_verified_by_fkey"
            columns: ["verified_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["user_id"]
          },
        ]
      }
      campaigns: {
        Row: {
          business_id: string
          click_count: number
          created_at: string
          created_by: string | null
          description: string | null
          discount_percent: number | null
          ends_at: string | null
          id: string
          image_url: string | null
          starts_at: string | null
          status: string
          title: string
          type: string
          updated_at: string
          view_count: number
        }
        Insert: {
          business_id: string
          click_count?: number
          created_at?: string
          created_by?: string | null
          description?: string | null
          discount_percent?: number | null
          ends_at?: string | null
          id?: string
          image_url?: string | null
          starts_at?: string | null
          status?: string
          title: string
          type?: string
          updated_at?: string
          view_count?: number
        }
        Update: {
          business_id?: string
          click_count?: number
          created_at?: string
          created_by?: string | null
          description?: string | null
          discount_percent?: number | null
          ends_at?: string | null
          id?: string
          image_url?: string | null
          starts_at?: string | null
          status?: string
          title?: string
          type?: string
          updated_at?: string
          view_count?: number
        }
        Relationships: [
          {
            foreignKeyName: "campaigns_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "campaigns_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "campaigns_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "campaigns_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      chain_item_overrides: {
        Row: {
          business_id: string
          created_at: string
          created_by: string | null
          currency: string
          id: string
          menu_item_id: string
          note: string | null
          price_cents: number
          updated_at: string
        }
        Insert: {
          business_id: string
          created_at?: string
          created_by?: string | null
          currency?: string
          id?: string
          menu_item_id: string
          note?: string | null
          price_cents: number
          updated_at?: string
        }
        Update: {
          business_id?: string
          created_at?: string
          created_by?: string | null
          currency?: string
          id?: string
          menu_item_id?: string
          note?: string | null
          price_cents?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "chain_item_overrides_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "chain_item_overrides_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chain_item_overrides_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chain_item_overrides_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chain_item_overrides_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "business_item_trends_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "chain_item_overrides_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_item_price_status_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "chain_item_overrides_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_item_value_score_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "chain_item_overrides_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_items"
            referencedColumns: ["id"]
          },
        ]
      }
      chain_memberships: {
        Row: {
          chain_id: string
          created_at: string
          role: string
          user_id: string
        }
        Insert: {
          chain_id: string
          created_at?: string
          role?: string
          user_id: string
        }
        Update: {
          chain_id?: string
          created_at?: string
          role?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "chain_memberships_chain_id_fkey"
            columns: ["chain_id"]
            isOneToOne: false
            referencedRelation: "chains"
            referencedColumns: ["id"]
          },
        ]
      }
      chains: {
        Row: {
          category: string | null
          cover_url: string | null
          created_at: string
          description: string | null
          id: string
          is_verified: boolean
          logo_url: string | null
          name: string
          slug: string | null
          template_business_id: string | null
          website: string | null
        }
        Insert: {
          category?: string | null
          cover_url?: string | null
          created_at?: string
          description?: string | null
          id?: string
          is_verified?: boolean
          logo_url?: string | null
          name: string
          slug?: string | null
          template_business_id?: string | null
          website?: string | null
        }
        Update: {
          category?: string | null
          cover_url?: string | null
          created_at?: string
          description?: string | null
          id?: string
          is_verified?: boolean
          logo_url?: string | null
          name?: string
          slug?: string | null
          template_business_id?: string | null
          website?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "chains_template_business_id_fkey"
            columns: ["template_business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "chains_template_business_id_fkey"
            columns: ["template_business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chains_template_business_id_fkey"
            columns: ["template_business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "chains_template_business_id_fkey"
            columns: ["template_business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      city_search_aliases: {
        Row: {
          alias: string
          canonical_city: string
          canonical_district: string | null
          created_at: string
        }
        Insert: {
          alias: string
          canonical_city: string
          canonical_district?: string | null
          created_at?: string
        }
        Update: {
          alias?: string
          canonical_city?: string
          canonical_district?: string | null
          created_at?: string
        }
        Relationships: []
      }
      client_mutation_idempotency_keys: {
        Row: {
          action: string
          created_at: string
          idempotency_key: string
          resource_id: string | null
          resource_type: string | null
          response: Json
          user_id: string
        }
        Insert: {
          action: string
          created_at?: string
          idempotency_key: string
          resource_id?: string | null
          resource_type?: string | null
          response: Json
          user_id: string
        }
        Update: {
          action?: string
          created_at?: string
          idempotency_key?: string
          resource_id?: string | null
          resource_type?: string | null
          response?: Json
          user_id?: string
        }
        Relationships: []
      }
      collab_list_items: {
        Row: {
          added_by: string
          business_id: string
          created_at: string
          id: string
          list_id: string
          note: string | null
        }
        Insert: {
          added_by: string
          business_id: string
          created_at?: string
          id?: string
          list_id: string
          note?: string | null
        }
        Update: {
          added_by?: string
          business_id?: string
          created_at?: string
          id?: string
          list_id?: string
          note?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "collab_list_items_list_id_fkey"
            columns: ["list_id"]
            isOneToOne: false
            referencedRelation: "collab_lists"
            referencedColumns: ["id"]
          },
        ]
      }
      collab_list_members: {
        Row: {
          id: string
          joined_at: string
          list_id: string
          user_id: string
        }
        Insert: {
          id?: string
          joined_at?: string
          list_id: string
          user_id: string
        }
        Update: {
          id?: string
          joined_at?: string
          list_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "collab_list_members_list_id_fkey"
            columns: ["list_id"]
            isOneToOne: false
            referencedRelation: "collab_lists"
            referencedColumns: ["id"]
          },
        ]
      }
      collab_list_votes: {
        Row: {
          id: string
          item_id: string
          list_id: string
          user_id: string
          vote: number
          voted_at: string
          voter_ip: string | null
        }
        Insert: {
          id?: string
          item_id: string
          list_id: string
          user_id: string
          vote: number
          voted_at?: string
          voter_ip?: string | null
        }
        Update: {
          id?: string
          item_id?: string
          list_id?: string
          user_id?: string
          vote?: number
          voted_at?: string
          voter_ip?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "collab_list_votes_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: false
            referencedRelation: "collab_list_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "collab_list_votes_list_id_fkey"
            columns: ["list_id"]
            isOneToOne: false
            referencedRelation: "collab_lists"
            referencedColumns: ["id"]
          },
        ]
      }
      collab_lists: {
        Row: {
          created_at: string
          description: string | null
          id: string
          invite_token: string
          name: string
          owner_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          invite_token?: string
          name: string
          owner_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          invite_token?: string
          name?: string
          owner_id?: string
          updated_at?: string
        }
        Relationships: []
      }
      collection_items: {
        Row: {
          business_id: string
          collection_id: string
          created_at: string
          note: string | null
        }
        Insert: {
          business_id: string
          collection_id: string
          created_at?: string
          note?: string | null
        }
        Update: {
          business_id?: string
          collection_id?: string
          created_at?: string
          note?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "collection_items_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "collection_items_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "collection_items_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "collection_items_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "collection_items_collection_id_fkey"
            columns: ["collection_id"]
            isOneToOne: false
            referencedRelation: "collections"
            referencedColumns: ["id"]
          },
        ]
      }
      collection_shares: {
        Row: {
          business_ids: string[]
          collection_key: string
          created_at: string
          created_by: string | null
          name: string
          slug: string
        }
        Insert: {
          business_ids: string[]
          collection_key: string
          created_at?: string
          created_by?: string | null
          name: string
          slug: string
        }
        Update: {
          business_ids?: string[]
          collection_key?: string
          created_at?: string
          created_by?: string | null
          name?: string
          slug?: string
        }
        Relationships: []
      }
      collection_social_stats: {
        Row: {
          collection_key: string
          engagement_count: number
          followers_count: number
          updated_at: string
        }
        Insert: {
          collection_key: string
          engagement_count?: number
          followers_count?: number
          updated_at?: string
        }
        Update: {
          collection_key?: string
          engagement_count?: number
          followers_count?: number
          updated_at?: string
        }
        Relationships: []
      }
      collections: {
        Row: {
          created_at: string
          id: string
          is_public: boolean
          title: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          is_public?: boolean
          title: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          is_public?: boolean
          title?: string
          user_id?: string
        }
        Relationships: []
      }
      custom_domains: {
        Row: {
          business_id: string
          created_at: string
          dns_txt_token: string
          domain: string
          id: string
          is_active: boolean
          updated_at: string
          verified_at: string | null
        }
        Insert: {
          business_id: string
          created_at?: string
          dns_txt_token: string
          domain: string
          id?: string
          is_active?: boolean
          updated_at?: string
          verified_at?: string | null
        }
        Update: {
          business_id?: string
          created_at?: string
          dns_txt_token?: string
          domain?: string
          id?: string
          is_active?: boolean
          updated_at?: string
          verified_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "custom_domains_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "custom_domains_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "custom_domains_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "custom_domains_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      customer_notes: {
        Row: {
          business_id: string
          created_at: string
          created_by: string | null
          id: string
          note: string
          user_id: string
        }
        Insert: {
          business_id: string
          created_at?: string
          created_by?: string | null
          id?: string
          note: string
          user_id: string
        }
        Update: {
          business_id?: string
          created_at?: string
          created_by?: string | null
          id?: string
          note?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "customer_notes_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "customer_notes_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "customer_notes_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "customer_notes_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      customer_tags: {
        Row: {
          business_id: string
          created_at: string
          created_by: string | null
          id: string
          tag: string
          user_id: string
        }
        Insert: {
          business_id: string
          created_at?: string
          created_by?: string | null
          id?: string
          tag: string
          user_id: string
        }
        Update: {
          business_id?: string
          created_at?: string
          created_by?: string | null
          id?: string
          tag?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "customer_tags_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "customer_tags_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "customer_tags_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "customer_tags_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      edge_ip_denylist: {
        Row: {
          created_at: string
          created_by: string | null
          expires_at: string | null
          id: string
          ip_hash: string
          is_active: boolean
          reason: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          expires_at?: string | null
          id?: string
          ip_hash: string
          is_active?: boolean
          reason?: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          expires_at?: string | null
          id?: string
          ip_hash?: string
          is_active?: boolean
          reason?: string
        }
        Relationships: []
      }
      edge_rate_limit_events: {
        Row: {
          action: string
          created_at: string
          id: number
          ip_hash: string
          scope: string | null
          user_id: string | null
        }
        Insert: {
          action: string
          created_at?: string
          id?: number
          ip_hash: string
          scope?: string | null
          user_id?: string | null
        }
        Update: {
          action?: string
          created_at?: string
          id?: number
          ip_hash?: string
          scope?: string | null
          user_id?: string | null
        }
        Relationships: []
      }
      email_campaigns: {
        Row: {
          business_id: string
          campaign_id: string | null
          created_at: string
          html_body: string
          id: string
          opened_count: number
          scheduled_at: string | null
          sent_at: string | null
          sent_count: number
          subject: string
          target_segment: string
        }
        Insert: {
          business_id: string
          campaign_id?: string | null
          created_at?: string
          html_body: string
          id?: string
          opened_count?: number
          scheduled_at?: string | null
          sent_at?: string | null
          sent_count?: number
          subject: string
          target_segment?: string
        }
        Update: {
          business_id?: string
          campaign_id?: string | null
          created_at?: string
          html_body?: string
          id?: string
          opened_count?: number
          scheduled_at?: string | null
          sent_at?: string | null
          sent_count?: number
          subject?: string
          target_segment?: string
        }
        Relationships: [
          {
            foreignKeyName: "email_campaigns_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "email_campaigns_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "email_campaigns_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "email_campaigns_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "email_campaigns_campaign_id_fkey"
            columns: ["campaign_id"]
            isOneToOne: false
            referencedRelation: "campaigns"
            referencedColumns: ["id"]
          },
        ]
      }
      embeds: {
        Row: {
          created_at: string
          created_by: string | null
          id: string
          owner_id: string
          owner_type: string
          provider: string
          thumbnail_url: string | null
          title: string | null
          url_normalized: string
          url_raw: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          id?: string
          owner_id: string
          owner_type: string
          provider: string
          thumbnail_url?: string | null
          title?: string | null
          url_normalized: string
          url_raw: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          id?: string
          owner_id?: string
          owner_type?: string
          provider?: string
          thumbnail_url?: string | null
          title?: string | null
          url_normalized?: string
          url_raw?: string
        }
        Relationships: []
      }
      exchange_rates: {
        Row: {
          currency: string
          fetched_at: string
          source: string
          try_rate: number
        }
        Insert: {
          currency: string
          fetched_at?: string
          source?: string
          try_rate: number
        }
        Update: {
          currency?: string
          fetched_at?: string
          source?: string
          try_rate?: number
        }
        Relationships: []
      }
      favorite_revisit_reminders_sent: {
        Row: {
          business_id: string
          id: string
          sent_at: string
          user_id: string
        }
        Insert: {
          business_id: string
          id?: string
          sent_at?: string
          user_id: string
        }
        Update: {
          business_id?: string
          id?: string
          sent_at?: string
          user_id?: string
        }
        Relationships: []
      }
      favorites: {
        Row: {
          business_id: string
          created_at: string
          email_optin: boolean
          id: string
          user_id: string
        }
        Insert: {
          business_id: string
          created_at?: string
          email_optin?: boolean
          id?: string
          user_id: string
        }
        Update: {
          business_id?: string
          created_at?: string
          email_optin?: boolean
          id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "favorites_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "favorites_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "favorites_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "favorites_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      feed_events: {
        Row: {
          business_id: string | null
          created_at: string | null
          id: string
          meta: Json | null
          ref_id: string | null
          type: string
        }
        Insert: {
          business_id?: string | null
          created_at?: string | null
          id?: string
          meta?: Json | null
          ref_id?: string | null
          type: string
        }
        Update: {
          business_id?: string | null
          created_at?: string | null
          id?: string
          meta?: Json | null
          ref_id?: string | null
          type?: string
        }
        Relationships: [
          {
            foreignKeyName: "feed_events_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "feed_events_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "feed_events_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "feed_events_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      food_catalog_categories: {
        Row: {
          id: string
          name: string
          sort_order: number
        }
        Insert: {
          id: string
          name: string
          sort_order?: number
        }
        Update: {
          id?: string
          name?: string
          sort_order?: number
        }
        Relationships: []
      }
      food_catalog_items: {
        Row: {
          category_id: string
          id: number
          name: string
          name_norm: string
          popularity: number
          slug: string
        }
        Insert: {
          category_id: string
          id?: number
          name: string
          name_norm: string
          popularity?: number
          slug: string
        }
        Update: {
          category_id?: string
          id?: number
          name?: string
          name_norm?: string
          popularity?: number
          slug?: string
        }
        Relationships: [
          {
            foreignKeyName: "food_catalog_items_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "food_catalog_categories"
            referencedColumns: ["id"]
          },
        ]
      }
      group_offer_votes: {
        Row: {
          created_at: string
          offer_id: string
          user_id: string
          vote: number
        }
        Insert: {
          created_at?: string
          offer_id: string
          user_id: string
          vote?: number
        }
        Update: {
          created_at?: string
          offer_id?: string
          user_id?: string
          vote?: number
        }
        Relationships: [
          {
            foreignKeyName: "group_offer_votes_offer_id_fkey"
            columns: ["offer_id"]
            isOneToOne: false
            referencedRelation: "group_offers"
            referencedColumns: ["id"]
          },
        ]
      }
      group_offers: {
        Row: {
          business_id: string
          created_at: string
          created_by: string
          id: string
          includes: Json
          message: string | null
          offered_total_cents: number
          request_id: string
          status: string
        }
        Insert: {
          business_id: string
          created_at?: string
          created_by: string
          id?: string
          includes?: Json
          message?: string | null
          offered_total_cents: number
          request_id: string
          status?: string
        }
        Update: {
          business_id?: string
          created_at?: string
          created_by?: string
          id?: string
          includes?: Json
          message?: string | null
          offered_total_cents?: number
          request_id?: string
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "group_offers_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "group_offers_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "group_offers_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "group_offers_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "group_offers_request_id_fkey"
            columns: ["request_id"]
            isOneToOne: false
            referencedRelation: "group_requests"
            referencedColumns: ["id"]
          },
        ]
      }
      group_requests: {
        Row: {
          budget_total_cents: number
          category: string | null
          city: string
          created_at: string
          created_by: string
          currency: string
          date_time: string
          districts: string[] | null
          id: string
          notes: string | null
          party_size: number
          status: string
        }
        Insert: {
          budget_total_cents: number
          category?: string | null
          city: string
          created_at?: string
          created_by: string
          currency?: string
          date_time: string
          districts?: string[] | null
          id?: string
          notes?: string | null
          party_size: number
          status?: string
        }
        Update: {
          budget_total_cents?: number
          category?: string | null
          city?: string
          created_at?: string
          created_by?: string
          currency?: string
          date_time?: string
          districts?: string[] | null
          id?: string
          notes?: string | null
          party_size?: number
          status?: string
        }
        Relationships: []
      }
      import_places_stage: {
        Row: {
          address: string | null
          category: string | null
          city: string | null
          created_at: string
          district: string | null
          fingerprint: string | null
          lat: number | null
          lng: number | null
          name: string | null
          phone: string | null
          raw: Json | null
          source: string
          source_id: string
        }
        Insert: {
          address?: string | null
          category?: string | null
          city?: string | null
          created_at?: string
          district?: string | null
          fingerprint?: string | null
          lat?: number | null
          lng?: number | null
          name?: string | null
          phone?: string | null
          raw?: Json | null
          source: string
          source_id: string
        }
        Update: {
          address?: string | null
          category?: string | null
          city?: string | null
          created_at?: string
          district?: string | null
          fingerprint?: string | null
          lat?: number | null
          lng?: number | null
          name?: string | null
          phone?: string | null
          raw?: Json | null
          source?: string
          source_id?: string
        }
        Relationships: []
      }
      incident_updates: {
        Row: {
          action_taken: string
          created_at: string
          created_by: string | null
          id: string
          incident_key: string
          status: string
          summary: string
          title: string
          visibility: string
        }
        Insert: {
          action_taken: string
          created_at?: string
          created_by?: string | null
          id?: string
          incident_key: string
          status?: string
          summary: string
          title: string
          visibility?: string
        }
        Update: {
          action_taken?: string
          created_at?: string
          created_by?: string | null
          id?: string
          incident_key?: string
          status?: string
          summary?: string
          title?: string
          visibility?: string
        }
        Relationships: []
      }
      loyalty_events: {
        Row: {
          actor_id: string | null
          amount: number
          created_at: string
          id: string
          member_id: string
          source: string
        }
        Insert: {
          actor_id?: string | null
          amount: number
          created_at?: string
          id?: string
          member_id: string
          source: string
        }
        Update: {
          actor_id?: string | null
          amount?: number
          created_at?: string
          id?: string
          member_id?: string
          source?: string
        }
        Relationships: [
          {
            foreignKeyName: "loyalty_events_member_id_fkey"
            columns: ["member_id"]
            isOneToOne: false
            referencedRelation: "loyalty_members"
            referencedColumns: ["id"]
          },
        ]
      }
      loyalty_members: {
        Row: {
          id: string
          program_id: string
          progress: number
          redeemed_count: number
          updated_at: string
          user_id: string
        }
        Insert: {
          id?: string
          program_id: string
          progress?: number
          redeemed_count?: number
          updated_at?: string
          user_id: string
        }
        Update: {
          id?: string
          program_id?: string
          progress?: number
          redeemed_count?: number
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "loyalty_members_program_id_fkey"
            columns: ["program_id"]
            isOneToOne: false
            referencedRelation: "loyalty_programs"
            referencedColumns: ["id"]
          },
        ]
      }
      loyalty_programs: {
        Row: {
          business_id: string | null
          chain_id: string | null
          created_at: string
          id: string
          is_active: boolean
          mode: string
          name: string
          reward_desc: string
          reward_threshold: number
        }
        Insert: {
          business_id?: string | null
          chain_id?: string | null
          created_at?: string
          id?: string
          is_active?: boolean
          mode: string
          name: string
          reward_desc: string
          reward_threshold: number
        }
        Update: {
          business_id?: string | null
          chain_id?: string | null
          created_at?: string
          id?: string
          is_active?: boolean
          mode?: string
          name?: string
          reward_desc?: string
          reward_threshold?: number
        }
        Relationships: [
          {
            foreignKeyName: "loyalty_programs_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "loyalty_programs_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "loyalty_programs_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "loyalty_programs_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "loyalty_programs_chain_id_fkey"
            columns: ["chain_id"]
            isOneToOne: false
            referencedRelation: "chains"
            referencedColumns: ["id"]
          },
        ]
      }
      meal_card_providers: {
        Row: {
          asset_name: string
          created_at: string
          id: string
          is_active: boolean
          key: string
          name: string
          sort_order: number
        }
        Insert: {
          asset_name: string
          created_at?: string
          id?: string
          is_active?: boolean
          key: string
          name: string
          sort_order?: number
        }
        Update: {
          asset_name?: string
          created_at?: string
          id?: string
          is_active?: boolean
          key?: string
          name?: string
          sort_order?: number
        }
        Relationships: []
      }
      menu_categories: {
        Row: {
          business_id: string
          created_at: string
          id: string
          is_active: boolean
          menu_id: string | null
          sort_order: number
        }
        Insert: {
          business_id: string
          created_at?: string
          id?: string
          is_active?: boolean
          menu_id?: string | null
          sort_order?: number
        }
        Update: {
          business_id?: string
          created_at?: string
          id?: string
          is_active?: boolean
          menu_id?: string | null
          sort_order?: number
        }
        Relationships: [
          {
            foreignKeyName: "menu_categories_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "menu_categories_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_categories_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_categories_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_categories_menu_id_fkey"
            columns: ["menu_id"]
            isOneToOne: false
            referencedRelation: "menus"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_feedback: {
        Row: {
          business_id: string
          category: string
          created_at: string
          id: string
          message: string | null
          rating: number
        }
        Insert: {
          business_id: string
          category?: string
          created_at?: string
          id?: string
          message?: string | null
          rating: number
        }
        Update: {
          business_id?: string
          category?: string
          created_at?: string
          id?: string
          message?: string | null
          rating?: number
        }
        Relationships: [
          {
            foreignKeyName: "menu_feedback_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "menu_feedback_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_feedback_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_feedback_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_item_ai_analysis: {
        Row: {
          ai_model: string | null
          allergens_json: Json | null
          business_id: string
          calorie_max: number | null
          calorie_min: number | null
          confidence: number
          created_at: string
          id: string
          ingredients_json: Json | null
          menu_item_id: string | null
          normalized_text: string | null
          ocr_job_id: string | null
          requires_review: boolean
          source_text: string
          status: string
          updated_at: string
        }
        Insert: {
          ai_model?: string | null
          allergens_json?: Json | null
          business_id: string
          calorie_max?: number | null
          calorie_min?: number | null
          confidence?: number
          created_at?: string
          id?: string
          ingredients_json?: Json | null
          menu_item_id?: string | null
          normalized_text?: string | null
          ocr_job_id?: string | null
          requires_review?: boolean
          source_text: string
          status?: string
          updated_at?: string
        }
        Update: {
          ai_model?: string | null
          allergens_json?: Json | null
          business_id?: string
          calorie_max?: number | null
          calorie_min?: number | null
          confidence?: number
          created_at?: string
          id?: string
          ingredients_json?: Json | null
          menu_item_id?: string | null
          normalized_text?: string | null
          ocr_job_id?: string | null
          requires_review?: boolean
          source_text?: string
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "menu_item_ai_analysis_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "menu_item_ai_analysis_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_item_ai_analysis_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_item_ai_analysis_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_item_ai_analysis_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "business_item_trends_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_ai_analysis_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_item_price_status_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_ai_analysis_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_item_value_score_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_ai_analysis_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_item_ai_analysis_ocr_job_id_fkey"
            columns: ["ocr_job_id"]
            isOneToOne: false
            referencedRelation: "menu_ocr_jobs"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_item_allergens: {
        Row: {
          allergen: string
          detected_by: string
          item_id: string
          risk_level: string
          updated_at: string
        }
        Insert: {
          allergen: string
          detected_by?: string
          item_id: string
          risk_level?: string
          updated_at?: string
        }
        Update: {
          allergen?: string
          detected_by?: string
          item_id?: string
          risk_level?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "menu_item_allergens_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: false
            referencedRelation: "business_item_trends_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_allergens_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: false
            referencedRelation: "menu_item_price_status_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_allergens_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: false
            referencedRelation: "menu_item_value_score_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_allergens_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: false
            referencedRelation: "menu_items"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_item_diet_tags: {
        Row: {
          detected_by: string
          is_dairy_free: boolean | null
          is_gluten_free: boolean | null
          is_vegan: boolean | null
          is_vegetarian: boolean | null
          item_id: string
          updated_at: string
        }
        Insert: {
          detected_by?: string
          is_dairy_free?: boolean | null
          is_gluten_free?: boolean | null
          is_vegan?: boolean | null
          is_vegetarian?: boolean | null
          item_id: string
          updated_at?: string
        }
        Update: {
          detected_by?: string
          is_dairy_free?: boolean | null
          is_gluten_free?: boolean | null
          is_vegan?: boolean | null
          is_vegetarian?: boolean | null
          item_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "menu_item_diet_tags_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: true
            referencedRelation: "business_item_trends_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_diet_tags_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: true
            referencedRelation: "menu_item_price_status_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_diet_tags_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: true
            referencedRelation: "menu_item_value_score_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_diet_tags_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: true
            referencedRelation: "menu_items"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_item_ingredients: {
        Row: {
          category: string
          confidence: string
          item_id: string
          name: string
          sort_order: number
        }
        Insert: {
          category?: string
          confidence?: string
          item_id: string
          name: string
          sort_order?: number
        }
        Update: {
          category?: string
          confidence?: string
          item_id?: string
          name?: string
          sort_order?: number
        }
        Relationships: [
          {
            foreignKeyName: "menu_item_ingredients_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: false
            referencedRelation: "business_item_trends_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_ingredients_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: false
            referencedRelation: "menu_item_price_status_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_ingredients_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: false
            referencedRelation: "menu_item_value_score_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_ingredients_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: false
            referencedRelation: "menu_items"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_item_nutrition: {
        Row: {
          calorie_max: number | null
          calorie_min: number | null
          carbs_max_g: number | null
          carbs_min_g: number | null
          created_at: string
          fat_max_g: number | null
          fat_min_g: number | null
          is_approximate: boolean
          item_id: string
          protein_max_g: number | null
          protein_min_g: number | null
          serving_est_g: number | null
          source: string
          updated_at: string
          usda_fdc_ids: Json | null
        }
        Insert: {
          calorie_max?: number | null
          calorie_min?: number | null
          carbs_max_g?: number | null
          carbs_min_g?: number | null
          created_at?: string
          fat_max_g?: number | null
          fat_min_g?: number | null
          is_approximate?: boolean
          item_id: string
          protein_max_g?: number | null
          protein_min_g?: number | null
          serving_est_g?: number | null
          source?: string
          updated_at?: string
          usda_fdc_ids?: Json | null
        }
        Update: {
          calorie_max?: number | null
          calorie_min?: number | null
          carbs_max_g?: number | null
          carbs_min_g?: number | null
          created_at?: string
          fat_max_g?: number | null
          fat_min_g?: number | null
          is_approximate?: boolean
          item_id?: string
          protein_max_g?: number | null
          protein_min_g?: number | null
          serving_est_g?: number | null
          source?: string
          updated_at?: string
          usda_fdc_ids?: Json | null
        }
        Relationships: [
          {
            foreignKeyName: "menu_item_nutrition_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: true
            referencedRelation: "business_item_trends_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_nutrition_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: true
            referencedRelation: "menu_item_price_status_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_nutrition_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: true
            referencedRelation: "menu_item_value_score_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_nutrition_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: true
            referencedRelation: "menu_items"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_item_photo_votes: {
        Row: {
          created_at: string
          photo_id: string
          user_id: string
          vote: number
        }
        Insert: {
          created_at?: string
          photo_id: string
          user_id: string
          vote: number
        }
        Update: {
          created_at?: string
          photo_id?: string
          user_id?: string
          vote?: number
        }
        Relationships: [
          {
            foreignKeyName: "menu_item_photo_votes_photo_id_fkey"
            columns: ["photo_id"]
            isOneToOne: false
            referencedRelation: "menu_item_photos"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_item_photos: {
        Row: {
          business_id: string
          created_at: string
          created_by: string | null
          deleted_at: string | null
          deleted_by: string | null
          down_votes: number
          id: string
          is_hidden: boolean
          is_shadow: boolean
          menu_item_id: string
          moderation_note: string | null
          provider: string
          status: string
          up_votes: number
          url: string
          url_large: string | null
          url_thumb: string | null
        }
        Insert: {
          business_id: string
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          deleted_by?: string | null
          down_votes?: number
          id?: string
          is_hidden?: boolean
          is_shadow?: boolean
          menu_item_id: string
          moderation_note?: string | null
          provider?: string
          status?: string
          up_votes?: number
          url: string
          url_large?: string | null
          url_thumb?: string | null
        }
        Update: {
          business_id?: string
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          deleted_by?: string | null
          down_votes?: number
          id?: string
          is_hidden?: boolean
          is_shadow?: boolean
          menu_item_id?: string
          moderation_note?: string | null
          provider?: string
          status?: string
          up_votes?: number
          url?: string
          url_large?: string | null
          url_thumb?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "menu_item_photos_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "menu_item_photos_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_item_photos_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_item_photos_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_item_photos_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "business_item_trends_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_photos_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_item_price_status_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_photos_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_item_value_score_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_photos_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_items"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_item_price_history: {
        Row: {
          created_at: string
          created_by: string | null
          currency: string
          id: string
          menu_item_id: string
          new_price_cents: number | null
          old_price_cents: number | null
          price_cents: number
          source: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          currency?: string
          id?: string
          menu_item_id: string
          new_price_cents?: number | null
          old_price_cents?: number | null
          price_cents: number
          source?: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          currency?: string
          id?: string
          menu_item_id?: string
          new_price_cents?: number | null
          old_price_cents?: number | null
          price_cents?: number
          source?: string
        }
        Relationships: [
          {
            foreignKeyName: "menu_item_price_history_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "business_item_trends_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_price_history_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_item_price_status_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_price_history_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_item_value_score_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_price_history_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_items"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_item_price_suggestions: {
        Row: {
          anomaly_flags: Json
          anomaly_score: number
          approved_at: string | null
          approved_by: string | null
          business_id: string
          captured_at: string | null
          client_id: string | null
          conflict_state: string
          conflict_variants_24h: number
          created_at: string
          created_by: string
          currency: string
          evidence_url: string | null
          handled_at: string | null
          handled_by: string | null
          id: string
          is_shadow: boolean
          menu_item_id: string
          note: string | null
          onsite_signal: string | null
          onsite_verified: boolean
          quality_confidence: number
          quality_evidence_weight: number
          quality_time_weight: number
          quality_user_weight: number
          status: Database["public"]["Enums"]["menu_price_suggestion_status"]
          suggested_price_cents: number
        }
        Insert: {
          anomaly_flags?: Json
          anomaly_score?: number
          approved_at?: string | null
          approved_by?: string | null
          business_id: string
          captured_at?: string | null
          client_id?: string | null
          conflict_state?: string
          conflict_variants_24h?: number
          created_at?: string
          created_by: string
          currency?: string
          evidence_url?: string | null
          handled_at?: string | null
          handled_by?: string | null
          id?: string
          is_shadow?: boolean
          menu_item_id: string
          note?: string | null
          onsite_signal?: string | null
          onsite_verified?: boolean
          quality_confidence?: number
          quality_evidence_weight?: number
          quality_time_weight?: number
          quality_user_weight?: number
          status?: Database["public"]["Enums"]["menu_price_suggestion_status"]
          suggested_price_cents: number
        }
        Update: {
          anomaly_flags?: Json
          anomaly_score?: number
          approved_at?: string | null
          approved_by?: string | null
          business_id?: string
          captured_at?: string | null
          client_id?: string | null
          conflict_state?: string
          conflict_variants_24h?: number
          created_at?: string
          created_by?: string
          currency?: string
          evidence_url?: string | null
          handled_at?: string | null
          handled_by?: string | null
          id?: string
          is_shadow?: boolean
          menu_item_id?: string
          note?: string | null
          onsite_signal?: string | null
          onsite_verified?: boolean
          quality_confidence?: number
          quality_evidence_weight?: number
          quality_time_weight?: number
          quality_user_weight?: number
          status?: Database["public"]["Enums"]["menu_price_suggestion_status"]
          suggested_price_cents?: number
        }
        Relationships: [
          {
            foreignKeyName: "menu_item_price_suggestions_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "menu_item_price_suggestions_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_item_price_suggestions_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_item_price_suggestions_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_item_price_suggestions_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "business_item_trends_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_price_suggestions_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_item_price_status_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_price_suggestions_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_item_value_score_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_price_suggestions_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_items"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_item_price_votes: {
        Row: {
          created_at: string
          menu_item_id: string
          user_id: string
          vote: number
        }
        Insert: {
          created_at?: string
          menu_item_id: string
          user_id: string
          vote: number
        }
        Update: {
          created_at?: string
          menu_item_id?: string
          user_id?: string
          vote?: number
        }
        Relationships: [
          {
            foreignKeyName: "menu_item_price_votes_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "business_item_trends_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_price_votes_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_item_price_status_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_price_votes_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_item_value_score_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_price_votes_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_items"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_item_suggestions: {
        Row: {
          action: string
          admin_note: string | null
          business_id: string
          created_at: string
          created_by: string
          handled_at: string | null
          handled_by: string | null
          id: string
          menu_item_id: string | null
          payload: Json
          status: Database["public"]["Enums"]["contrib_status"]
        }
        Insert: {
          action: string
          admin_note?: string | null
          business_id: string
          created_at?: string
          created_by: string
          handled_at?: string | null
          handled_by?: string | null
          id?: string
          menu_item_id?: string | null
          payload: Json
          status?: Database["public"]["Enums"]["contrib_status"]
        }
        Update: {
          action?: string
          admin_note?: string | null
          business_id?: string
          created_at?: string
          created_by?: string
          handled_at?: string | null
          handled_by?: string | null
          id?: string
          menu_item_id?: string | null
          payload?: Json
          status?: Database["public"]["Enums"]["contrib_status"]
        }
        Relationships: [
          {
            foreignKeyName: "menu_item_suggestions_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "menu_item_suggestions_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_item_suggestions_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_item_suggestions_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_item_suggestions_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "business_item_trends_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_suggestions_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_item_price_status_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_suggestions_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_item_value_score_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_suggestions_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_items"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_item_translations: {
        Row: {
          created_at: string
          description: string | null
          id: string
          locale: string
          menu_item_id: string
          name: string | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          locale: string
          menu_item_id: string
          name?: string | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          locale?: string
          menu_item_id?: string
          name?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "menu_item_translations_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "business_item_trends_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_translations_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_item_price_status_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_translations_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_item_value_score_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_translations_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_items"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_item_variant_groups: {
        Row: {
          created_at: string
          group_type: string
          id: string
          is_required: boolean
          item_id: string
          name: string
          selection: string
          sort_order: number
        }
        Insert: {
          created_at?: string
          group_type?: string
          id?: string
          is_required?: boolean
          item_id: string
          name: string
          selection?: string
          sort_order?: number
        }
        Update: {
          created_at?: string
          group_type?: string
          id?: string
          is_required?: boolean
          item_id?: string
          name?: string
          selection?: string
          sort_order?: number
        }
        Relationships: [
          {
            foreignKeyName: "menu_item_variant_groups_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: false
            referencedRelation: "business_item_trends_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_variant_groups_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: false
            referencedRelation: "menu_item_price_status_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_variant_groups_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: false
            referencedRelation: "menu_item_value_score_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_variant_groups_item_id_fkey"
            columns: ["item_id"]
            isOneToOne: false
            referencedRelation: "menu_items"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_item_variant_options: {
        Row: {
          created_at: string
          group_id: string
          id: string
          is_available: boolean
          is_default: boolean
          label: string
          price_modifier_cents: number
          sort_order: number
        }
        Insert: {
          created_at?: string
          group_id: string
          id?: string
          is_available?: boolean
          is_default?: boolean
          label: string
          price_modifier_cents?: number
          sort_order?: number
        }
        Update: {
          created_at?: string
          group_id?: string
          id?: string
          is_available?: boolean
          is_default?: boolean
          label?: string
          price_modifier_cents?: number
          sort_order?: number
        }
        Relationships: [
          {
            foreignKeyName: "menu_item_variant_options_group_id_fkey"
            columns: ["group_id"]
            isOneToOne: false
            referencedRelation: "menu_item_variant_groups"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_item_variants: {
        Row: {
          created_at: string
          currency: string
          id: string
          is_available: boolean
          is_default: boolean
          label: string
          menu_item_id: string
          price_cents: number
          sort_order: number
          updated_at: string
        }
        Insert: {
          created_at?: string
          currency?: string
          id?: string
          is_available?: boolean
          is_default?: boolean
          label: string
          menu_item_id: string
          price_cents: number
          sort_order?: number
          updated_at?: string
        }
        Update: {
          created_at?: string
          currency?: string
          id?: string
          is_available?: boolean
          is_default?: boolean
          label?: string
          menu_item_id?: string
          price_cents?: number
          sort_order?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "menu_item_variants_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "business_item_trends_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_variants_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_item_price_status_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_variants_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_item_value_score_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "menu_item_variants_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_items"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_items: {
        Row: {
          business_id: string
          calorie_source: string | null
          calories_max: number | null
          calories_min: number | null
          category_id: string | null
          created_at: string
          currency: string
          description: string | null
          id: string
          image_url: string | null
          is_available: boolean
          is_today_special: boolean
          name: string
          portion_size: number | null
          portion_unit: string | null
          price_cents: number
          section_id: string
          sort_order: number
          special_date: string | null
          special_note: string | null
          tags: Json
          time_windows: Json | null
          updated_at: string
        }
        Insert: {
          business_id: string
          calorie_source?: string | null
          calories_max?: number | null
          calories_min?: number | null
          category_id?: string | null
          created_at?: string
          currency?: string
          description?: string | null
          id?: string
          image_url?: string | null
          is_available?: boolean
          is_today_special?: boolean
          name: string
          portion_size?: number | null
          portion_unit?: string | null
          price_cents?: number
          section_id: string
          sort_order?: number
          special_date?: string | null
          special_note?: string | null
          tags?: Json
          time_windows?: Json | null
          updated_at?: string
        }
        Update: {
          business_id?: string
          calorie_source?: string | null
          calories_max?: number | null
          calories_min?: number | null
          category_id?: string | null
          created_at?: string
          currency?: string
          description?: string | null
          id?: string
          image_url?: string | null
          is_available?: boolean
          is_today_special?: boolean
          name?: string
          portion_size?: number | null
          portion_unit?: string | null
          price_cents?: number
          section_id?: string
          sort_order?: number
          special_date?: string | null
          special_note?: string | null
          tags?: Json
          time_windows?: Json | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "menu_items_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "menu_items_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_items_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_items_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_items_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "menu_categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_items_section_id_fkey"
            columns: ["section_id"]
            isOneToOne: false
            referencedRelation: "menu_sections"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_ocr_jobs: {
        Row: {
          business_id: string
          created_at: string
          error_message: string | null
          file_name: string | null
          file_url: string
          id: string
          item_count: number | null
          ocr_engine: string | null
          owner_id: string
          parsed_output: Json | null
          raw_text: string | null
          status: string
          updated_at: string
        }
        Insert: {
          business_id: string
          created_at?: string
          error_message?: string | null
          file_name?: string | null
          file_url: string
          id?: string
          item_count?: number | null
          ocr_engine?: string | null
          owner_id: string
          parsed_output?: Json | null
          raw_text?: string | null
          status?: string
          updated_at?: string
        }
        Update: {
          business_id?: string
          created_at?: string
          error_message?: string | null
          file_name?: string | null
          file_url?: string
          id?: string
          item_count?: number | null
          ocr_engine?: string | null
          owner_id?: string
          parsed_output?: Json | null
          raw_text?: string | null
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "menu_ocr_jobs_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "menu_ocr_jobs_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_ocr_jobs_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_ocr_jobs_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_sections: {
        Row: {
          created_at: string
          created_by: string | null
          id: string
          menu_id: string
          sort_order: number
          title: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          id?: string
          menu_id: string
          sort_order?: number
          title: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          id?: string
          menu_id?: string
          sort_order?: number
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "menu_sections_menu_id_fkey"
            columns: ["menu_id"]
            isOneToOne: false
            referencedRelation: "menus"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_snapshots: {
        Row: {
          business_id: string
          created_at: string
          created_by: string | null
          id: string
          menu_version: number
          snapshot_json: Json
          snapshot_reason: string
          source_menu_id: string
        }
        Insert: {
          business_id: string
          created_at?: string
          created_by?: string | null
          id?: string
          menu_version?: number
          snapshot_json: Json
          snapshot_reason?: string
          source_menu_id: string
        }
        Update: {
          business_id?: string
          created_at?: string
          created_by?: string | null
          id?: string
          menu_version?: number
          snapshot_json?: Json
          snapshot_reason?: string
          source_menu_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "menu_snapshots_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "menu_snapshots_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_snapshots_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_snapshots_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_snapshots_source_menu_id_fkey"
            columns: ["source_menu_id"]
            isOneToOne: false
            referencedRelation: "menus"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_translations: {
        Row: {
          created_at: string
          description: string | null
          entity_id: string
          entity_type: Database["public"]["Enums"]["translation_entity_type"]
          id: string
          locale: string
          name: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          entity_id: string
          entity_type: Database["public"]["Enums"]["translation_entity_type"]
          id?: string
          locale: string
          name: string
        }
        Update: {
          created_at?: string
          description?: string | null
          entity_id?: string
          entity_type?: Database["public"]["Enums"]["translation_entity_type"]
          id?: string
          locale?: string
          name?: string
        }
        Relationships: []
      }
      menus: {
        Row: {
          active_from: string | null
          active_to: string | null
          business_id: string
          confidence_score: number
          created_at: string
          created_by: string | null
          external_url: string | null
          id: string
          kind: string | null
          source: string
          source_image_url: string | null
          status: Database["public"]["Enums"]["menu_status"]
          title: string
          updated_at: string
          version: number
        }
        Insert: {
          active_from?: string | null
          active_to?: string | null
          business_id: string
          confidence_score?: number
          created_at?: string
          created_by?: string | null
          external_url?: string | null
          id?: string
          kind?: string | null
          source?: string
          source_image_url?: string | null
          status?: Database["public"]["Enums"]["menu_status"]
          title?: string
          updated_at?: string
          version?: number
        }
        Update: {
          active_from?: string | null
          active_to?: string | null
          business_id?: string
          confidence_score?: number
          created_at?: string
          created_by?: string | null
          external_url?: string | null
          id?: string
          kind?: string | null
          source?: string
          source_image_url?: string | null
          status?: Database["public"]["Enums"]["menu_status"]
          title?: string
          updated_at?: string
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "menus_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "menus_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menus_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menus_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      moderation_appeals: {
        Row: {
          appellant_user_id: string
          assigned_at: string | null
          assigned_to: string | null
          created_at: string
          decided_at: string | null
          decided_by: string | null
          decision_note: string | null
          details: string | null
          id: string
          reason: string
          source_id: string
          source_type: string
          status: string
          updated_at: string
        }
        Insert: {
          appellant_user_id: string
          assigned_at?: string | null
          assigned_to?: string | null
          created_at?: string
          decided_at?: string | null
          decided_by?: string | null
          decision_note?: string | null
          details?: string | null
          id?: string
          reason: string
          source_id: string
          source_type: string
          status?: string
          updated_at?: string
        }
        Update: {
          appellant_user_id?: string
          assigned_at?: string | null
          assigned_to?: string | null
          created_at?: string
          decided_at?: string | null
          decided_by?: string | null
          decision_note?: string | null
          details?: string | null
          id?: string
          reason?: string
          source_id?: string
          source_type?: string
          status?: string
          updated_at?: string
        }
        Relationships: []
      }
      moderation_decision_templates: {
        Row: {
          body: string
          created_at: string
          decision: string
          id: string
          is_active: boolean
          locale: string
          scope: string
          title: string
          updated_at: string
        }
        Insert: {
          body: string
          created_at?: string
          decision: string
          id?: string
          is_active?: boolean
          locale?: string
          scope: string
          title: string
          updated_at?: string
        }
        Update: {
          body?: string
          created_at?: string
          decision?: string
          id?: string
          is_active?: boolean
          locale?: string
          scope?: string
          title?: string
          updated_at?: string
        }
        Relationships: []
      }
      notification_dispatch_jobs: {
        Row: {
          attempts: number
          created_at: string
          id: string
          last_error: string | null
          locked_at: string | null
          notification_id: string
          status: string
          updated_at: string
        }
        Insert: {
          attempts?: number
          created_at?: string
          id?: string
          last_error?: string | null
          locked_at?: string | null
          notification_id: string
          status?: string
          updated_at?: string
        }
        Update: {
          attempts?: number
          created_at?: string
          id?: string
          last_error?: string | null
          locked_at?: string | null
          notification_id?: string
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "notification_dispatch_jobs_notification_id_fkey"
            columns: ["notification_id"]
            isOneToOne: true
            referencedRelation: "notifications"
            referencedColumns: ["id"]
          },
        ]
      }
      notification_preferences: {
        Row: {
          created_at: string
          enabled: boolean
          id: string
          notification_type: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          enabled?: boolean
          id?: string
          notification_type: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          enabled?: boolean
          id?: string
          notification_type?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      notifications: {
        Row: {
          body: string
          created_at: string
          data: Json
          id: string
          is_read: boolean
          title: string
          type: string
          user_id: string
        }
        Insert: {
          body: string
          created_at?: string
          data?: Json
          id?: string
          is_read?: boolean
          title: string
          type: string
          user_id: string
        }
        Update: {
          body?: string
          created_at?: string
          data?: Json
          id?: string
          is_read?: boolean
          title?: string
          type?: string
          user_id?: string
        }
        Relationships: []
      }
      offer_messages: {
        Row: {
          body: string
          business_id: string | null
          created_at: string
          id: string
          offer_id: string | null
          request_id: string
          sender_type: string
          sender_user_id: string | null
        }
        Insert: {
          body: string
          business_id?: string | null
          created_at?: string
          id?: string
          offer_id?: string | null
          request_id: string
          sender_type: string
          sender_user_id?: string | null
        }
        Update: {
          body?: string
          business_id?: string | null
          created_at?: string
          id?: string
          offer_id?: string | null
          request_id?: string
          sender_type?: string
          sender_user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "offer_messages_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "offer_messages_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "offer_messages_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "offer_messages_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "offer_messages_offer_id_fkey"
            columns: ["offer_id"]
            isOneToOne: false
            referencedRelation: "group_offers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "offer_messages_request_id_fkey"
            columns: ["request_id"]
            isOneToOne: false
            referencedRelation: "group_requests"
            referencedColumns: ["id"]
          },
        ]
      }
      osm_admin_boundaries: {
        Row: {
          admin_level: number
          boundary: unknown
          centroid: unknown
          id: string
          imported_at: string
          name: string
          name_en: string | null
          osm_id: number
          parent_id: string | null
          properties: Json
        }
        Insert: {
          admin_level: number
          boundary?: unknown
          centroid?: unknown
          id?: string
          imported_at?: string
          name: string
          name_en?: string | null
          osm_id: number
          parent_id?: string | null
          properties?: Json
        }
        Update: {
          admin_level?: number
          boundary?: unknown
          centroid?: unknown
          id?: string
          imported_at?: string
          name?: string
          name_en?: string | null
          osm_id?: number
          parent_id?: string | null
          properties?: Json
        }
        Relationships: [
          {
            foreignKeyName: "osm_admin_boundaries_parent_id_fkey"
            columns: ["parent_id"]
            isOneToOne: false
            referencedRelation: "osm_admin_boundaries"
            referencedColumns: ["id"]
          },
        ]
      }
      owner_claims: {
        Row: {
          admin_note: string | null
          assigned_at: string | null
          assigned_to: string | null
          auto_moderated: boolean
          business_id: string
          created_at: string
          evidence_storage_path: string | null
          evidence_url: string | null
          full_name: string | null
          handled_at: string | null
          handled_by: string | null
          id: string
          note: string | null
          phone: string | null
          reviewed_at: string | null
          status: string
          user_id: string
        }
        Insert: {
          admin_note?: string | null
          assigned_at?: string | null
          assigned_to?: string | null
          auto_moderated?: boolean
          business_id: string
          created_at?: string
          evidence_storage_path?: string | null
          evidence_url?: string | null
          full_name?: string | null
          handled_at?: string | null
          handled_by?: string | null
          id?: string
          note?: string | null
          phone?: string | null
          reviewed_at?: string | null
          status?: string
          user_id: string
        }
        Update: {
          admin_note?: string | null
          assigned_at?: string | null
          assigned_to?: string | null
          auto_moderated?: boolean
          business_id?: string
          created_at?: string
          evidence_storage_path?: string | null
          evidence_url?: string | null
          full_name?: string | null
          handled_at?: string | null
          handled_by?: string | null
          id?: string
          note?: string | null
          phone?: string | null
          reviewed_at?: string | null
          status?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "owner_claims_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "owner_claims_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "owner_claims_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "owner_claims_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      owner_onboarding_progress: {
        Row: {
          business_id: string
          step_completed: number
          updated_at: string
        }
        Insert: {
          business_id: string
          step_completed?: number
          updated_at?: string
        }
        Update: {
          business_id?: string
          step_completed?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "owner_onboarding_progress_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "owner_onboarding_progress_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "owner_onboarding_progress_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "owner_onboarding_progress_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: true
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      photo_missions: {
        Row: {
          business_id: string
          city: string | null
          created_at: string
          district: string | null
          expires_at: string | null
          id: string
          mission_type: string
          reward_points: number
        }
        Insert: {
          business_id: string
          city?: string | null
          created_at?: string
          district?: string | null
          expires_at?: string | null
          id?: string
          mission_type: string
          reward_points?: number
        }
        Update: {
          business_id?: string
          city?: string | null
          created_at?: string
          district?: string | null
          expires_at?: string | null
          id?: string
          mission_type?: string
          reward_points?: number
        }
        Relationships: [
          {
            foreignKeyName: "photo_missions_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "photo_missions_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "photo_missions_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "photo_missions_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      plan_feature_usage: {
        Row: {
          business_id: string
          feature_key: string
          period_start: string
          usage_count: number
        }
        Insert: {
          business_id: string
          feature_key: string
          period_start: string
          usage_count?: number
        }
        Update: {
          business_id?: string
          feature_key?: string
          period_start?: string
          usage_count?: number
        }
        Relationships: [
          {
            foreignKeyName: "plan_feature_usage_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "plan_feature_usage_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "plan_feature_usage_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "plan_feature_usage_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      plan_features: {
        Row: {
          enabled: boolean
          feature_key: string
          limit_value: number | null
          plan_tier: string
        }
        Insert: {
          enabled?: boolean
          feature_key: string
          limit_value?: number | null
          plan_tier: string
        }
        Update: {
          enabled?: boolean
          feature_key?: string
          limit_value?: number | null
          plan_tier?: string
        }
        Relationships: []
      }
      policy_versions: {
        Row: {
          content_hash: string
          created_at: string
          created_by: string | null
          id: string
          is_active: boolean
          policy_type: string
          published_at: string
          version_label: string
        }
        Insert: {
          content_hash: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          policy_type: string
          published_at?: string
          version_label: string
        }
        Update: {
          content_hash?: string
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          policy_type?: string
          published_at?: string
          version_label?: string
        }
        Relationships: []
      }
      price_alerts: {
        Row: {
          category: string | null
          city: string | null
          created_at: string
          currency: string
          district: string | null
          id: string
          is_active: boolean
          max_price_cents: number
          query: string
          user_id: string
        }
        Insert: {
          category?: string | null
          city?: string | null
          created_at?: string
          currency?: string
          district?: string | null
          id?: string
          is_active?: boolean
          max_price_cents: number
          query: string
          user_id: string
        }
        Update: {
          category?: string | null
          city?: string | null
          created_at?: string
          currency?: string
          district?: string | null
          id?: string
          is_active?: boolean
          max_price_cents?: number
          query?: string
          user_id?: string
        }
        Relationships: []
      }
      privacy_requests: {
        Row: {
          created_at: string
          details: string
          id: string
          request_type: string
          resolved_at: string | null
          status: string
          submitted_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          details?: string
          id?: string
          request_type: string
          resolved_at?: string | null
          status?: string
          submitted_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          details?: string
          id?: string
          request_type?: string
          resolved_at?: string | null
          status?: string
          submitted_at?: string
          user_id?: string
        }
        Relationships: []
      }
      push_campaigns: {
        Row: {
          body: string
          business_id: string
          created_at: string | null
          created_by: string | null
          id: string
          image_url: string | null
          opened_count: number | null
          scheduled_at: string | null
          sent_at: string | null
          sent_count: number | null
          target_segment: Database["public"]["Enums"]["push_campaign_segment"]
          title: string
        }
        Insert: {
          body: string
          business_id: string
          created_at?: string | null
          created_by?: string | null
          id?: string
          image_url?: string | null
          opened_count?: number | null
          scheduled_at?: string | null
          sent_at?: string | null
          sent_count?: number | null
          target_segment?: Database["public"]["Enums"]["push_campaign_segment"]
          title: string
        }
        Update: {
          body?: string
          business_id?: string
          created_at?: string | null
          created_by?: string | null
          id?: string
          image_url?: string | null
          opened_count?: number | null
          scheduled_at?: string | null
          sent_at?: string | null
          sent_count?: number | null
          target_segment?: Database["public"]["Enums"]["push_campaign_segment"]
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "push_campaigns_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "push_campaigns_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "push_campaigns_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "push_campaigns_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      rate_limit_buckets: {
        Row: {
          count: number
          key: string
          window_end: string
        }
        Insert: {
          count?: number
          key: string
          window_end?: string
        }
        Update: {
          count?: number
          key?: string
          window_end?: string
        }
        Relationships: []
      }
      receipt_matches: {
        Row: {
          detected_price_cents: number
          menu_item_id: string
          receipt_id: string
        }
        Insert: {
          detected_price_cents: number
          menu_item_id: string
          receipt_id: string
        }
        Update: {
          detected_price_cents?: number
          menu_item_id?: string
          receipt_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "receipt_matches_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "business_item_trends_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "receipt_matches_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_item_price_status_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "receipt_matches_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_item_value_score_v1"
            referencedColumns: ["menu_item_id"]
          },
          {
            foreignKeyName: "receipt_matches_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "receipt_matches_receipt_id_fkey"
            columns: ["receipt_id"]
            isOneToOne: false
            referencedRelation: "receipt_submissions"
            referencedColumns: ["id"]
          },
        ]
      }
      receipt_submissions: {
        Row: {
          business_id: string
          created_at: string
          id: string
          image_url: string
          review_note: string | null
          review_status: string
          reviewed_at: string | null
          reviewed_by: string | null
          user_id: string
        }
        Insert: {
          business_id: string
          created_at?: string
          id?: string
          image_url: string
          review_note?: string | null
          review_status?: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          user_id: string
        }
        Update: {
          business_id?: string
          created_at?: string
          id?: string
          image_url?: string
          review_note?: string | null
          review_status?: string
          reviewed_at?: string | null
          reviewed_by?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "receipt_submissions_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "receipt_submissions_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "receipt_submissions_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "receipt_submissions_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      reports: {
        Row: {
          admin_note: string | null
          assigned_at: string | null
          assigned_to: string | null
          auto_moderated: boolean
          business_id: string | null
          created_at: string
          details: string | null
          handled_at: string | null
          handled_by: string | null
          id: string
          menu_item_photo_id: string | null
          reason: string
          reporter_user_id: string | null
          review_id: string | null
          status: string
          target_id: string
          target_type: string
          user_id: string | null
        }
        Insert: {
          admin_note?: string | null
          assigned_at?: string | null
          assigned_to?: string | null
          auto_moderated?: boolean
          business_id?: string | null
          created_at?: string
          details?: string | null
          handled_at?: string | null
          handled_by?: string | null
          id?: string
          menu_item_photo_id?: string | null
          reason: string
          reporter_user_id?: string | null
          review_id?: string | null
          status?: string
          target_id: string
          target_type: string
          user_id?: string | null
        }
        Update: {
          admin_note?: string | null
          assigned_at?: string | null
          assigned_to?: string | null
          auto_moderated?: boolean
          business_id?: string | null
          created_at?: string
          details?: string | null
          handled_at?: string | null
          handled_by?: string | null
          id?: string
          menu_item_photo_id?: string | null
          reason?: string
          reporter_user_id?: string | null
          review_id?: string | null
          status?: string
          target_id?: string
          target_type?: string
          user_id?: string | null
        }
        Relationships: []
      }
      reservations: {
        Row: {
          business_id: string
          channel: string
          created_at: string
          guest_email: string | null
          guest_name: string
          guest_phone: string
          id: string
          owner_note: string | null
          party_size: number
          reservation_date: string
          reservation_no: string
          reservation_time: string
          special_request: string | null
          status: string
          table_preference: string | null
          updated_at: string
          user_id: string | null
        }
        Insert: {
          business_id: string
          channel?: string
          created_at?: string
          guest_email?: string | null
          guest_name: string
          guest_phone: string
          id?: string
          owner_note?: string | null
          party_size: number
          reservation_date: string
          reservation_no: string
          reservation_time: string
          special_request?: string | null
          status?: string
          table_preference?: string | null
          updated_at?: string
          user_id?: string | null
        }
        Update: {
          business_id?: string
          channel?: string
          created_at?: string
          guest_email?: string | null
          guest_name?: string
          guest_phone?: string
          id?: string
          owner_note?: string | null
          party_size?: number
          reservation_date?: string
          reservation_no?: string
          reservation_time?: string
          special_request?: string | null
          status?: string
          table_preference?: string | null
          updated_at?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "reservations_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "reservations_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reservations_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reservations_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      review_replies: {
        Row: {
          business_id: string
          content: string
          created_at: string
          id: string
          owner_user_id: string
          review_id: string
          updated_at: string
        }
        Insert: {
          business_id: string
          content: string
          created_at?: string
          id?: string
          owner_user_id: string
          review_id: string
          updated_at?: string
        }
        Update: {
          business_id?: string
          content?: string
          created_at?: string
          id?: string
          owner_user_id?: string
          review_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "review_replies_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "review_replies_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "review_replies_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "review_replies_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "review_replies_review_id_fkey"
            columns: ["review_id"]
            isOneToOne: true
            referencedRelation: "business_reviews"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "review_replies_review_id_fkey"
            columns: ["review_id"]
            isOneToOne: true
            referencedRelation: "review_ratings"
            referencedColumns: ["review_id"]
          },
          {
            foreignKeyName: "review_replies_review_id_fkey"
            columns: ["review_id"]
            isOneToOne: true
            referencedRelation: "reviews"
            referencedColumns: ["id"]
          },
        ]
      }
      review_tags: {
        Row: {
          business_id: string
          id: string
          last_seen_at: string
          mention_count: number
          tag: string
        }
        Insert: {
          business_id: string
          id?: string
          last_seen_at?: string
          mention_count?: number
          tag: string
        }
        Update: {
          business_id?: string
          id?: string
          last_seen_at?: string
          mention_count?: number
          tag?: string
        }
        Relationships: [
          {
            foreignKeyName: "review_tags_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "review_tags_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "review_tags_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "review_tags_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      review_votes: {
        Row: {
          created_at: string
          id: string
          is_helpful: boolean
          review_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          is_helpful?: boolean
          review_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          is_helpful?: boolean
          review_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "review_votes_review_id_fkey"
            columns: ["review_id"]
            isOneToOne: false
            referencedRelation: "business_reviews"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "review_votes_review_id_fkey"
            columns: ["review_id"]
            isOneToOne: false
            referencedRelation: "review_ratings"
            referencedColumns: ["review_id"]
          },
          {
            foreignKeyName: "review_votes_review_id_fkey"
            columns: ["review_id"]
            isOneToOne: false
            referencedRelation: "reviews"
            referencedColumns: ["id"]
          },
        ]
      }
      reviews: {
        Row: {
          atmosphere_rating: number | null
          business_id: string
          cleanliness_rating: number | null
          content: string
          created_at: string
          helpful_count: number
          id: string
          overall_rating: number | null
          owner_replied_at: string | null
          owner_reply: string | null
          price_performance_rating: number | null
          rating: number
          service_speed_rating: number | null
          status: string
          taste_rating: number | null
          title: string | null
          user_id: string | null
        }
        Insert: {
          atmosphere_rating?: number | null
          business_id: string
          cleanliness_rating?: number | null
          content: string
          created_at?: string
          helpful_count?: number
          id?: string
          overall_rating?: number | null
          owner_replied_at?: string | null
          owner_reply?: string | null
          price_performance_rating?: number | null
          rating: number
          service_speed_rating?: number | null
          status?: string
          taste_rating?: number | null
          title?: string | null
          user_id?: string | null
        }
        Update: {
          atmosphere_rating?: number | null
          business_id?: string
          cleanliness_rating?: number | null
          content?: string
          created_at?: string
          helpful_count?: number
          id?: string
          overall_rating?: number | null
          owner_replied_at?: string | null
          owner_reply?: string | null
          price_performance_rating?: number | null
          rating?: number
          service_speed_rating?: number | null
          status?: string
          taste_rating?: number | null
          title?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "reviews_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "reviews_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reviews_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reviews_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      runtime_experiments: {
        Row: {
          allowed_regions: string[]
          blocked_regions: string[]
          enabled: boolean
          key: string
          updated_at: string
          updated_by: string | null
          variants: Json
        }
        Insert: {
          allowed_regions?: string[]
          blocked_regions?: string[]
          enabled?: boolean
          key: string
          updated_at?: string
          updated_by?: string | null
          variants?: Json
        }
        Update: {
          allowed_regions?: string[]
          blocked_regions?: string[]
          enabled?: boolean
          key?: string
          updated_at?: string
          updated_by?: string | null
          variants?: Json
        }
        Relationships: []
      }
      runtime_feature_flags: {
        Row: {
          allowed_regions: string[]
          blocked_regions: string[]
          enabled: boolean
          key: string
          metadata: Json
          rollout_percent: number
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          allowed_regions?: string[]
          blocked_regions?: string[]
          enabled?: boolean
          key: string
          metadata?: Json
          rollout_percent?: number
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          allowed_regions?: string[]
          blocked_regions?: string[]
          enabled?: boolean
          key?: string
          metadata?: Json
          rollout_percent?: number
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: []
      }
      runtime_release_controls: {
        Row: {
          global_kill_switch: boolean
          id: boolean
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          global_kill_switch?: boolean
          id?: boolean
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          global_kill_switch?: boolean
          id?: boolean
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: []
      }
      saved_campaigns: {
        Row: {
          created_at: string
          id: string
          story_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          story_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          story_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "saved_campaigns_story_id_fkey"
            columns: ["story_id"]
            isOneToOne: false
            referencedRelation: "business_stories"
            referencedColumns: ["id"]
          },
        ]
      }
      spatial_ref_sys: {
        Row: {
          auth_name: string | null
          auth_srid: number | null
          proj4text: string | null
          srid: number
          srtext: string | null
        }
        Insert: {
          auth_name?: string | null
          auth_srid?: number | null
          proj4text?: string | null
          srid: number
          srtext?: string | null
        }
        Update: {
          auth_name?: string | null
          auth_srid?: number | null
          proj4text?: string | null
          srid?: number
          srtext?: string | null
        }
        Relationships: []
      }
      sponsorship_impressions_daily: {
        Row: {
          created_at: string
          day: string
          id: string
          impressions_count: number
          sponsorship_id: string
          unique_users_count: number
          updated_at: string
        }
        Insert: {
          created_at?: string
          day: string
          id?: string
          impressions_count?: number
          sponsorship_id: string
          unique_users_count?: number
          updated_at?: string
        }
        Update: {
          created_at?: string
          day?: string
          id?: string
          impressions_count?: number
          sponsorship_id?: string
          unique_users_count?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "sponsorship_impressions_daily_sponsorship_id_fkey"
            columns: ["sponsorship_id"]
            isOneToOne: false
            referencedRelation: "sponsorships"
            referencedColumns: ["id"]
          },
        ]
      }
      sponsorship_leads: {
        Row: {
          business_id: string
          created_at: string
          id: string
          message: string | null
          owner_user_id: string
          phone: string | null
          preferred_surface: string
          preferred_targeting: Json
          status: string
        }
        Insert: {
          business_id: string
          created_at?: string
          id?: string
          message?: string | null
          owner_user_id: string
          phone?: string | null
          preferred_surface: string
          preferred_targeting?: Json
          status?: string
        }
        Update: {
          business_id?: string
          created_at?: string
          id?: string
          message?: string | null
          owner_user_id?: string
          phone?: string | null
          preferred_surface?: string
          preferred_targeting?: Json
          status?: string
        }
        Relationships: [
          {
            foreignKeyName: "sponsorship_leads_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "sponsorship_leads_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sponsorship_leads_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sponsorship_leads_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      sponsorship_packages: {
        Row: {
          created_at: string | null
          currency_code: string
          duration_days: number
          id: string
          inventory_limit: number
          is_active: boolean
          name: string
          price_cents: number
          price_display: string
          surface: string
        }
        Insert: {
          created_at?: string | null
          currency_code?: string
          duration_days: number
          id?: string
          inventory_limit?: number
          is_active?: boolean
          name: string
          price_cents?: number
          price_display: string
          surface: string
        }
        Update: {
          created_at?: string | null
          currency_code?: string
          duration_days?: number
          id?: string
          inventory_limit?: number
          is_active?: boolean
          name?: string
          price_cents?: number
          price_display?: string
          surface?: string
        }
        Relationships: []
      }
      sponsorships: {
        Row: {
          business_id: string
          created_at: string
          created_by: string | null
          daily_cap: number | null
          ends_at: string | null
          id: string
          package_id: string
          source: string
          starts_at: string | null
          status: string
          surface: string
          targeting: Json
          total_cap: number | null
          updated_at: string
        }
        Insert: {
          business_id: string
          created_at?: string
          created_by?: string | null
          daily_cap?: number | null
          ends_at?: string | null
          id?: string
          package_id: string
          source?: string
          starts_at?: string | null
          status?: string
          surface: string
          targeting?: Json
          total_cap?: number | null
          updated_at?: string
        }
        Update: {
          business_id?: string
          created_at?: string
          created_by?: string | null
          daily_cap?: number | null
          ends_at?: string | null
          id?: string
          package_id?: string
          source?: string
          starts_at?: string | null
          status?: string
          surface?: string
          targeting?: Json
          total_cap?: number | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "sponsorships_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "sponsorships_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sponsorships_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sponsorships_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sponsorships_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "admin_users"
            referencedColumns: ["user_id"]
          },
          {
            foreignKeyName: "sponsorships_package_id_fkey"
            columns: ["package_id"]
            isOneToOne: false
            referencedRelation: "sponsorship_packages"
            referencedColumns: ["id"]
          },
        ]
      }
      storage_deletion_queue: {
        Row: {
          attempts: number
          bucket: string
          id: string
          last_error: string | null
          path: string
          processed_at: string | null
          reason: string
          scheduled_at: string
        }
        Insert: {
          attempts?: number
          bucket: string
          id?: string
          last_error?: string | null
          path: string
          processed_at?: string | null
          reason: string
          scheduled_at?: string
        }
        Update: {
          attempts?: number
          bucket?: string
          id?: string
          last_error?: string | null
          path?: string
          processed_at?: string | null
          reason?: string
          scheduled_at?: string
        }
        Relationships: []
      }
      support_ticket_messages: {
        Row: {
          created_at: string
          created_by: string | null
          id: string
          message: string
          sender: string
          ticket_id: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          id?: string
          message: string
          sender: string
          ticket_id: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          id?: string
          message?: string
          sender?: string
          ticket_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "support_ticket_messages_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "support_tickets"
            referencedColumns: ["id"]
          },
        ]
      }
      support_tickets: {
        Row: {
          assigned_to: string | null
          business_id: string | null
          category: string
          created_at: string
          id: string
          priority: string
          requester_email: string | null
          requester_name: string | null
          status: string
          subject: string
          updated_at: string
          user_id: string | null
        }
        Insert: {
          assigned_to?: string | null
          business_id?: string | null
          category?: string
          created_at?: string
          id?: string
          priority?: string
          requester_email?: string | null
          requester_name?: string | null
          status?: string
          subject: string
          updated_at?: string
          user_id?: string | null
        }
        Update: {
          assigned_to?: string | null
          business_id?: string | null
          category?: string
          created_at?: string
          id?: string
          priority?: string
          requester_email?: string | null
          requester_name?: string | null
          status?: string
          subject?: string
          updated_at?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "support_tickets_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "support_tickets_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "support_tickets_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "support_tickets_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      suspended_meal_claims: {
        Row: {
          claimant_user_id: string
          created_at: string
          fulfilled_at: string | null
          handled_at: string | null
          handled_by: string | null
          id: string
          note: string | null
          status: Database["public"]["Enums"]["suspended_claim_status"]
          suspended_meal_id: string
          verify_code: string | null
        }
        Insert: {
          claimant_user_id: string
          created_at?: string
          fulfilled_at?: string | null
          handled_at?: string | null
          handled_by?: string | null
          id?: string
          note?: string | null
          status?: Database["public"]["Enums"]["suspended_claim_status"]
          suspended_meal_id: string
          verify_code?: string | null
        }
        Update: {
          claimant_user_id?: string
          created_at?: string
          fulfilled_at?: string | null
          handled_at?: string | null
          handled_by?: string | null
          id?: string
          note?: string | null
          status?: Database["public"]["Enums"]["suspended_claim_status"]
          suspended_meal_id?: string
          verify_code?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "suspended_meal_claims_suspended_meal_id_fkey"
            columns: ["suspended_meal_id"]
            isOneToOne: false
            referencedRelation: "suspended_meals"
            referencedColumns: ["id"]
          },
        ]
      }
      suspended_meals: {
        Row: {
          amount_cents: number
          business_id: string
          created_at: string
          currency: string
          donor_user_id: string
          expires_at: string
          id: string
          message: string | null
          provider: string | null
          provider_ref: string | null
          status: Database["public"]["Enums"]["suspended_meal_status"]
        }
        Insert: {
          amount_cents: number
          business_id: string
          created_at?: string
          currency?: string
          donor_user_id: string
          expires_at?: string
          id?: string
          message?: string | null
          provider?: string | null
          provider_ref?: string | null
          status?: Database["public"]["Enums"]["suspended_meal_status"]
        }
        Update: {
          amount_cents?: number
          business_id?: string
          created_at?: string
          currency?: string
          donor_user_id?: string
          expires_at?: string
          id?: string
          message?: string | null
          provider?: string | null
          provider_ref?: string | null
          status?: Database["public"]["Enums"]["suspended_meal_status"]
        }
        Relationships: [
          {
            foreignKeyName: "suspended_meals_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "suspended_meals_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "suspended_meals_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "suspended_meals_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      table_feedback: {
        Row: {
          business_id: string
          client_id: string
          created_at: string
          id: string
          note: string | null
          rating: number
          table_no: string
        }
        Insert: {
          business_id: string
          client_id: string
          created_at?: string
          id?: string
          note?: string | null
          rating: number
          table_no: string
        }
        Update: {
          business_id?: string
          client_id?: string
          created_at?: string
          id?: string
          note?: string | null
          rating?: number
          table_no?: string
        }
        Relationships: [
          {
            foreignKeyName: "table_feedback_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "table_feedback_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "table_feedback_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "table_feedback_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      table_orders: {
        Row: {
          business_id: string
          created_at: string
          customer_note: string | null
          done_at: string | null
          id: string
          items_json: Json
          seen_at: string | null
          status: string
          table_number: string
        }
        Insert: {
          business_id: string
          created_at?: string
          customer_note?: string | null
          done_at?: string | null
          id?: string
          items_json?: Json
          seen_at?: string | null
          status?: string
          table_number: string
        }
        Update: {
          business_id?: string
          created_at?: string
          customer_note?: string | null
          done_at?: string | null
          id?: string
          items_json?: Json
          seen_at?: string | null
          status?: string
          table_number?: string
        }
        Relationships: [
          {
            foreignKeyName: "table_orders_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "table_orders_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "table_orders_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "table_orders_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      temp_uploads: {
        Row: {
          business_id: string
          bytes: number | null
          created_at: string
          duplicate_candidate: boolean
          expires_at: string
          height: number | null
          id: string
          kind: string
          mime_type: string | null
          phash: string | null
          review_id: string | null
          review_note: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          sha1: string | null
          status: string
          storage_bucket: string
          storage_path: string
          user_id: string | null
          width: number | null
        }
        Insert: {
          business_id: string
          bytes?: number | null
          created_at?: string
          duplicate_candidate?: boolean
          expires_at?: string
          height?: number | null
          id?: string
          kind: string
          mime_type?: string | null
          phash?: string | null
          review_id?: string | null
          review_note?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          sha1?: string | null
          status?: string
          storage_bucket?: string
          storage_path: string
          user_id?: string | null
          width?: number | null
        }
        Update: {
          business_id?: string
          bytes?: number | null
          created_at?: string
          duplicate_candidate?: boolean
          expires_at?: string
          height?: number | null
          id?: string
          kind?: string
          mime_type?: string | null
          phash?: string | null
          review_id?: string | null
          review_note?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          sha1?: string | null
          status?: string
          storage_bucket?: string
          storage_path?: string
          user_id?: string | null
          width?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "temp_uploads_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "temp_uploads_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "temp_uploads_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "temp_uploads_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "temp_uploads_review_id_fkey"
            columns: ["review_id"]
            isOneToOne: false
            referencedRelation: "business_reviews"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "temp_uploads_review_id_fkey"
            columns: ["review_id"]
            isOneToOne: false
            referencedRelation: "review_ratings"
            referencedColumns: ["review_id"]
          },
          {
            foreignKeyName: "temp_uploads_review_id_fkey"
            columns: ["review_id"]
            isOneToOne: false
            referencedRelation: "reviews"
            referencedColumns: ["id"]
          },
        ]
      }
      user_achievement_awards: {
        Row: {
          achievement_id: string
          award_date: string
          awarded_at: string
          meta: Json
          user_id: string
        }
        Insert: {
          achievement_id: string
          award_date?: string
          awarded_at?: string
          meta?: Json
          user_id: string
        }
        Update: {
          achievement_id?: string
          award_date?: string
          awarded_at?: string
          meta?: Json
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_achievement_awards_achievement_id_fkey"
            columns: ["achievement_id"]
            isOneToOne: false
            referencedRelation: "achievements"
            referencedColumns: ["id"]
          },
        ]
      }
      user_achievements: {
        Row: {
          achievement_id: string
          meta: Json
          unlocked_at: string
          user_id: string
        }
        Insert: {
          achievement_id: string
          meta?: Json
          unlocked_at?: string
          user_id: string
        }
        Update: {
          achievement_id?: string
          meta?: Json
          unlocked_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_achievements_achievement_id_fkey"
            columns: ["achievement_id"]
            isOneToOne: false
            referencedRelation: "achievements"
            referencedColumns: ["id"]
          },
        ]
      }
      user_collection_follows: {
        Row: {
          collection_key: string
          created_at: string
          user_id: string
        }
        Insert: {
          collection_key: string
          created_at?: string
          user_id: string
        }
        Update: {
          collection_key?: string
          created_at?: string
          user_id?: string
        }
        Relationships: []
      }
      user_device_fingerprints: {
        Row: {
          created_at: string
          fingerprint: string
          last_seen_at: string
          seen_count: number
          user_id: string
        }
        Insert: {
          created_at?: string
          fingerprint: string
          last_seen_at?: string
          seen_count?: number
          user_id: string
        }
        Update: {
          created_at?: string
          fingerprint?: string
          last_seen_at?: string
          seen_count?: number
          user_id?: string
        }
        Relationships: []
      }
      user_devices: {
        Row: {
          app_version: string | null
          created_at: string
          fcm_token: string
          id: string
          last_seen_at: string
          platform: string
          user_id: string
        }
        Insert: {
          app_version?: string | null
          created_at?: string
          fcm_token: string
          id?: string
          last_seen_at?: string
          platform: string
          user_id: string
        }
        Update: {
          app_version?: string | null
          created_at?: string
          fcm_token?: string
          id?: string
          last_seen_at?: string
          platform?: string
          user_id?: string
        }
        Relationships: []
      }
      user_diet_profiles: {
        Row: {
          is_gluten_free: boolean
          is_halal: boolean
          is_lactose_free: boolean
          is_vegan: boolean
          is_vegetarian: boolean
          max_calories: number | null
          updated_at: string
          user_id: string
        }
        Insert: {
          is_gluten_free?: boolean
          is_halal?: boolean
          is_lactose_free?: boolean
          is_vegan?: boolean
          is_vegetarian?: boolean
          max_calories?: number | null
          updated_at?: string
          user_id: string
        }
        Update: {
          is_gluten_free?: boolean
          is_halal?: boolean
          is_lactose_free?: boolean
          is_vegan?: boolean
          is_vegetarian?: boolean
          max_calories?: number | null
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      user_follows: {
        Row: {
          created_at: string
          followee_id: string
          follower_id: string
        }
        Insert: {
          created_at?: string
          followee_id: string
          follower_id: string
        }
        Update: {
          created_at?: string
          followee_id?: string
          follower_id?: string
        }
        Relationships: []
      }
      user_location_prefs: {
        Row: {
          city: string | null
          district: string | null
          mode: string
          neighborhood: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          city?: string | null
          district?: string | null
          mode?: string
          neighborhood?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          city?: string | null
          district?: string | null
          mode?: string
          neighborhood?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      user_mission_claims: {
        Row: {
          created_at: string
          id: string
          mission_id: string
          photo_id: string | null
          status: string
          updated_at: string
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          mission_id: string
          photo_id?: string | null
          status?: string
          updated_at?: string
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          mission_id?: string
          photo_id?: string | null
          status?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_mission_claims_mission_id_fkey"
            columns: ["mission_id"]
            isOneToOne: false
            referencedRelation: "photo_missions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_mission_claims_photo_id_fkey"
            columns: ["photo_id"]
            isOneToOne: false
            referencedRelation: "menu_item_photos"
            referencedColumns: ["id"]
          },
        ]
      }
      user_moderation_strikes: {
        Row: {
          created_at: string
          id: string
          reason: string | null
          source: string | null
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          reason?: string | null
          source?: string | null
          user_id: string
        }
        Update: {
          created_at?: string
          id?: string
          reason?: string | null
          source?: string | null
          user_id?: string
        }
        Relationships: []
      }
      user_points: {
        Row: {
          points: number
          updated_at: string
          user_id: string
        }
        Insert: {
          points?: number
          updated_at?: string
          user_id: string
        }
        Update: {
          points?: number
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      user_policy_acceptances: {
        Row: {
          accepted_at: string
          created_at: string
          id: string
          ip_address: unknown
          policy_version_id: string
          source_app: string
          user_agent: string | null
          user_id: string
        }
        Insert: {
          accepted_at?: string
          created_at?: string
          id?: string
          ip_address?: unknown
          policy_version_id: string
          source_app: string
          user_agent?: string | null
          user_id: string
        }
        Update: {
          accepted_at?: string
          created_at?: string
          id?: string
          ip_address?: unknown
          policy_version_id?: string
          source_app?: string
          user_agent?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_policy_acceptances_policy_version_id_fkey"
            columns: ["policy_version_id"]
            isOneToOne: false
            referencedRelation: "policy_versions"
            referencedColumns: ["id"]
          },
        ]
      }
      user_profile_progress: {
        Row: {
          level: number
          total_xp: number
          unlocked_count: number
          updated_at: string
          user_id: string
        }
        Insert: {
          level?: number
          total_xp?: number
          unlocked_count?: number
          updated_at?: string
          user_id: string
        }
        Update: {
          level?: number
          total_xp?: number
          unlocked_count?: number
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      user_profiles: {
        Row: {
          avatar_url: string | null
          bio: string | null
          birth_date: string | null
          city: string | null
          created_at: string
          display_name: string
          district: string | null
          gender: string | null
          is_gourmet: boolean
          language_code: string | null
          marketing_email_opt_in: boolean
          marketing_email_opted_in_at: string | null
          owner_onboarding_redirected_at: string | null
          phone: string | null
          referral_code: string | null
          shadow_banned: boolean
          social_links: Json | null
          updated_at: string
          user_id: string
        }
        Insert: {
          avatar_url?: string | null
          bio?: string | null
          birth_date?: string | null
          city?: string | null
          created_at?: string
          display_name: string
          district?: string | null
          gender?: string | null
          is_gourmet?: boolean
          language_code?: string | null
          marketing_email_opt_in?: boolean
          marketing_email_opted_in_at?: string | null
          owner_onboarding_redirected_at?: string | null
          phone?: string | null
          referral_code?: string | null
          shadow_banned?: boolean
          social_links?: Json | null
          updated_at?: string
          user_id: string
        }
        Update: {
          avatar_url?: string | null
          bio?: string | null
          birth_date?: string | null
          city?: string | null
          created_at?: string
          display_name?: string
          district?: string | null
          gender?: string | null
          is_gourmet?: boolean
          language_code?: string | null
          marketing_email_opt_in?: boolean
          marketing_email_opted_in_at?: string | null
          owner_onboarding_redirected_at?: string | null
          phone?: string | null
          referral_code?: string | null
          shadow_banned?: boolean
          social_links?: Json | null
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      user_rate_limits: {
        Row: {
          action: string
          count: number
          day: string
          key: string
          updated_at: string
          user_id: string
        }
        Insert: {
          action: string
          count?: number
          day: string
          key: string
          updated_at?: string
          user_id: string
        }
        Update: {
          action?: string
          count?: number
          day?: string
          key?: string
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      user_referrals: {
        Row: {
          created_at: string
          id: string
          invitee_id: string
          inviter_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          invitee_id: string
          inviter_id: string
        }
        Update: {
          created_at?: string
          id?: string
          invitee_id?: string
          inviter_id?: string
        }
        Relationships: []
      }
      user_risk_signals: {
        Row: {
          created_at: string
          id: number
          ip_hash: string | null
          signal_key: string
          signal_meta: Json
          signal_weight: number
          user_id: string
        }
        Insert: {
          created_at?: string
          id?: number
          ip_hash?: string | null
          signal_key: string
          signal_meta?: Json
          signal_weight?: number
          user_id: string
        }
        Update: {
          created_at?: string
          id?: number
          ip_hash?: string | null
          signal_key?: string
          signal_meta?: Json
          signal_weight?: number
          user_id?: string
        }
        Relationships: []
      }
      user_safety_actions: {
        Row: {
          auto_pending_until: string | null
          last_signal_at: string | null
          risk_score: number
          shadow_banned_until: string | null
          soft_limited_until: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          auto_pending_until?: string | null
          last_signal_at?: string | null
          risk_score?: number
          shadow_banned_until?: string | null
          soft_limited_until?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          auto_pending_until?: string | null
          last_signal_at?: string | null
          risk_score?: number
          shadow_banned_until?: string | null
          soft_limited_until?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: []
      }
      visits: {
        Row: {
          amount_cents: number | null
          business_id: string
          checked_in_at: string | null
          created_at: string
          currency: string | null
          id: string
          note: string | null
          personal_note: string | null
          personal_rating: number | null
          user_id: string
        }
        Insert: {
          amount_cents?: number | null
          business_id: string
          checked_in_at?: string | null
          created_at?: string
          currency?: string | null
          id?: string
          note?: string | null
          personal_note?: string | null
          personal_rating?: number | null
          user_id: string
        }
        Update: {
          amount_cents?: number | null
          business_id?: string
          checked_in_at?: string | null
          created_at?: string
          currency?: string | null
          id?: string
          note?: string | null
          personal_note?: string | null
          personal_rating?: number | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "visits_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "visits_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "visits_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "visits_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      admin_business_suggestions_queue_v1: {
        Row: {
          address: string | null
          category: string | null
          city: string | null
          created_at: string | null
          district: string | null
          id: string | null
          name: string | null
          notes: string | null
          status: string | null
          user_id: string | null
        }
        Insert: {
          address?: string | null
          category?: string | null
          city?: string | null
          created_at?: string | null
          district?: string | null
          id?: string | null
          name?: string | null
          notes?: string | null
          status?: string | null
          user_id?: string | null
        }
        Update: {
          address?: string | null
          category?: string | null
          city?: string | null
          created_at?: string | null
          district?: string | null
          id?: string | null
          name?: string | null
          notes?: string | null
          status?: string | null
          user_id?: string | null
        }
        Relationships: []
      }
      admin_owner_claims_queue_v1: {
        Row: {
          admin_note: string | null
          business_id: string | null
          created_at: string | null
          evidence_url: string | null
          full_name: string | null
          handled_at: string | null
          handled_by: string | null
          id: string | null
          note: string | null
          phone: string | null
          status: string | null
          user_id: string | null
        }
        Insert: {
          admin_note?: string | null
          business_id?: string | null
          created_at?: string | null
          evidence_url?: string | null
          full_name?: string | null
          handled_at?: string | null
          handled_by?: string | null
          id?: string | null
          note?: string | null
          phone?: string | null
          status?: string | null
          user_id?: string | null
        }
        Update: {
          admin_note?: string | null
          business_id?: string | null
          created_at?: string | null
          evidence_url?: string | null
          full_name?: string | null
          handled_at?: string | null
          handled_by?: string | null
          id?: string | null
          note?: string | null
          phone?: string | null
          status?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "owner_claims_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "owner_claims_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "owner_claims_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "owner_claims_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      admin_reports_queue_v1: {
        Row: {
          admin_note: string | null
          business_id: string | null
          created_at: string | null
          details: string | null
          durum: string | null
          handled_at: string | null
          handled_by: string | null
          id: string | null
          reason: string | null
          review_id: string | null
          user_id: string | null
        }
        Insert: {
          admin_note?: string | null
          business_id?: string | null
          created_at?: string | null
          details?: string | null
          durum?: string | null
          handled_at?: string | null
          handled_by?: string | null
          id?: string | null
          reason?: string | null
          review_id?: string | null
          user_id?: string | null
        }
        Update: {
          admin_note?: string | null
          business_id?: string | null
          created_at?: string | null
          details?: string | null
          durum?: string | null
          handled_at?: string | null
          handled_by?: string | null
          id?: string | null
          reason?: string | null
          review_id?: string | null
          user_id?: string | null
        }
        Relationships: []
      }
      admin_suggestions_v1: {
        Row: {
          address: string | null
          admin_note: string | null
          category: string | null
          city: string | null
          created_at: string | null
          district: string | null
          id: string | null
          name: string | null
          notes: string | null
          phone: string | null
          reviewed_at: string | null
          status: string | null
          user_id: string | null
          website: string | null
        }
        Insert: {
          address?: string | null
          admin_note?: string | null
          category?: string | null
          city?: string | null
          created_at?: string | null
          district?: string | null
          id?: string | null
          name?: string | null
          notes?: string | null
          phone?: string | null
          reviewed_at?: string | null
          status?: string | null
          user_id?: string | null
          website?: string | null
        }
        Update: {
          address?: string | null
          admin_note?: string | null
          category?: string | null
          city?: string | null
          created_at?: string | null
          district?: string | null
          id?: string | null
          name?: string | null
          notes?: string | null
          phone?: string | null
          reviewed_at?: string | null
          status?: string | null
          user_id?: string | null
          website?: string | null
        }
        Relationships: []
      }
      business_claims: {
        Row: {
          admin_note: string | null
          assigned_at: string | null
          assigned_to: string | null
          auto_moderated: boolean | null
          business_id: string | null
          created_at: string | null
          evidence_url: string | null
          full_name: string | null
          handled_at: string | null
          handled_by: string | null
          id: string | null
          note: string | null
          phone: string | null
          reviewed_at: string | null
          status: string | null
          user_id: string | null
        }
        Insert: {
          admin_note?: string | null
          assigned_at?: string | null
          assigned_to?: string | null
          auto_moderated?: boolean | null
          business_id?: string | null
          created_at?: string | null
          evidence_url?: string | null
          full_name?: string | null
          handled_at?: string | null
          handled_by?: string | null
          id?: string | null
          note?: string | null
          phone?: string | null
          reviewed_at?: string | null
          status?: string | null
          user_id?: string | null
        }
        Update: {
          admin_note?: string | null
          assigned_at?: string | null
          assigned_to?: string | null
          auto_moderated?: boolean | null
          business_id?: string | null
          created_at?: string | null
          evidence_url?: string | null
          full_name?: string | null
          handled_at?: string | null
          handled_by?: string | null
          id?: string | null
          note?: string | null
          phone?: string | null
          reviewed_at?: string | null
          status?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "owner_claims_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "owner_claims_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "owner_claims_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "owner_claims_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      business_item_trends_v1: {
        Row: {
          business_id: string | null
          menu_item_id: string | null
          menu_item_views_7d: number | null
          photo_votes_7d: number | null
          price_changes_7d: number | null
          price_votes_7d: number | null
          score: number | null
        }
        Relationships: [
          {
            foreignKeyName: "menu_items_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "menu_items_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_items_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_items_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      business_price_index_v1: {
        Row: {
          business_id: string | null
          last_update_at: string | null
          median_price_cents: number | null
          verified_ratio: number | null
        }
        Relationships: [
          {
            foreignKeyName: "menu_items_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "menu_items_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_items_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_items_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      business_quality_score_v1: {
        Row: {
          amenities_count: number | null
          amenities_points: number | null
          business_id: string | null
          has_fee_flags: boolean | null
          has_pricing_rule: boolean | null
          last_menu_update_at: string | null
          photos_count: number | null
          photos_points: number | null
          pricing_points: number | null
          recency_points: number | null
          score: number | null
          total_items: number | null
          verified_items: number | null
          verified_points: number | null
          weekly_verified_votes: number | null
        }
        Relationships: []
      }
      business_rating_summary: {
        Row: {
          avg_atmosphere_rating: number | null
          avg_cleanliness_rating: number | null
          avg_overall_rating: number | null
          avg_price_performance_rating: number | null
          avg_service_speed_rating: number | null
          avg_taste_rating: number | null
          business_id: string | null
          rating_count: number | null
        }
        Relationships: [
          {
            foreignKeyName: "reviews_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "reviews_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reviews_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reviews_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      business_reviews: {
        Row: {
          atmosphere_rating: number | null
          business_id: string | null
          cleanliness_rating: number | null
          content: string | null
          created_at: string | null
          helpful_count: number | null
          id: string | null
          overall_rating: number | null
          owner_replied_at: string | null
          owner_reply: string | null
          price_performance_rating: number | null
          rating: number | null
          service_speed_rating: number | null
          status: string | null
          taste_rating: number | null
          title: string | null
          user_id: string | null
        }
        Insert: {
          atmosphere_rating?: number | null
          business_id?: string | null
          cleanliness_rating?: number | null
          content?: string | null
          created_at?: string | null
          helpful_count?: number | null
          id?: string | null
          overall_rating?: number | null
          owner_replied_at?: string | null
          owner_reply?: string | null
          price_performance_rating?: number | null
          rating?: number | null
          service_speed_rating?: number | null
          status?: string | null
          taste_rating?: number | null
          title?: string | null
          user_id?: string | null
        }
        Update: {
          atmosphere_rating?: number | null
          business_id?: string | null
          cleanliness_rating?: number | null
          content?: string | null
          created_at?: string | null
          helpful_count?: number | null
          id?: string | null
          overall_rating?: number | null
          owner_replied_at?: string | null
          owner_reply?: string | null
          price_performance_rating?: number | null
          rating?: number | null
          service_speed_rating?: number | null
          status?: string | null
          taste_rating?: number | null
          title?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "reviews_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "reviews_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reviews_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reviews_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      businesses_with_stats: {
        Row: {
          address: string | null
          avg_rating: number | null
          category: string | null
          city: string | null
          created_at: string | null
          description: string | null
          district: string | null
          id: string | null
          is_active: boolean | null
          is_verified: boolean | null
          lat: number | null
          lng: number | null
          name: string | null
          phone: string | null
          reviews_count: number | null
        }
        Relationships: []
      }
      businesses_with_stats_mv: {
        Row: {
          address: string | null
          avg_rating: number | null
          category: string | null
          city: string | null
          district: string | null
          geog: unknown
          id: string | null
          last_review_at: string | null
          lat: number | null
          lng: number | null
          name: string | null
          reviews_count: number | null
        }
        Relationships: []
      }
      crowd_checkins: {
        Row: {
          business_id: string | null
          checked_in_at: string | null
          id: string | null
          user_id: string | null
        }
        Insert: {
          business_id?: string | null
          checked_in_at?: never
          id?: string | null
          user_id?: string | null
        }
        Update: {
          business_id?: string | null
          checked_in_at?: never
          id?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "visits_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "visits_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "visits_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "visits_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      expired_temp_uploads_v1: {
        Row: {
          business_id: string | null
          bytes: number | null
          created_at: string | null
          duplicate_candidate: boolean | null
          expires_at: string | null
          height: number | null
          id: string | null
          kind: string | null
          mime_type: string | null
          phash: string | null
          review_note: string | null
          reviewed_at: string | null
          reviewed_by: string | null
          sha1: string | null
          status: string | null
          storage_bucket: string | null
          storage_path: string | null
          user_id: string | null
          width: number | null
        }
        Insert: {
          business_id?: string | null
          bytes?: number | null
          created_at?: string | null
          duplicate_candidate?: boolean | null
          expires_at?: string | null
          height?: number | null
          id?: string | null
          kind?: string | null
          mime_type?: string | null
          phash?: string | null
          review_note?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          sha1?: string | null
          status?: string | null
          storage_bucket?: string | null
          storage_path?: string | null
          user_id?: string | null
          width?: number | null
        }
        Update: {
          business_id?: string | null
          bytes?: number | null
          created_at?: string | null
          duplicate_candidate?: boolean | null
          expires_at?: string | null
          height?: number | null
          id?: string | null
          kind?: string | null
          mime_type?: string | null
          phash?: string | null
          review_note?: string | null
          reviewed_at?: string | null
          reviewed_by?: string | null
          sha1?: string | null
          status?: string | null
          storage_bucket?: string | null
          storage_path?: string | null
          user_id?: string | null
          width?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "temp_uploads_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "temp_uploads_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "temp_uploads_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "temp_uploads_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      geography_columns: {
        Row: {
          coord_dimension: number | null
          f_geography_column: unknown
          f_table_catalog: unknown
          f_table_name: unknown
          f_table_schema: unknown
          srid: number | null
          type: string | null
        }
        Relationships: []
      }
      geometry_columns: {
        Row: {
          coord_dimension: number | null
          f_geometry_column: unknown
          f_table_catalog: string | null
          f_table_name: unknown
          f_table_schema: unknown
          srid: number | null
          type: string | null
        }
        Insert: {
          coord_dimension?: number | null
          f_geometry_column?: unknown
          f_table_catalog?: string | null
          f_table_name?: unknown
          f_table_schema?: unknown
          srid?: number | null
          type?: string | null
        }
        Update: {
          coord_dimension?: number | null
          f_geometry_column?: unknown
          f_table_catalog?: string | null
          f_table_name?: unknown
          f_table_schema?: unknown
          srid?: number | null
          type?: string | null
        }
        Relationships: []
      }
      menu_item_price_status_v1: {
        Row: {
          business_id: string | null
          down_30d: number | null
          menu_item_id: string | null
          price_status: string | null
          total_30d: number | null
          up_30d: number | null
        }
        Relationships: [
          {
            foreignKeyName: "menu_items_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "business_quality_score_v1"
            referencedColumns: ["business_id"]
          },
          {
            foreignKeyName: "menu_items_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_items_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "menu_items_business_id_fkey"
            columns: ["business_id"]
            isOneToOne: false
            referencedRelation: "businesses_with_stats_mv"
            referencedColumns: ["id"]
          },
        ]
      }
      menu_item_value_score_v1: {
        Row: {
          menu_item_id: string | null
          price_changes_30d: number | null
          price_stability: number | null
          recent_positive_ratio: number | null
          value_score: number | null
          verified_ratio: number | null
        }
        Relationships: []
      }
      price_verifications: {
        Row: {
          created_at: string | null
          user_id: string | null
        }
        Insert: {
          created_at?: string | null
          user_id?: string | null
        }
        Update: {
          created_at?: string | null
          user_id?: string | null
        }
        Relationships: []
      }
      profiles: {
        Row: {
          avatar_url: string | null
          bio: string | null
          display_name: string | null
          email: string | null
          id: string | null
          is_gourmet: boolean | null
        }
        Insert: {
          avatar_url?: string | null
          bio?: string | null
          display_name?: string | null
          email?: never
          id?: string | null
          is_gourmet?: boolean | null
        }
        Update: {
          avatar_url?: string | null
          bio?: string | null
          display_name?: string | null
          email?: never
          id?: string | null
          is_gourmet?: boolean | null
        }
        Relationships: []
      }
      review_ratings: {
        Row: {
          r_atmosphere: number | null
          r_cleanliness: number | null
          r_price_value: number | null
          r_service: number | null
          r_taste: number | null
          review_id: string | null
        }
        Insert: {
          r_atmosphere?: number | null
          r_cleanliness?: number | null
          r_price_value?: number | null
          r_service?: number | null
          r_taste?: number | null
          review_id?: string | null
        }
        Update: {
          r_atmosphere?: number | null
          r_cleanliness?: number | null
          r_price_value?: number | null
          r_service?: number | null
          r_taste?: number | null
          review_id?: string | null
        }
        Relationships: []
      }
      user_business_signals_v1: {
        Row: {
          business_id: string | null
          signal_score: number | null
          user_id: string | null
        }
        Relationships: []
      }
    }
    Functions: {
      _allocate_business_slug_token_v1: {
        Args: { current_business_id: string; desired: string }
        Returns: string
      }
      _award_loyalty_progress: {
        Args: {
          p_amount: number
          p_business_id: string
          p_source: string
          p_user_id: string
        }
        Returns: undefined
      }
      _check_plan_limit_v1: {
        Args: { p_business_id: string; p_feature_key: string }
        Returns: undefined
      }
      _get_business_plan_tier_v1: {
        Args: { p_business_id: string }
        Returns: string
      }
      _increment_plan_usage_v1: {
        Args: { p_business_id: string; p_feature_key: string }
        Returns: undefined
      }
      _is_approved_owner_of_business: {
        Args: { p_business_id: string }
        Returns: boolean
      }
      _normalize_public_slug_v1: { Args: { input: string }; Returns: string }
      _normalize_tr_match: { Args: { p: string }; Returns: string }
      _postgis_deprecate: {
        Args: { newname: string; oldname: string; version: string }
        Returns: undefined
      }
      _postgis_index_extent: {
        Args: { col: string; tbl: unknown }
        Returns: unknown
      }
      _postgis_pgsql_version: { Args: never; Returns: string }
      _postgis_scripts_pgsql_version: { Args: never; Returns: string }
      _postgis_selectivity: {
        Args: { att_name: string; geom: unknown; mode?: string; tbl: unknown }
        Returns: number
      }
      _postgis_stats: {
        Args: { ""?: string; att_name: string; tbl: unknown }
        Returns: string
      }
      _resolve_chain_business_ids_v1: {
        Args: { p_business_id: string }
        Returns: string[]
      }
      _resolve_loyalty_program_v1: {
        Args: { p_business_id: string }
        Returns: string
      }
      _review_verified_visit: {
        Args: {
          p_business_id: string
          p_review_date: string
          p_user_id: string
        }
        Returns: boolean
      }
      _st_3dintersects: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_contains: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_containsproperly: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_coveredby:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      _st_covers:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      _st_crosses: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_dwithin: {
        Args: {
          geog1: unknown
          geog2: unknown
          tolerance: number
          use_spheroid?: boolean
        }
        Returns: boolean
      }
      _st_equals: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      _st_intersects: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_linecrossingdirection: {
        Args: { line1: unknown; line2: unknown }
        Returns: number
      }
      _st_longestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      _st_maxdistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      _st_orderingequals: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_overlaps: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_sortablehash: { Args: { geom: unknown }; Returns: number }
      _st_touches: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      _st_voronoi: {
        Args: {
          clip?: unknown
          g1: unknown
          return_polygons?: boolean
          tolerance?: number
        }
        Returns: unknown
      }
      _st_within: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      _sync_plan_sponsorship_v1: {
        Args: { p_business_id: string; p_ends_at: string; p_plan_tier: string }
        Returns: undefined
      }
      _variant_item_owner_check: {
        Args: { p_item_id: string }
        Returns: boolean
      }
      accept_group_offer_v1: { Args: { p_offer_id: string }; Returns: Json }
      add_business_media_v1: {
        Args: {
          p_business_id: string
          p_kind?: string
          p_provider?: string
          p_url: string
          p_url_large?: string
          p_url_thumb?: string
        }
        Returns: Json
      }
      add_customer_note_v1: {
        Args: { p_business_id: string; p_note: string; p_user_id: string }
        Returns: string
      }
      add_customer_tag_v1: {
        Args: { p_business_id: string; p_tag: string; p_user_id: string }
        Returns: string
      }
      add_menu_item_photo_v1: {
        Args: {
          p_menu_item_id: string
          p_provider?: string
          p_url: string
          p_url_large?: string
          p_url_thumb?: string
        }
        Returns: Json
      }
      add_moderation_strike_v1: {
        Args: { p_reason?: string; p_source?: string; p_user_id: string }
        Returns: Json
      }
      add_to_collection_v1: {
        Args: {
          p_business_id: string
          p_collection_id: string
          p_note?: string
        }
        Returns: Json
      }
      addauth: { Args: { "": string }; Returns: boolean }
      addgeometrycolumn:
        | {
            Args: {
              catalog_name: string
              column_name: string
              new_dim: number
              new_srid_in: number
              new_type: string
              schema_name: string
              table_name: string
              use_typmod?: boolean
            }
            Returns: string
          }
        | {
            Args: {
              column_name: string
              new_dim: number
              new_srid: number
              new_type: string
              schema_name: string
              table_name: string
              use_typmod?: boolean
            }
            Returns: string
          }
        | {
            Args: {
              column_name: string
              new_dim: number
              new_srid: number
              new_type: string
              table_name: string
              use_typmod?: boolean
            }
            Returns: string
          }
      admin_apply_user_safety_action_v1: {
        Args: {
          p_action: string
          p_minutes?: number
          p_reason?: string
          p_user_id: string
        }
        Returns: Json
      }
      admin_approve_business_submission_v1: {
        Args: { p_submission_id: string }
        Returns: Json
      }
      admin_approve_business_suggestion_v1: {
        Args: { p_admin_note?: string; p_suggestion_id: string }
        Returns: Json
      }
      admin_approve_menu_price_suggestion_v1: {
        Args: { p_suggestion_id: string }
        Returns: Json
      }
      admin_approve_mission_claim_v1: {
        Args: { p_claim_id: string }
        Returns: Json
      }
      admin_approve_price_suggestion_v1: {
        Args: { p_suggestion_id: string }
        Returns: Json
      }
      admin_approve_suspended_claim_v1: {
        Args: { p_claim_id: string }
        Returns: Json
      }
      admin_assign_business_suggestion_v1: {
        Args: { p_suggestion_id: string }
        Returns: Json
      }
      admin_assign_business_to_chain_v1: {
        Args: {
          p_branch_label?: string
          p_business_id: string
          p_chain_id: string
          p_set_as_template?: boolean
        }
        Returns: Json
      }
      admin_assign_owner_claim_v1: {
        Args: { p_claim_id: string }
        Returns: Json
      }
      admin_assign_report_v1: { Args: { p_report_id: string }; Returns: Json }
      admin_bulk_decide_owner_claims_v1: {
        Args: { p_claim_ids: string[]; p_decision: string; p_note?: string }
        Returns: Json
      }
      admin_bulk_reject_business_suggestions_v1: {
        Args: { p_admin_note?: string; p_suggestion_ids: string[] }
        Returns: Json
      }
      admin_bulk_replace_preview_v1: {
        Args: {
          p_case_insensitive?: boolean
          p_column: string
          p_from: string
          p_table: string
        }
        Returns: Json
      }
      admin_bulk_replace_text_v1: {
        Args: {
          p_case_insensitive?: boolean
          p_column: string
          p_from: string
          p_table: string
          p_to: string
        }
        Returns: Json
      }
      admin_bulk_replace_url_prefix_v1: {
        Args: { p_field: string; p_from_prefix: string; p_to_prefix: string }
        Returns: Json
      }
      admin_bulk_update_reports_status_v2: {
        Args: {
          p_admin_note?: string
          p_report_ids: string[]
          p_status: string
        }
        Returns: Json
      }
      admin_create_chain_v1: {
        Args: {
          p_category?: string
          p_cover_url?: string
          p_description?: string
          p_logo_url?: string
          p_name: string
          p_slug?: string
          p_website?: string
        }
        Returns: Json
      }
      admin_create_incident_update_v1: {
        Args: {
          p_action_taken: string
          p_incident_key: string
          p_status?: string
          p_summary: string
          p_title: string
          p_visibility?: string
        }
        Returns: string
      }
      admin_create_sponsorship_v1: {
        Args: {
          p_business_id: string
          p_daily_cap?: number
          p_ends_at?: string
          p_package_id: string
          p_starts_at?: string
          p_surface: string
          p_targeting?: Json
          p_total_cap?: number
        }
        Returns: Json
      }
      admin_decide_moderation_appeal_v1: {
        Args: { p_appeal_id: string; p_decision: string; p_note?: string }
        Returns: Json
      }
      admin_decide_owner_claim_v1: {
        Args: { p_claim_id: string; p_decision: string; p_note?: string }
        Returns: undefined
      }
      admin_export_anonymous_trends_csv_v1: {
        Args: { p_days?: number }
        Returns: string
      }
      admin_export_business_suggestions_csv_v1: {
        Args: { p_q?: string; p_status?: string }
        Returns: string
      }
      admin_export_menu_inflation_csv_v1: {
        Args: { p_days?: number }
        Returns: string
      }
      admin_export_menu_price_suggestions_csv_v1: {
        Args: { p_assigned?: string; p_sla_only?: boolean; p_status?: string }
        Returns: string
      }
      admin_export_owner_claims_csv_v1: {
        Args: { p_q?: string; p_status?: string }
        Returns: string
      }
      admin_export_price_anomalies_csv_v1: {
        Args: { p_days?: number; p_threshold_pct?: number }
        Returns: string
      }
      admin_export_regional_price_index_csv_v1: {
        Args: { p_days?: number }
        Returns: string
      }
      admin_export_reports_csv_v1: {
        Args: { p_q?: string; p_status?: string }
        Returns: string
      }
      admin_export_suspended_claims_csv_v1: {
        Args: { p_sla_only?: boolean; p_status?: string }
        Returns: string
      }
      admin_find_duplicate_businesses_v1: {
        Args: { p_suggestion_id: string; p_threshold?: number }
        Returns: {
          address: string
          business_id: string
          city: string
          district: string
          name: string
          score: number
        }[]
      }
      admin_get_chain_detail_v1: {
        Args: { p_chain_id: string }
        Returns: {
          branch_label: string
          business_id: string
          business_name: string
          chain_category: string
          chain_cover_url: string
          chain_description: string
          chain_id: string
          chain_is_verified: boolean
          chain_logo_url: string
          chain_name: string
          chain_slug: string
          chain_website: string
          city: string
          district: string
          is_active: boolean
          is_template: boolean
          template_business_id: string
        }[]
      }
      admin_get_offline_mutation_alert_settings_v1: {
        Args: never
        Returns: Json
      }
      admin_get_overview_stats_v1: { Args: never; Returns: Json }
      admin_get_queues_counts_v1: { Args: never; Returns: Json }
      admin_get_receipt_submission_summary_v1: {
        Args: {
          p_only_unmatched?: boolean
          p_query?: string
          p_review_status?: string
        }
        Returns: {
          business_count: number
          needs_followup_count: number
          pending_count: number
          recent_24h_count: number
          reviewed_count: number
          total_count: number
          zero_match_count: number
        }[]
      }
      admin_get_sponsorship_summary_v1: {
        Args: never
        Returns: {
          active_sponsorships: number
          estimated_active_revenue_cents: number
          impressions_30d: number
          open_leads: number
          pending_sponsorships: number
          unique_users_30d: number
        }[]
      }
      admin_kpi_summary_v1: {
        Args: { p_days?: number }
        Returns: {
          business_views: number
          business_views_prev: number
          dau: number
          dau_prev: number
          discovery_clicks: number
          discovery_clicks_prev: number
          discovery_ctr: number
          discovery_ctr_prev: number
          discovery_impressions: number
          discovery_impressions_prev: number
          menu_view_rate: number
          menu_view_rate_prev: number
          menu_views: number
          menu_views_prev: number
          price_suggestions: number
          price_suggestions_prev: number
          price_verification_rate: number
          price_verification_rate_prev: number
          reports_avg_resolution_minutes: number
          reports_avg_resolution_minutes_prev: number
          wau: number
          wau_prev: number
        }[]
      }
      admin_link_suggestion_to_business_v1: {
        Args: {
          p_admin_note?: string
          p_business_id: string
          p_suggestion_id: string
        }
        Returns: Json
      }
      admin_list_business_submissions_v1: {
        Args: { p_limit?: number; p_offset?: number; p_status?: string }
        Returns: {
          address: string
          admin_note: string
          category: string
          city: string
          created_at: string
          district: string
          id: string
          name: string
          phone: string
          status: string
          submitted_by: string
          website: string
        }[]
      }
      admin_list_business_submissions_v2: {
        Args: {
          p_date_from?: string
          p_date_to?: string
          p_limit?: number
          p_offset?: number
          p_q?: string
          p_sort_ascending?: boolean
          p_sort_key?: string
          p_status?: string
        }
        Returns: {
          address: string
          admin_note: string
          category: string
          city: string
          created_at: string
          district: string
          id: string
          name: string
          phone: string
          status: string
          submitted_by: string
          total_count: number
          website: string
        }[]
      }
      admin_list_business_suggestions_v1: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_q?: string
          p_status?: string
        }
        Returns: {
          address: string
          admin_note: string
          approved_business_id: string
          category: string
          city: string
          created_at: string
          district: string
          handled_at: string
          handled_by: string
          id: string
          name: string
          notes: string
          status: string
          user_id: string
        }[]
      }
      admin_list_business_suggestions_v3: {
        Args: {
          p_assigned?: string
          p_limit?: number
          p_offset?: number
          p_q?: string
          p_sla_only?: boolean
          p_status?: string
        }
        Returns: {
          address: string
          admin_note: string
          age_days: number
          approved_business_id: string
          assigned_at: string
          assigned_to: string
          category: string
          city: string
          created_at: string
          district: string
          handled_at: string
          handled_by: string
          id: string
          name: string
          notes: string
          sla_breached: boolean
          status: string
          user_id: string
        }[]
      }
      admin_list_businesses_v1: {
        Args: {
          p_city?: string
          p_district?: string
          p_limit?: number
          p_offset?: number
          p_q?: string
        }
        Returns: {
          address: string
          category: string
          city: string
          cover_url: string
          created_at: string
          district: string
          id: string
          lat: number
          lng: number
          logo_url: string
          name: string
        }[]
      }
      admin_list_chains_v1: {
        Args: { p_limit?: number; p_offset?: number; p_q?: string }
        Returns: {
          branch_count: number
          category: string
          created_at: string
          id: string
          is_verified: boolean
          logo_url: string
          name: string
          slug: string
          template_business_id: string
          template_business_name: string
        }[]
      }
      admin_list_incident_updates_v1: {
        Args: { p_limit?: number }
        Returns: {
          action_taken: string
          created_at: string
          created_by: string
          id: string
          incident_key: string
          status: string
          summary: string
          title: string
          visibility: string
        }[]
      }
      admin_list_menu_price_suggestions_v1: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_sla_only?: boolean
          p_status?: string
        }
        Returns: {
          business_id: string
          business_name: string
          city: string
          created_at: string
          created_by: string
          currency: string
          current_price_cents: number
          district: string
          item_name: string
          menu_item_id: string
          sla_breached: boolean
          status: string
          suggested_price_cents: number
          suggestion_id: string
        }[]
      }
      admin_list_menu_price_suggestions_v2: {
        Args: {
          p_assigned?: string
          p_limit?: number
          p_offset?: number
          p_sla_only?: boolean
          p_status?: string
        }
        Returns: {
          anomaly_flags: Json
          anomaly_score: number
          assigned_at: string
          assigned_to: string
          business_id: string
          business_name: string
          city: string
          conflict_state: string
          conflict_variants_24h: number
          created_at: string
          created_by: string
          currency: string
          current_price_cents: number
          district: string
          item_name: string
          menu_item_id: string
          quality_confidence: number
          sla_breached: boolean
          status: string
          suggested_price_cents: number
          suggestion_id: string
        }[]
      }
      admin_list_mission_claims_v1: {
        Args: { p_limit?: number; p_offset?: number; p_status?: string }
        Returns: {
          business_id: string
          business_name: string
          claim_id: string
          created_at: string
          mission_id: string
          mission_type: string
          photo_id: string
          reward_points: number
          status: string
          user_id: string
        }[]
      }
      admin_list_moderation_appeals_v1: {
        Args: { p_limit?: number; p_offset?: number; p_status?: string }
        Returns: {
          appeal_id: string
          appellant_user_id: string
          created_at: string
          decided_at: string
          decided_by: string
          decision_note: string
          details: string
          reason: string
          source_id: string
          source_type: string
          status: string
        }[]
      }
      admin_list_offline_mutation_outcomes_v1: {
        Args: { p_hours?: number; p_limit?: number }
        Returns: {
          client_id: string
          created_at: string
          detail: string
          disposition: string
          kind: string
          retry_category: string
          retry_count: number
          source: string
          user_id: string
        }[]
      }
      admin_list_owner_claims_v1: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_q?: string
          p_status?: string
        }
        Returns: {
          admin_note: string
          business_id: string
          created_at: string
          evidence_url: string
          full_name: string
          handled_at: string
          handled_by: string
          id: string
          note: string
          phone: string
          status: string
          user_id: string
        }[]
      }
      admin_list_owner_claims_v3: {
        Args: {
          p_assigned?: string
          p_limit?: number
          p_offset?: number
          p_q?: string
          p_sla_only?: boolean
          p_status?: string
        }
        Returns: {
          admin_note: string
          age_days: number
          assigned_at: string
          assigned_to: string
          auto_moderated: boolean
          business_id: string
          claim_id: string
          created_at: string
          evidence_url: string
          full_name: string
          note: string
          phone: string
          sla_breached: boolean
          status: string
        }[]
      }
      admin_list_receipt_submission_batch_opportunities_v1: {
        Args: { p_limit?: number }
        Returns: {
          business_id: string
          business_name: string
          chain_id: string
          chain_name: string
          last_submitted_at: string
          pending_count: number
          zero_match_count: number
        }[]
      }
      admin_list_receipt_submission_matches_v1: {
        Args: { p_receipt_id: string }
        Returns: {
          current_price_cents: number
          delta_cents: number
          detected_price_cents: number
          item_name: string
          menu_item_id: string
        }[]
      }
      admin_list_receipt_submissions_v1: {
        Args: { p_limit?: number; p_offset?: number }
        Returns: {
          business_id: string
          business_name: string
          created_at: string
          image_url: string
          matches_count: number
          receipt_id: string
          user_id: string
        }[]
      }
      admin_list_receipt_submissions_v2: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_only_unmatched?: boolean
          p_query?: string
          p_review_status?: string
        }
        Returns: {
          business_id: string
          business_name: string
          chain_id: string
          chain_name: string
          city: string
          created_at: string
          district: string
          image_url: string
          matches_count: number
          receipt_id: string
          review_note: string
          review_status: string
          reviewed_at: string
          reviewed_by: string
          user_id: string
        }[]
      }
      admin_list_reports_v5: {
        Args: {
          p_assigned?: string
          p_limit?: number
          p_offset?: number
          p_q?: string
          p_sla_only?: boolean
          p_status?: string
        }
        Returns: {
          admin_note: string
          age_hours: number
          assigned_at: string
          assigned_to: string
          business_id: string
          created_at: string
          details: string
          handled_at: string
          handled_by: string
          id: string
          menu_item_photo_id: string
          reason: string
          review_id: string
          sla_breached: boolean
          status: string
          target_id: string
          target_type: string
          user_id: string
        }[]
      }
      admin_list_risky_users_v1: {
        Args: { p_limit?: number; p_min_score?: number; p_offset?: number }
        Returns: {
          auto_pending_until: string
          device_change_hits: number
          duplicate_text_hits: number
          last_signal_at: string
          new_account_hits: number
          recommended_action: string
          risk_score: number
          same_ip_hits: number
          shadow_banned_until: string
          signal_count: number
          soft_limited_until: string
          user_id: string
        }[]
      }
      admin_list_sponsorship_inventory_v1: {
        Args: never
        Returns: {
          active_packages: number
          estimated_active_revenue_cents: number
          impressions_30d: number
          inventory_limit: number
          live_units: number
          open_inventory_slots: number
          open_leads: number
          pending_sponsorships: number
          surface: string
          total_packages: number
          unique_users_30d: number
        }[]
      }
      admin_list_sponsorship_leads_v1: {
        Args: { p_limit?: number; p_offset?: number; p_status?: string }
        Returns: {
          business_id: string
          business_name: string
          city: string
          created_at: string
          district: string
          lead_id: string
          message: string
          owner_user_id: string
          phone: string
          preferred_surface: string
          preferred_targeting: Json
          status: string
        }[]
      }
      admin_list_sponsorships_v1: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_status?: string
          p_surface?: string
        }
        Returns: {
          business_id: string
          business_name: string
          city: string
          created_at: string
          created_by: string
          daily_cap: number
          district: string
          ends_at: string
          package_id: string
          source: string
          sponsorship_id: string
          starts_at: string
          status: string
          surface: string
          total_cap: number
        }[]
      }
      admin_list_suspended_claims_v1: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_sla_only?: boolean
          p_status?: string
        }
        Returns: {
          business_id: string
          business_name: string
          city: string
          claim_created_at: string
          claim_id: string
          claim_status: string
          claimant_name: string
          claimant_user_id: string
          district: string
          meal_amount_cents: number
          meal_created_at: string
          meal_currency: string
          meal_id: string
          meal_message: string
          sla_breached: boolean
        }[]
      }
      admin_list_table_feedback_v1: {
        Args: { p_limit?: number; p_offset?: number }
        Returns: {
          business_id: string
          business_name: string
          client_id: string
          created_at: string
          note: string
          rating: number
          table_no: string
        }[]
      }
      admin_list_user_business_access_v1: {
        Args: {
          p_limit?: number
          p_offset?: number
          p_role_override?: string
          p_user_id: string
        }
        Returns: {
          branch_label: string
          business_id: string
          business_name: string
          chain_id: string
          chain_name: string
          city: string
          claim_status: string
          claimed_at: string
          district: string
          owner_role: string
        }[]
      }
      admin_log_impersonation_v1: {
        Args: {
          p_action: string
          p_meta?: Json
          p_role_override?: string
          p_target_user_id: string
        }
        Returns: Json
      }
      admin_merge_businesses_v1: {
        Args: {
          p_admin_note?: string
          p_dry_run?: boolean
          p_duplicate_business_id: string
          p_primary_business_id: string
        }
        Returns: Json
      }
      admin_queue_assign_v1: {
        Args: {
          p_assign_to_me?: boolean
          p_item_id: string
          p_item_type: string
        }
        Returns: Json
      }
      admin_queue_v1: {
        Args: {
          p_city?: string
          p_from?: string
          p_limit?: number
          p_offset?: number
          p_q?: string
          p_sort_dir?: string
          p_sort_key?: string
          p_status?: string
          p_to?: string
          p_type?: string
        }
        Returns: {
          age_hours: number
          assigned_at: string
          assigned_to: string
          business_id: string
          business_name: string
          city: string
          created_at: string
          detail: Json
          district: string
          id: string
          item_type: string
          sla_breached: boolean
          sla_hours: number
          status: string
          subtitle: string
          title: string
          total_count: number
        }[]
      }
      admin_reject_business_submission_v1: {
        Args: { p_note?: string; p_submission_id: string }
        Returns: Json
      }
      admin_reject_business_suggestion_v1: {
        Args: { p_admin_note?: string; p_suggestion_id: string }
        Returns: Json
      }
      admin_reject_menu_price_suggestion_v1: {
        Args: { p_note?: string; p_suggestion_id: string }
        Returns: Json
      }
      admin_reject_mission_claim_v1: {
        Args: { p_claim_id: string }
        Returns: Json
      }
      admin_reject_price_suggestion_v1: {
        Args: { p_reason?: string; p_suggestion_id: string }
        Returns: Json
      }
      admin_reject_suspended_claim_v1: {
        Args: { p_claim_id: string; p_note?: string }
        Returns: Json
      }
      admin_remove_business_from_chain_v1: {
        Args: { p_business_id: string }
        Returns: Json
      }
      admin_reset_user_achievement_v1: {
        Args: { p_achievement_id: string; p_reason?: string; p_user_id: string }
        Returns: Json
      }
      admin_set_appeal_review_v1: {
        Args: { p_appeal_id: string; p_in_review: boolean }
        Returns: Json
      }
      admin_set_business_media_v1: {
        Args: { p_business_id: string; p_field: string; p_url: string }
        Returns: Json
      }
      admin_set_business_plan_v1: {
        Args: { p_business_id: string; p_ends_at?: string; p_plan_tier: string }
        Returns: Json
      }
      admin_set_business_verified_v1: {
        Args: {
          p_business_id: string
          p_ends_at?: string
          p_is_verified: boolean
          p_tier?: string
        }
        Returns: Json
      }
      admin_set_menu_item_photo_moderation_v1: {
        Args: {
          p_is_hidden?: boolean
          p_note?: string
          p_photo_id: string
          p_status: string
        }
        Returns: Json
      }
      admin_set_offline_mutation_alert_settings_v1: {
        Args: { p_settings: Json }
        Returns: Json
      }
      admin_set_sponsorship_status_v1: {
        Args: { p_sponsorship_id: string; p_status: string }
        Returns: Json
      }
      admin_set_submission_review_v1: {
        Args: { p_in_review: boolean; p_submission_id: string }
        Returns: Json
      }
      admin_sla_metrics_v1: { Args: never; Returns: Json }
      admin_unassign_business_suggestion_v1: {
        Args: { p_suggestion_id: string }
        Returns: Json
      }
      admin_unassign_owner_claim_v1: {
        Args: { p_claim_id: string }
        Returns: Json
      }
      admin_unassign_report_v1: { Args: { p_report_id: string }; Returns: Json }
      admin_update_business_v1: {
        Args: {
          p_address: string
          p_business_id: string
          p_category: string
          p_city: string
          p_cover_url: string
          p_district: string
          p_lat: number
          p_lng: number
          p_logo_url: string
          p_name: string
        }
        Returns: Json
      }
      admin_update_chain_v1: {
        Args: {
          p_category?: string
          p_chain_id: string
          p_cover_url?: string
          p_description?: string
          p_is_verified?: boolean
          p_logo_url?: string
          p_name?: string
          p_slug?: string
          p_template_business_id?: string
          p_website?: string
        }
        Returns: Json
      }
      admin_update_receipt_submission_review_v1: {
        Args: {
          p_receipt_id: string
          p_review_note?: string
          p_review_status: string
          p_reviewed_by?: string
        }
        Returns: Json
      }
      admin_update_report_v2: {
        Args: { p_admin_note?: string; p_report_id: string; p_status: string }
        Returns: undefined
      }
      admin_update_sponsorship_lead_status_v1: {
        Args: { p_id: string; p_status: string }
        Returns: Json
      }
      admin_upsert_chain_override_v1: {
        Args: {
          p_business_id: string
          p_currency?: string
          p_menu_item_id: string
          p_note?: string
          p_price_cents: number
        }
        Returns: Json
      }
      admin_upsert_sponsorship_package_v1: {
        Args: {
          p_currency_code?: string
          p_duration_days?: number
          p_id?: string
          p_inventory_limit?: number
          p_is_active?: boolean
          p_name?: string
          p_price_cents?: number
          p_price_display?: string
          p_surface?: string
        }
        Returns: Json
      }
      analytics_growth_v1: {
        Args: { p_business_id?: string; p_days?: number }
        Returns: {
          app_install_from_menu: number
          day: string
          menu_link_opened: number
          menu_shared: number
          qr_scanned: number
        }[]
      }
      analytics_growth_v2: {
        Args: { p_business_id?: string; p_days?: number }
        Returns: {
          app_install_from_menu: number
          business_order_click: number
          business_phone_click: number
          business_reservation_click: number
          business_whatsapp_click: number
          day: string
          menu_link_opened: number
          menu_shared: number
          qr_scanned: number
        }[]
      }
      analytics_growth_v3: {
        Args: { p_business_id?: string; p_days?: number }
        Returns: {
          app_install_from_menu: number
          business_order_click: number
          business_phone_click: number
          business_reservation_click: number
          business_whatsapp_click: number
          day: string
          district_price_gap_pct: number
          district_price_position: string
          menu_link_opened: number
          menu_shared: number
          price_dropoff_estimate: number
          qr_scanned: number
        }[]
      }
      anonymize_user_content_v1: {
        Args: { p_reason?: string; p_user_id: string }
        Returns: undefined
      }
      apply_auto_moderation_rules_v1: {
        Args: { p_id: string; p_target: string }
        Returns: Json
      }
      apply_menu_ai_analysis_v1: {
        Args: { p_analysis_id: string; p_section_id: string }
        Returns: string
      }
      apply_profile_xp_v1: {
        Args: { p_user_id: string; p_xp: number }
        Returns: {
          level: number
          leveled_up: boolean
          total_xp: number
          unlocked_count: number
        }[]
      }
      approve_menu_item_suggestion_v1: {
        Args: { p_note?: string; p_suggestion_id: string }
        Returns: Json
      }
      assert_owner_scope_v1: {
        Args: { p_business_id: string }
        Returns: undefined
      }
      assign_all_businesses_to_boundaries_v1: {
        Args: { p_batch?: number }
        Returns: number
      }
      assign_business_to_boundary_v1: {
        Args: { p_business_id: string }
        Returns: string
      }
      auto_approve_trusted_owner_claim_v1: {
        Args: { p_claim_id: string }
        Returns: boolean
      }
      auto_close_duplicate_report_v1: {
        Args: { p_report_id: string }
        Returns: boolean
      }
      auto_queue_grey_report_v1: {
        Args: { p_report_id: string }
        Returns: boolean
      }
      auto_reject_low_quality_report_v1: {
        Args: { p_report_id: string }
        Returns: boolean
      }
      award_achievement_v1: {
        Args: { p_achievement_id: string; p_meta?: Json; p_user_id: string }
        Returns: boolean
      }
      batch_recompute_price_levels_v1: {
        Args: { p_category?: string; p_city?: string }
        Returns: {
          set_null: number
          updated: number
        }[]
      }
      bump_collection_engagement_v1: {
        Args: { p_collection_key: string; p_delta?: number }
        Returns: {
          engagement_count: number
        }[]
      }
      bump_food_catalog_popularity_v1: { Args: { p_id: number }; Returns: Json }
      business_role_has_permission_v1: {
        Args: { p_permission: string; p_role: string }
        Returns: boolean
      }
      business_role_rank_v1: { Args: { p_role: string }; Returns: number }
      can_access_business_v1: {
        Args: { p_business_id: string }
        Returns: boolean
      }
      can_manage_branch_v1: {
        Args: {
          p_actor_user_id?: string
          p_business_id: string
          p_role_override?: string
        }
        Returns: boolean
      }
      can_manage_business_v1: {
        Args: { p_business_id: string }
        Returns: boolean
      }
      can_view_business_v1: {
        Args: {
          p_actor_user_id?: string
          p_business_id: string
          p_role_override?: string
        }
        Returns: boolean
      }
      capture_request_meta_v1: { Args: never; Returns: Record<string, unknown> }
      check_price_alerts_for_item_v1:
        | {
            Args: {
              p_business_id: string
              p_category: string
              p_city: string
              p_district: string
              p_item_name: string
              p_menu_item_id: string
              p_price_cents: number
            }
            Returns: undefined
          }
        | {
            Args: {
              p_business_id: string
              p_category: string
              p_city: string
              p_district: string
              p_district_avg_price_cents?: number
              p_item_name: string
              p_menu_item_id: string
              p_previous_price_cents?: number
              p_price_cents: number
            }
            Returns: undefined
          }
        | {
            Args: {
              p_business_id: string
              p_category: string
              p_city: string
              p_district: string
              p_district_avg_price_cents?: number
              p_is_verified_change?: boolean
              p_item_name: string
              p_menu_item_id: string
              p_previous_price_cents?: number
              p_price_cents: number
            }
            Returns: undefined
          }
      check_rate_limit_v1: {
        Args: { p_key: string; p_max: number; p_window?: string }
        Returns: boolean
      }
      claim_mission_v1: { Args: { p_mission_id: string }; Returns: Json }
      claim_pending_team_invites_v1: { Args: never; Returns: Json }
      close_group_request_v1: { Args: { p_request_id: string }; Returns: Json }
      complete_notification_dispatch_job_v1: {
        Args: { p_error?: string; p_job_id: string; p_success: boolean }
        Returns: boolean
      }
      compute_business_price_level_v1: {
        Args: { p_business_id: string }
        Returns: string
      }
      compute_price_suggestion_quality_v1: {
        Args: {
          p_captured_at?: string
          p_evidence_url?: string
          p_menu_item_id: string
          p_suggested_price_cents: number
        }
        Returns: Json
      }
      consume_edge_guard_event_v1: {
        Args: { p_action: string; p_max_age_seconds?: number; p_scope?: string }
        Returns: undefined
      }
      consume_rate_limit_v1: {
        Args: { p_action: string; p_daily_limit?: number }
        Returns: Json
      }
      contains_contact_or_url_v1: { Args: { p_text: string }; Returns: boolean }
      contains_obfuscated_profanity_v1: {
        Args: { p_text: string }
        Returns: boolean
      }
      create_business_story_v1:
        | {
            Args: {
              p_business_id: string
              p_caption: string
              p_duration_sec?: number
              p_media_thumb_url?: string
              p_media_url: string
              p_type: string
            }
            Returns: Json
          }
        | {
            Args: {
              p_business_id: string
              p_caption: string
              p_duration_sec?: number
              p_expire_mode?: string
              p_media_thumb_url?: string
              p_media_url: string
              p_type: string
            }
            Returns: Json
          }
      create_collection_v1: {
        Args: { p_is_public?: boolean; p_title: string }
        Returns: Json
      }
      create_email_campaign_v1: {
        Args: {
          p_business_id: string
          p_campaign_id?: string
          p_html_body: string
          p_scheduled_at?: string
          p_subject: string
          p_target_segment?: string
        }
        Returns: string
      }
      create_group_request_v1: {
        Args: {
          p_budget_total_cents?: number
          p_category?: string
          p_city: string
          p_date_time?: string
          p_districts?: string[]
          p_notes?: string
          p_party_size?: number
        }
        Returns: Json
      }
      create_loyalty_program_v1: {
        Args: {
          p_business_id: string
          p_mode: string
          p_name: string
          p_reward_desc: string
          p_reward_threshold: number
        }
        Returns: string
      }
      create_menu_ocr_job_v1: {
        Args: {
          p_business_id: string
          p_file_name?: string
          p_file_url: string
        }
        Returns: string
      }
      create_menu_snapshot_v1: {
        Args: { p_menu_id: string; p_reason?: string }
        Returns: string
      }
      create_price_alert_v1: {
        Args: {
          p_category?: string
          p_city?: string
          p_currency?: string
          p_district?: string
          p_max_price_cents: number
          p_query: string
        }
        Returns: Json
      }
      create_price_alert_v2: {
        Args: {
          p_category?: string
          p_city?: string
          p_currency?: string
          p_district?: string
          p_idempotency_key?: string
          p_max_price_cents: number
          p_query: string
        }
        Returns: Json
      }
      create_push_campaign_v1: {
        Args: {
          p_body: string
          p_business_id: string
          p_image_url?: string
          p_scheduled_at?: string
          p_target_segment?: string
          p_title: string
        }
        Returns: string
      }
      create_reservation_v1: {
        Args: {
          p_business_id: string
          p_channel?: string
          p_date?: string
          p_guest_email?: string
          p_guest_name: string
          p_guest_phone: string
          p_party_size?: number
          p_special_request?: string
          p_table_preference?: string
          p_time?: string
        }
        Returns: Json
      }
      create_support_ticket_v1: {
        Args: {
          p_business_id: string
          p_category: string
          p_message: string
          p_subject: string
        }
        Returns: string
      }
      create_suspended_meal_v1: {
        Args: {
          p_amount_cents: number
          p_business_id: string
          p_currency?: string
          p_message?: string
        }
        Returns: Json
      }
      current_user_role_v1: { Args: never; Returns: string }
      delete_business_special_hour_v1: {
        Args: { p_business_id: string; p_date: string }
        Returns: undefined
      }
      delete_business_story_v1: { Args: { p_story_id: string }; Returns: Json }
      delete_custom_domain_v1: {
        Args: { p_business_id: string }
        Returns: undefined
      }
      delete_loyalty_program_v1: {
        Args: { p_program_id: string }
        Returns: undefined
      }
      delete_owner_review_reply_v1: {
        Args: { p_review_id: string }
        Returns: Json
      }
      delete_review_reply: { Args: { p_review_id: string }; Returns: Json }
      delete_user_account_v1: { Args: never; Returns: Json }
      dequeue_notification_dispatch_jobs_v1: {
        Args: { p_limit?: number }
        Returns: {
          body: string
          data: Json
          job_id: string
          notification_id: string
          title: string
          type: string
          user_id: string
        }[]
      }
      disablelongtransactions: { Args: never; Returns: string }
      discover_gourmets_v1: {
        Args: { p_limit?: number; p_offset?: number }
        Returns: {
          avatar_url: string
          bio: string
          display_name: string
          follower_count: number
          user_id: string
        }[]
      }
      dropgeometrycolumn:
        | {
            Args: {
              catalog_name: string
              column_name: string
              schema_name: string
              table_name: string
            }
            Returns: string
          }
        | {
            Args: {
              column_name: string
              schema_name: string
              table_name: string
            }
            Returns: string
          }
        | { Args: { column_name: string; table_name: string }; Returns: string }
      dropgeometrytable:
        | {
            Args: {
              catalog_name: string
              schema_name: string
              table_name: string
            }
            Returns: string
          }
        | { Args: { schema_name: string; table_name: string }; Returns: string }
        | { Args: { table_name: string }; Returns: string }
      enablelongtransactions: { Args: never; Returns: string }
      ensure_default_section_for_business_v1: {
        Args: { p_business_id: string }
        Returns: string
      }
      ensure_my_profile_v1: {
        Args: { p_avatar_url?: string; p_display_name?: string }
        Returns: Json
      }
      equals: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      estimate_campaign_segment_v1: {
        Args: { p_business_id: string; p_segment: string }
        Returns: number
      }
      estimate_email_segment_v1: {
        Args: { p_business_id: string; p_segment?: string }
        Returns: number
      }
      follow_business_v1: { Args: { p_business_id: string }; Returns: Json }
      generate_photo_missions_v1: {
        Args: { p_city?: string; p_district?: string; p_limit?: number }
        Returns: number
      }
      geometry: { Args: { "": string }; Returns: unknown }
      geometry_above: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_below: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_cmp: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      geometry_contained_3d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_contains: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_contains_3d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_distance_box: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      geometry_distance_centroid: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      geometry_eq: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_ge: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_gt: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_le: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_left: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_lt: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overabove: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overbelow: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overlaps: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overlaps_3d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overleft: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_overright: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_right: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_same: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_same_3d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geometry_within: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      geomfromewkt: { Args: { "": string }; Returns: unknown }
      get_active_perks_v1: {
        Args: { p_business_id: string }
        Returns: {
          business_id: string
          created_at: string
          description: string
          ends_at: string
          id: string
          requires_checkin: boolean
          starts_at: string
          status: string
          title: string
        }[]
      }
      get_app_role_v1: { Args: never; Returns: string }
      get_bill_estimate_v1: {
        Args: { p_business_id: string; p_items: Json; p_tip_pct?: number }
        Returns: Json
      }
      get_boundary_stats_v1: {
        Args: { p_admin_level?: number }
        Returns: {
          admin_level: number
          avg_rating: number
          boundary_id: string
          business_count: number
          name: string
        }[]
      }
      get_budget_combos_v1: {
        Args: {
          p_budget_total_cents: number
          p_category?: string
          p_city: string
          p_district: string
          p_limit?: number
          p_party_size: number
        }
        Returns: {
          business_id: string
          business_name: string
          combo: Json
          total_cents: number
        }[]
      }
      get_business_activity_v1: {
        Args: { p_business_id: string; p_limit?: number }
        Returns: {
          activity_id: string
          activity_type: string
          created_at: string
          meta: Json
        }[]
      }
      get_business_amenities_v1: {
        Args: { p_business_id: string }
        Returns: {
          icon: string
          key: string
          label: string
        }[]
      }
      get_business_audit_log_v1: {
        Args: {
          p_action?: string
          p_actor_id?: string
          p_business_ids: string[]
          p_date_from?: string
          p_date_to?: string
          p_limit?: number
          p_offset?: number
        }
        Returns: Json
      }
      get_business_badges_v1: {
        Args: { p_business_id: string }
        Returns: {
          badge_id: string
          color: string
          tier: string
          title: string
        }[]
      }
      get_business_categories_v1: {
        Args: never
        Returns: {
          business_count: number
          category: string
        }[]
      }
      get_business_chain_info_v1: {
        Args: { p_business_id: string }
        Returns: {
          branch_count: number
          branch_label: string
          chain_category: string
          chain_id: string
          chain_is_verified: boolean
          chain_logo_url: string
          chain_name: string
          chain_slug: string
          is_template_branch: boolean
        }[]
      }
      get_business_cities_v1: {
        Args: { p_limit?: number }
        Returns: {
          business_count: number
          city: string
        }[]
      }
      get_business_compare_v1: {
        Args: { p_business_ids: string[] }
        Returns: {
          business_id: string
          last_update_at: string
          median_price_cents: number
          verified_ratio: number
        }[]
      }
      get_business_crowd_v1: { Args: { p_business_id: string }; Returns: Json }
      get_business_customers_v1: {
        Args: { p_business_id: string }
        Returns: Json
      }
      get_business_daily_stats_v1: {
        Args: { p_business_id: string; p_date?: string }
        Returns: Json
      }
      get_business_detail_v1: {
        Args: { p_business_id: string; p_latest_reviews_limit?: number }
        Returns: Json
      }
      get_business_districts_v1: {
        Args: { p_city?: string }
        Returns: {
          business_count: number
          district: string
        }[]
      }
      get_business_fee_summary_v1: {
        Args: { p_business_id: string }
        Returns: Json
      }
      get_business_frequent_tags_v1: {
        Args: { p_business_id: string; p_limit?: number }
        Returns: {
          mention_count: number
          tag: string
        }[]
      }
      get_business_full_profile_v1: {
        Args: {
          p_business_id: string
          p_include_hours?: boolean
          p_latest_reviews?: number
        }
        Returns: Json
      }
      get_business_hours_v1: { Args: { p_business_id: string }; Returns: Json }
      get_business_location_district_stats_v1: {
        Args: never
        Returns: {
          active_count: number
          business_count: number
          city: string
          district: string
          verified_count: number
        }[]
      }
      get_business_loyalty_members_v1: {
        Args: { p_business_id: string }
        Returns: Json
      }
      get_business_loyalty_program_v1: {
        Args: { p_business_id: string }
        Returns: Json
      }
      get_business_meal_card_provider_rows_v1: {
        Args: { p_business_ids: string[]; p_provider_keys?: string[] }
        Returns: {
          asset_name: string
          business_id: string
          key: string
          name: string
          provider_id: string
          sort_order: number
        }[]
      }
      get_business_meal_card_providers_v1: {
        Args: { p_business_id: string }
        Returns: {
          asset_name: string
          key: string
          name: string
          provider_id: string
          sort_order: number
        }[]
      }
      get_business_menus_v1: {
        Args: { p_business_id: string }
        Returns: {
          active_from: string
          active_to: string
          external_url: string
          id: string
          kind: string
          source_image_url: string
          status: Database["public"]["Enums"]["menu_status"]
          title: string
        }[]
      }
      get_business_new_items_v1: {
        Args: { p_business_id: string; p_limit?: number }
        Returns: {
          created_at: string
          currency: string
          item_name: string
          menu_item_id: string
          price_cents: number
        }[]
      }
      get_business_price_comparison_v1: {
        Args: { p_business_id: string; p_limit?: number }
        Returns: {
          business_price_cents: number
          category: string
          city_avg_cents: number
          city_max_cents: number
          city_min_cents: number
          city_sample_count: number
          diff_pct: number
          district_avg_cents: number
          item_name: string
          menu_item_id: string
        }[]
      }
      get_business_price_competitors_v1: {
        Args: { p_business_id: string; p_limit?: number }
        Returns: {
          business_id: string
          category: string
          city: string
          district: string
          matched_items: number
        }[]
      }
      get_business_price_history_v1: {
        Args: { p_business_id: string; p_days?: number; p_limit?: number }
        Returns: {
          business_id: string
          changed_at: string
          menu_item_id: string
          menu_item_name: string
          price_cents: number
        }[]
      }
      get_business_price_trust_v1: {
        Args: { p_business_id: string }
        Returns: Json
      }
      get_business_profile_score_v1: {
        Args: { p_business_id: string }
        Returns: Json
      }
      get_business_province_map_v1: {
        Args: { p_tolerance?: number }
        Returns: {
          active_count: number
          business_count: number
          district_count: number
          geojson: string
          province_name: string
          verified_count: number
        }[]
      }
      get_business_quality_score_v1: {
        Args: { p_business_id: string }
        Returns: Json
      }
      get_business_rating_summary_v1: {
        Args: { p_business_id: string }
        Returns: {
          avg_atmosphere_rating: number
          avg_cleanliness_rating: number
          avg_overall_rating: number
          avg_price_performance_rating: number
          avg_service_speed_rating: number
          avg_taste_rating: number
          business_id: string
          rating_count: number
        }[]
      }
      get_business_rating_summary_v2: {
        Args: { p_business_id: string }
        Returns: {
          avg_atmosphere_rating: number
          avg_cleanliness_rating: number
          avg_overall_rating: number
          avg_price_performance_rating: number
          avg_service_speed_rating: number
          avg_taste_rating: number
          business_id: string
          rating_1: number
          rating_2: number
          rating_3: number
          rating_4: number
          rating_5: number
          rating_count: number
        }[]
      }
      get_business_reality_score_v1: {
        Args: { p_business_id: string }
        Returns: Json
      }
      get_business_recent_checkins_v1: {
        Args: { p_business_id: string; p_hours?: number }
        Returns: Json
      }
      get_business_review_counts_batch_v1: {
        Args: { p_ids: string[] }
        Returns: {
          business_id: string
          review_count: number
        }[]
      }
      get_business_reviews_v2: {
        Args: {
          p_business_id: string
          p_limit?: number
          p_offset?: number
          p_sort?: string
        }
        Returns: {
          business_id: string
          content: string
          created_at: string
          helpful_count: number
          id: string
          quality_score: number
          rating: number
          status: string
          title: string
          user_id: string
        }[]
      }
      get_business_reviews_v3: {
        Args: {
          p_business_id: string
          p_limit?: number
          p_offset?: number
          p_sort?: string
        }
        Returns: {
          business_id: string
          content: string
          created_at: string
          helpful_count: number
          id: string
          quality_score: number
          r_atmosphere: number
          r_cleanliness: number
          r_price_value: number
          r_service: number
          r_taste: number
          rating: number
          status: string
          title: string
          user_id: string
          verified_visit: boolean
        }[]
      }
      get_business_reviews_v4: {
        Args: {
          p_business_id: string
          p_limit?: number
          p_min_rating?: number
          p_offset?: number
          p_sort?: string
          p_verified?: boolean
        }
        Returns: {
          author_badge_color: string
          author_badge_id: string
          author_badge_tier: string
          author_badge_title: string
          business_id: string
          content: string
          created_at: string
          helpful_count: number
          id: string
          quality_score: number
          r_atmosphere: number
          r_cleanliness: number
          r_price_value: number
          r_service: number
          r_taste: number
          rating: number
          status: string
          title: string
          user_id: string
          verified_visit: boolean
        }[]
      }
      get_business_role_v1: {
        Args: {
          p_actor_user_id?: string
          p_business_id: string
          p_role_override?: string
        }
        Returns: string
      }
      get_business_social_links_v1: {
        Args: { p_business_id: string }
        Returns: Json
      }
      get_business_stories_v1: {
        Args: { p_business_id: string; p_limit?: number }
        Returns: {
          caption: string
          created_at: string
          expires_at: string
          id: string
          media_thumb_url: string
          media_type: string
          media_url: string
          type: Database["public"]["Enums"]["story_type"]
        }[]
      }
      get_business_trending_items_v1: {
        Args: { p_business_id: string; p_limit?: number }
        Returns: {
          currency: string
          item_name: string
          menu_item_id: string
          price_cents: number
          score: number
        }[]
      }
      get_businesses_in_boundary_v1: {
        Args: { p_boundary_id: string; p_limit?: number; p_offset?: number }
        Returns: {
          address: string
          avg_rating: number
          category: string
          id: string
          is_active: boolean
          is_verified: boolean
          lat: number
          lng: number
          name: string
          review_count: number
          slug: string
        }[]
      }
      get_category_price_benchmark_v1: {
        Args: {
          p_city: string
          p_exclude_business_id?: string
          p_item_name: string
        }
        Returns: {
          avg_price_cents: number
          max_price_cents: number
          min_price_cents: number
          sample_count: number
        }[]
      }
      get_chain_menu_v1: {
        Args: { p_business_id: string }
        Returns: {
          branch_price_cents: number
          currency: string
          has_branch_override: boolean
          image_url: string
          is_available: boolean
          item_description: string
          item_id: string
          item_name: string
          item_sort: number
          price_cents: number
          section_id: string
          section_sort: number
          section_title: string
        }[]
      }
      get_chain_overview_v1: {
        Args: {
          p_chain_id: string
          p_lat?: number
          p_limit?: number
          p_lng?: number
        }
        Returns: {
          address: string
          branch_label: string
          business_id: string
          business_name: string
          chain_description: string
          chain_id: string
          chain_name: string
          city: string
          distance_km: number
          district: string
          is_open_now: boolean
        }[]
      }
      get_chain_overview_v2: {
        Args: {
          p_chain_id: string
          p_lat?: number
          p_limit?: number
          p_lng?: number
        }
        Returns: {
          address: string
          avg_price_cents: number
          branch_label: string
          business_id: string
          business_name: string
          chain_avg_price_cents: number
          chain_description: string
          chain_id: string
          chain_name: string
          city: string
          distance_km: number
          district: string
          is_open_now: boolean
          price_delta_pct: number
        }[]
      }
      get_city_districts_v1: {
        Args: never
        Returns: {
          city: string
          count: number
          district: string
        }[]
      }
      get_collab_list_detail_v1: { Args: { p_list_id: string }; Returns: Json }
      get_collection_share_by_slug_v1: {
        Args: { p_slug: string }
        Returns: {
          business_ids: string[]
          collection_key: string
          name: string
          slug: string
        }[]
      }
      get_collection_social_batch_v1: {
        Args: { p_keys: string[] }
        Returns: {
          collection_key: string
          engagement_count: number
          followers_count: number
          is_following: boolean
        }[]
      }
      get_custom_domain_v1: { Args: { p_business_id: string }; Returns: Json }
      get_customer_timeline_v1: {
        Args: { p_business_id: string; p_user_id: string }
        Returns: Json
      }
      get_daily_picks: {
        Args: { p_limit?: number }
        Returns: {
          avg_rating: number
          business_id: string
          category: string
          city: string
          district: string
          name: string
          reviews_count: number
        }[]
      }
      get_dashboard_weekly_v1: {
        Args: { p_business_id: string; p_days?: number }
        Returns: Json
      }
      get_district_night_favorites_v1:
        | {
            Args: { p_city: string; p_district: string; p_limit?: number }
            Returns: {
              address: string
              avg_rating: number
              category: string
              city: string
              distance_km: number
              district: string
              favorites_count: number
              id: string
              is_open_now: boolean
              lat: number
              lng: number
              median_price_cents: number
              name: string
              quality_score: number
              recent_price_verified_count: number
            }[]
          }
        | {
            Args: {
              p_city: string
              p_district: string
              p_limit?: number
              p_neighborhood?: string
            }
            Returns: {
              address: string
              avg_rating: number
              category: string
              city: string
              distance_km: number
              district: string
              favorites_count: number
              id: string
              is_open_now: boolean
              lat: number
              lng: number
              median_price_cents: number
              name: string
              quality_score: number
              recent_price_verified_count: number
            }[]
          }
      get_district_price_changes_v1:
        | {
            Args: { p_city: string; p_district: string; p_limit?: number }
            Returns: {
              address: string
              avg_rating: number
              category: string
              city: string
              distance_km: number
              district: string
              id: string
              is_open_now: boolean
              lat: number
              lng: number
              median_price_cents: number
              name: string
              price_changes_count: number
              quality_score: number
              recent_price_verified_count: number
            }[]
          }
        | {
            Args: {
              p_city: string
              p_district: string
              p_limit?: number
              p_neighborhood?: string
            }
            Returns: {
              address: string
              avg_rating: number
              category: string
              city: string
              distance_km: number
              district: string
              id: string
              is_open_now: boolean
              lat: number
              lng: number
              median_price_cents: number
              name: string
              price_changes_count: number
              quality_score: number
              recent_price_verified_count: number
            }[]
          }
      get_district_top_views_v1:
        | {
            Args: { p_city: string; p_district: string; p_limit?: number }
            Returns: {
              address: string
              avg_rating: number
              category: string
              city: string
              distance_km: number
              district: string
              id: string
              is_open_now: boolean
              lat: number
              lng: number
              median_price_cents: number
              name: string
              quality_score: number
              recent_price_verified_count: number
              views_count: number
            }[]
          }
        | {
            Args: {
              p_city: string
              p_district: string
              p_limit?: number
              p_neighborhood?: string
            }
            Returns: {
              address: string
              avg_rating: number
              category: string
              city: string
              distance_km: number
              district: string
              id: string
              is_open_now: boolean
              lat: number
              lng: number
              median_price_cents: number
              name: string
              quality_score: number
              recent_price_verified_count: number
              views_count: number
            }[]
          }
      get_email_campaign_recipients_v1: {
        Args: { p_business_id: string; p_target_segment: string }
        Returns: Json
      }
      get_heroes_v1: {
        Args: { p_limit?: number }
        Returns: {
          donated_amount_cents: number
          donated_count: number
          user_id: string
        }[]
      }
      get_menu_item_context_v1: {
        Args: { p_menu_item_id: string }
        Returns: Json
      }
      get_menu_item_counts_v1: {
        Args: { p_business_id: string }
        Returns: Json
      }
      get_menu_item_photos_v1: {
        Args: { p_limit?: number; p_menu_item_id: string }
        Returns: {
          created_at: string
          down_votes: number
          id: string
          my_vote: number
          provider: string
          score: number
          up_votes: number
          url: string
          url_large: string
          url_thumb: string
        }[]
      }
      get_menu_item_price_history_v1: {
        Args: { p_limit?: number; p_menu_item_id: string }
        Returns: {
          created_at: string
          currency: string
          new_price_cents: number
          old_price_cents: number
          source: string
        }[]
      }
      get_menu_item_price_status_v1: {
        Args: { p_menu_item_id: string }
        Returns: Json
      }
      get_menu_item_translations_v1: {
        Args: { p_item_id: string }
        Returns: Json
      }
      get_menu_item_value_score_v1: {
        Args: { p_menu_item_id: string }
        Returns: Json
      }
      get_menu_item_variants_v1: {
        Args: { p_menu_item_id: string }
        Returns: {
          currency: string
          id: string
          is_available: boolean
          is_default: boolean
          label: string
          menu_item_id: string
          price_cents: number
          sort_order: number
        }[]
      }
      get_menu_items_price_age_v1: {
        Args: { p_item_ids: string[] }
        Returns: {
          last_price_at: string
          menu_item_id: string
        }[]
      }
      get_menu_items_v1: {
        Args: { p_menu_id: string }
        Returns: {
          calories: number
          currency: string
          description: string
          id: string
          is_gluten_free: boolean
          is_halal: boolean
          is_lactose_free: boolean
          is_vegan: boolean
          is_vegetarian: boolean
          name: string
          price_cents: number
          section_id: string
        }[]
      }
      get_menu_items_v2: {
        Args: { p_limit?: number; p_offset?: number; p_section_id: string }
        Returns: {
          business_id: string
          calories: number
          catalog_item_id: number
          created_at: string
          currency: string
          description: string
          id: string
          is_gluten_free: boolean
          is_halal: boolean
          is_lactose_free: boolean
          is_vegan: boolean
          is_vegetarian: boolean
          name: string
          price_cents: number
          price_status: string
          section_id: string
          status: string
          total_30d: number
          updated_at: string
        }[]
      }
      get_menu_price_anomalies_v1: {
        Args: {
          p_city?: string
          p_days?: number
          p_district?: string
          p_limit?: number
          p_min_change_pct?: number
        }
        Returns: {
          business_id: string
          business_name: string
          change_pct: number
          city: string
          district: string
          first_price_cents: number
          last_changed_at: string
          last_price_cents: number
          menu_item_id: string
          menu_item_name: string
        }[]
      }
      get_menu_section_translations_v1: {
        Args: { p_section_id: string }
        Returns: Json
      }
      get_menu_sections_v1: {
        Args: { p_menu_id: string }
        Returns: {
          id: string
          sort_order: number
          title: string
        }[]
      }
      get_moderation_templates_v1: {
        Args: { p_scope?: string }
        Returns: {
          body: string
          decision: string
          id: string
          locale: string
          scope: string
          title: string
        }[]
      }
      get_my_achievements_v1: {
        Args: never
        Returns: {
          color: string
          condition: Json
          description: string
          icon: string
          id: string
          title: string
          unlocked: boolean
          unlocked_at: string
        }[]
      }
      get_my_achievements_v2: {
        Args: never
        Returns: {
          color: string
          condition: Json
          current_value: number
          description: string
          icon: string
          id: string
          target_value: number
          title: string
          unlocked: boolean
          unlocked_at: string
          xp: number
        }[]
      }
      get_my_behavior_segment_v1: { Args: never; Returns: Json }
      get_my_checkin_today_v1: {
        Args: { p_business_id: string }
        Returns: Json
      }
      get_my_daily_micro_task_v1: {
        Args: never
        Returns: {
          completed: boolean
          current_value: number
          description: string
          target_value: number
          task_key: string
          title: string
        }[]
      }
      get_my_diet_profile_v1: { Args: never; Returns: Json }
      get_my_favorites_v1: {
        Args: { p_limit?: number; p_offset?: number }
        Returns: {
          business_id: string
          favorited_at: string
        }[]
      }
      get_my_feed_v1: {
        Args: { p_limit: number; p_offset: number }
        Returns: {
          business_id: string
          created_at: string
          event_id: string
          meta: Json
          ref_id: string
          type: string
        }[]
      }
      get_my_following_v1: {
        Args: { p_limit?: number; p_offset?: number }
        Returns: {
          avatar_url: string
          bio: string
          display_name: string
          followed_at: string
          is_gourmet: boolean
          user_id: string
        }[]
      }
      get_my_food_journal_v1: {
        Args: { p_limit?: number; p_offset?: number }
        Returns: {
          amount_cents: number
          business_id: string
          business_name: string
          business_slug: string
          category: string
          checked_in_at: string
          city: string
          currency: string
          personal_note: string
          personal_rating: number
          visit_id: string
        }[]
      }
      get_my_loyalty_cards_v1: { Args: never; Returns: Json }
      get_my_notification_preferences_v1: { Args: never; Returns: Json }
      get_my_plan_v1: { Args: { p_business_id: string }; Returns: Json }
      get_my_points_v1: { Args: never; Returns: Json }
      get_my_profile_progress_v1: {
        Args: never
        Returns: {
          level: number
          next_level_xp: number
          total_xp: number
          unlocked_count: number
          xp_in_level: number
        }[]
      }
      get_my_profile_stats: {
        Args: never
        Returns: {
          contribution_score: number
          favorites_count: number
          helpful_received: number
          reviews_count: number
          visits_count: number
        }[]
      }
      get_my_profile_stats_v1: {
        Args: never
        Returns: {
          contribution_score: number
          favorites_count: number
          followers_count: number
          helpful_received: number
          reviews_count: number
          visits_count: number
        }[]
      }
      get_my_referral_stats_v1: { Args: never; Returns: Json }
      get_my_reputation_score_v1: { Args: never; Returns: number }
      get_my_silent_quality_score_v1: { Args: never; Returns: Json }
      get_my_spending_summary_v1: {
        Args: { p_months?: number }
        Returns: {
          month_label: string
          total_cents: number
          unique_places: number
          visit_count: number
        }[]
      }
      get_my_suspended_claim_badge_v1: { Args: never; Returns: Json }
      get_my_suspended_claims_v1: {
        Args: { p_limit?: number; p_offset?: number; p_status?: string }
        Returns: {
          amount_cents: number
          business_id: string
          business_name: string
          city: string
          claim_id: string
          claim_status: string
          created_at: string
          currency: string
          district: string
          fulfilled_at: string
          handled_at: string
          verify_code: string
        }[]
      }
      get_my_trust_graph_v1: { Args: never; Returns: Json }
      get_my_weekly_missions: {
        Args: never
        Returns: {
          completed_count: number
          reviews_done: number
          reviews_goal: number
          visits_done: number
          visits_goal: number
          votes_done: number
          votes_goal: number
          week_start: string
        }[]
      }
      get_nearby_campaign_stories_v1: {
        Args: {
          p_city?: string
          p_district?: string
          p_lat?: number
          p_limit?: number
          p_lng?: number
          p_radius_km?: number
        }
        Returns: {
          business_id: string
          business_name: string
          caption: string
          city: string
          created_at: string
          distance_km: number
          district: string
          expires_at: string
          media_thumb_url: string
          media_url: string
          story_id: string
        }[]
      }
      get_nearby_campaign_stories_v2: {
        Args: {
          p_city?: string
          p_district?: string
          p_lat?: number
          p_limit?: number
          p_lng?: number
          p_radius_km?: number
        }
        Returns: {
          business_id: string
          business_name: string
          caption: string
          category: string
          city: string
          created_at: string
          discount_percent: number
          distance_km: number
          district: string
          expires_at: string
          is_featured: boolean
          is_saved: boolean
          media_thumb_url: string
          media_url: string
          story_id: string
        }[]
      }
      get_owner_menu_version_detail_v1: {
        Args: { p_snapshot_id: string }
        Returns: {
          created_at: string
          item_names: string[]
          menu_id: string
          menu_kind: string
          menu_title: string
          menu_version: number
          section_titles: string[]
          snapshot_id: string
          snapshot_reason: string
        }[]
      }
      get_owner_onboarding_progress_v1: {
        Args: { p_business_id: string }
        Returns: {
          step_completed: number
          updated_at: string
        }[]
      }
      get_owner_price_suggestions_v1: {
        Args: {
          p_business_id?: string
          p_limit?: number
          p_offset?: number
          p_status?: string
        }
        Returns: {
          business_id: string
          business_name: string
          created_at: string
          created_by: string
          currency: string
          current_price_cents: number
          item_name: string
          menu_item_id: string
          status: string
          suggested_price_cents: number
          suggestion_id: string
        }[]
      }
      get_owner_reviews_v1: {
        Args: {
          p_business_id: string
          p_limit?: number
          p_offset?: number
          p_sort?: string
        }
        Returns: {
          content: string
          created_at: string
          helpful_count: number
          id: string
          quality_score: number
          rating: number
          reply_at: string
          reply_content: string
          reply_id: string
          status: string
          title: string
        }[]
      }
      get_pending_table_orders_v1: {
        Args: { p_business_id: string; p_limit?: number }
        Returns: {
          created_at: string
          customer_note: string
          id: string
          items_json: Json
          status: string
          table_number: string
        }[]
      }
      get_perk_feed_v1: {
        Args: {
          p_category?: string
          p_city?: string
          p_district?: string
          p_limit?: number
          p_offset?: number
        }
        Returns: {
          business_id: string
          business_name: string
          created_at: string
          description: string
          ends_at: string
          event_id: string
          starts_at: string
          title: string
        }[]
      }
      get_photo_missions_v1: {
        Args: { p_city?: string; p_district?: string; p_limit?: number }
        Returns: {
          business_id: string
          business_name: string
          city: string
          created_at: string
          district: string
          expires_at: string
          mission_id: string
          mission_type: string
          my_claim_id: string
          my_status: string
          reward_points: number
        }[]
      }
      get_public_collection_v1: {
        Args: { p_collection_id: string }
        Returns: Json
      }
      get_regional_price_index_v2: {
        Args: { p_city?: string; p_district?: string; p_limit?: number }
        Returns: {
          avg_price_cents: number
          category: string
          median_price_cents: number
          sample_count: number
          updated_in_30d: number
        }[]
      }
      get_review_replies_batch: {
        Args: { p_review_ids: string[] }
        Returns: {
          content: string
          created_at: string
          id: string
          review_id: string
        }[]
      }
      get_runtime_experiments_v1: {
        Args: { p_user_id?: string }
        Returns: Json
      }
      get_runtime_feature_flags_v1: {
        Args: { p_user_id?: string }
        Returns: Json
      }
      get_signal_overlap_examples_v1: {
        Args: { p_limit?: number; p_other_user_id: string }
        Returns: {
          business_id: string
          business_name: string
          my_signal: number
          other_signal: number
        }[]
      }
      get_slug_for_domain_v1: { Args: { p_domain: string }; Returns: string }
      get_smart_feed_v2: {
        Args: {
          p_bundles?: string[]
          p_categories?: string[]
          p_city?: string
          p_day_label?: string
          p_districts?: string[]
          p_limit: number
          p_offset: number
          p_price_max_cents?: number
          p_time_label?: string
          p_weather_hint?: string
        }
        Returns: {
          business_id: string
          business_name: string
          created_at: string
          event_id: string
          event_type: string
          payload: Json
          ref_id: string
          ref_type: string
        }[]
      }
      get_smart_recommendations_v1: {
        Args: {
          p_budget_max_cents?: number
          p_city: string
          p_district: string
          p_limit?: number
          p_party_size?: number
        }
        Returns: {
          business_id: string
          business_name: string
          cuisine: string
          discount_pct: number
          distance_km: number
          estimated_minutes: number
          image_url: string
          original_total_cents: number
          rating: number
          review_count: number
          total_cents: number
        }[]
      }
      get_smart_recommendations_v2: {
        Args: {
          p_budget_max_cents?: number
          p_city: string
          p_district: string
          p_lat?: number
          p_limit?: number
          p_lng?: number
          p_party_size?: number
        }
        Returns: {
          business_id: string
          business_name: string
          cuisine: string
          discount_pct: number
          distance_km: number
          estimated_minutes: number
          image_url: string
          original_total_cents: number
          rating: number
          review_count: number
          total_cents: number
        }[]
      }
      get_sponsored_businesses_v1: {
        Args: {
          p_category?: string
          p_city?: string
          p_district?: string
          p_limit?: number
          p_surface: string
        }
        Returns: {
          business_id: string
          business_name: string
          category: string
          city: string
          district: string
          ends_at: string
          priority: number
          sponsorship_id: string
          starts_at: string
        }[]
      }
      get_staff_performance_today_v1: {
        Args: { p_business_id: string }
        Returns: Json
      }
      get_taste_divergence_examples_v1: {
        Args: { p_limit?: number; p_other_user_id: string }
        Returns: {
          business_id: string
          business_name: string
          diff: number
          my_rating: number
          other_rating: number
        }[]
      }
      get_taste_matches_hybrid_v1: {
        Args: { p_limit?: number; p_min_overlap?: number }
        Returns: {
          overlap: number
          review_similarity: number
          signal_similarity: number
          similarity: number
          user_id: string
        }[]
      }
      get_taste_matches_v1: {
        Args: { p_limit?: number; p_min_overlap?: number }
        Returns: {
          overlap: number
          similarity: number
          user_id: string
        }[]
      }
      get_taste_overlap_examples_v1: {
        Args: { p_limit?: number; p_other_user_id: string }
        Returns: {
          business_id: string
          business_name: string
          created_at_my: string
          created_at_other: string
          my_rating: number
          other_rating: number
          score: number
        }[]
      }
      get_today_specials_v1: {
        Args: {
          p_city?: string
          p_lat?: number
          p_limit?: number
          p_lng?: number
          p_radius_km?: number
        }
        Returns: {
          business_id: string
          business_name: string
          business_slug: string
          city: string
          currency: string
          distance_km: number
          item_name: string
          menu_item_id: string
          price_cents: number
          special_note: string
        }[]
      }
      get_top_businesses: {
        Args: { p_limit?: number; p_min_reviews?: number; p_period?: string }
        Returns: {
          avg_rating: number
          business_id: string
          category: string
          city: string
          district: string
          name: string
          reviews_count: number
        }[]
      }
      get_top_businesses_period_v1: {
        Args: {
          p_limit?: number
          p_min_reviews?: number
          p_period: string
          p_user_lat?: number
          p_user_lng?: number
        }
        Returns: {
          avg_rating: number
          category: string
          city: string
          distance_km: number
          district: string
          id: string
          image_url: string
          lat: number
          lng: number
          name: string
          reviews_count: number
          score: number
        }[]
      }
      get_user_location_prefs_v1: { Args: never; Returns: Json }
      get_user_public_profile_v1: { Args: { p_user_id: string }; Returns: Json }
      get_user_reputation_score_v2: {
        Args: { p_user_id: string }
        Returns: number
      }
      get_weekly_contributor_leaderboard_v1: {
        Args: { p_limit?: number }
        Returns: {
          photo_count: number
          review_count: number
          user_id: string
          verify_count: number
          weekly_score: number
        }[]
      }
      gettransactionid: { Args: never; Returns: unknown }
      has_business_permission_v1: {
        Args: {
          p_actor_user_id?: string
          p_business_id: string
          p_permission: string
          p_role_override?: string
        }
        Returns: boolean
      }
      has_recent_checkin_v1: {
        Args: {
          p_business_id: string
          p_client_id: string
          p_window_minutes?: number
        }
        Returns: boolean
      }
      home_feed_v1: {
        Args: {
          p_city: string
          p_district: string
          p_near_open_limit?: number
          p_neighborhood?: string
          p_top_categories_limit?: number
          p_trending_limit?: number
        }
        Returns: Json
      }
      import_osm_boundaries_batch_v1: {
        Args: { p_rows: Json }
        Returns: number
      }
      import_osm_businesses_batch_v1: {
        Args: { p_rows: Json }
        Returns: number
      }
      increment_push_campaign_open_v1: {
        Args: { p_campaign_id: string }
        Returns: undefined
      }
      insert_audit_log_v1: {
        Args: {
          p_action: string
          p_after?: Json
          p_before?: Json
          p_target_id: string
          p_target_type: string
        }
        Returns: undefined
      }
      is_admin: { Args: never; Returns: boolean }
      is_admin_or_community_mod_v1: { Args: never; Returns: boolean }
      is_business_team_member: {
        Args: { p_business_id: string; p_roles: string[] }
        Returns: boolean
      }
      is_edge_ip_denied_v1: { Args: { p_ip_hash: string }; Returns: boolean }
      is_owner: { Args: never; Returns: boolean }
      is_owner_of_business: {
        Args: { p_business_id: string }
        Returns: boolean
      }
      is_shadow_banned_v1: { Args: never; Returns: boolean }
      is_user_auto_pending_v1: { Args: { p_user_id: string }; Returns: boolean }
      is_user_shadowed_v1: { Args: { p_user_id: string }; Returns: boolean }
      is_user_soft_limited_v1: { Args: { p_user_id: string }; Returns: boolean }
      join_collab_list_v1: { Args: { p_token: string }; Returns: Json }
      link_osm_boundary_parents_v1: { Args: never; Returns: number }
      list_active_suspended_meals_v1: {
        Args: { p_business_id: string; p_limit?: number }
        Returns: {
          amount_cents: number
          created_at: string
          currency: string
          expires_at: string
          id: string
          message: string
        }[]
      }
      list_audit_timeline_v1: {
        Args: {
          p_action?: string
          p_actor_id?: string
          p_from?: string
          p_limit?: number
          p_offset?: number
          p_target_id?: string
          p_target_type?: string
          p_to?: string
        }
        Returns: {
          action: string
          actor_id: string
          actor_role: string
          after_data: Json
          before_data: Json
          created_at: string
          id: string
          ip: string
          meta: Json
          target_id: string
          target_type: string
          user_agent: string
        }[]
      }
      list_audit_timeline_v2: {
        Args: {
          p_action?: string
          p_actor_id?: string
          p_business_id?: string
          p_from?: string
          p_limit?: number
          p_offset?: number
          p_q?: string
          p_target_id?: string
          p_target_type?: string
          p_to?: string
        }
        Returns: {
          action: string
          actor_id: string
          actor_role: string
          after_data: Json
          before_data: Json
          created_at: string
          id: string
          ip: string
          meta: Json
          target_id: string
          target_type: string
          user_agent: string
        }[]
      }
      list_customer_tags_v1: {
        Args: { p_business_id: string }
        Returns: string[]
      }
      list_email_campaigns_v1: {
        Args: { p_business_id: string; p_limit?: number; p_offset?: number }
        Returns: Json
      }
      list_group_requests_v1: {
        Args: {
          p_city?: string
          p_include_open?: boolean
          p_limit?: number
          p_offset?: number
          p_status?: string
        }
        Returns: {
          budget_total_cents: number
          category: string
          city: string
          created_at: string
          created_by: string
          currency: string
          date_time: string
          districts: string[]
          id: string
          notes: string
          party_size: number
          status: string
        }[]
      }
      list_menu_ai_analysis_v1: {
        Args: {
          p_business_id: string
          p_limit?: number
          p_ocr_job_id?: string
          p_offset?: number
          p_status?: string
        }
        Returns: {
          allergens_json: Json
          calorie_max: number
          calorie_min: number
          confidence: number
          created_at: string
          id: string
          ingredients_json: Json
          normalized_text: string
          ocr_job_id: string
          requires_review: boolean
          source_text: string
          status: string
        }[]
      }
      list_menu_item_translations_v1: {
        Args: {
          p_business_id: string
          p_limit?: number
          p_locale?: string
          p_menu_id?: string
          p_offset?: number
        }
        Returns: Json
      }
      list_menu_ocr_jobs_v1: {
        Args: { p_business_id: string; p_limit?: number; p_offset?: number }
        Returns: {
          created_at: string
          error_message: string
          file_name: string
          file_url: string
          id: string
          item_count: number
          status: string
          updated_at: string
        }[]
      }
      list_my_alert_events_v1: {
        Args: { p_limit?: number; p_offset?: number }
        Returns: {
          alert_id: string
          business_id: string
          created_at: string
          district_avg_price_cents: number
          id: string
          matched_price_cents: number
          menu_item_id: string
          previous_price_cents: number
        }[]
      }
      list_my_alerts_v1: {
        Args: { p_limit?: number; p_offset?: number }
        Returns: {
          category: string
          city: string
          created_at: string
          currency: string
          district: string
          id: string
          is_active: boolean
          max_price_cents: number
          query: string
        }[]
      }
      list_my_collections_v1: {
        Args: { p_limit?: number; p_offset?: number }
        Returns: {
          created_at: string
          id: string
          is_public: boolean
          items_count: number
          title: string
        }[]
      }
      list_open_requests_for_business_v1: {
        Args: {
          p_business_id?: string
          p_categories?: string[]
          p_city: string
          p_limit?: number
          p_offset?: number
        }
        Returns: {
          budget_total_cents: number
          category: string
          city: string
          created_at: string
          currency: string
          date_time: string
          districts: string[]
          id: string
          notes: string
          party_size: number
          status: string
        }[]
      }
      list_owner_analytics_hourly_v1: {
        Args: { p_business_id: string; p_hours?: number }
        Returns: Json
      }
      list_owner_analytics_v1: {
        Args: {
          p_business_id: string
          p_compare_branches?: boolean
          p_days?: number
        }
        Returns: Json
      }
      list_owner_menu_trash_v1: {
        Args: { p_business_id: string }
        Returns: {
          entity_id: string
          entity_type: string
          menu_id: string
          menu_item_id: string
          occurred_at: string
          photo_url: string
          subtitle: string
          title: string
        }[]
      }
      list_owner_menu_versions_v1: {
        Args: { p_menu_id: string }
        Returns: {
          created_at: string
          item_count: number
          menu_id: string
          menu_version: number
          section_count: number
          snapshot_id: string
          snapshot_reason: string
        }[]
      }
      list_push_campaigns_v1: {
        Args: { p_business_id: string; p_limit?: number; p_offset?: number }
        Returns: Json
      }
      list_team_members_v1: {
        Args: { p_business_id: string }
        Returns: {
          accepted_at: string
          created_at: string
          email: string
          membership_id: string
          role: string
          scope: string
          source: string
          status: string
          user_id: string
        }[]
      }
      log_admin_action_v1: {
        Args: {
          p_action: string
          p_meta?: Json
          p_target_id: string
          p_target_table: string
        }
        Returns: undefined
      }
      log_business_action_v1: {
        Args: {
          p_action: string
          p_business_id: string
          p_description: string
          p_meta?: Json
          p_target_id?: string
          p_target_label?: string
          p_target_table?: string
        }
        Returns: undefined
      }
      log_checkin_v1: {
        Args: {
          p_business_id: string
          p_client_id?: string
          p_menu_id?: string
          p_table_no?: string
        }
        Returns: Json
      }
      log_event_v1: {
        Args: {
          p_business_id?: string
          p_client_id?: string
          p_event_name: string
          p_menu_id?: string
          p_meta?: Json
          p_source?: string
        }
        Returns: Json
      }
      log_menu_activity_v1: {
        Args: { p_business_id: string; p_event: string; p_meta?: Json }
        Returns: undefined
      }
      longtransactionsenabled: { Args: never; Returns: boolean }
      mark_all_notifications_read_v1: { Args: never; Returns: number }
      mark_expired_temp_uploads_v1: {
        Args: { p_limit?: number }
        Returns: number
      }
      mark_notification_read_v1: {
        Args: { p_notification_id: string }
        Returns: boolean
      }
      mask_contact_tokens_v1: { Args: { p_text: string }; Returns: string }
      nearby_businesses_v2: {
        Args: {
          p_category?: string
          p_lat: number
          p_limit?: number
          p_lng: number
          p_offset?: number
          p_radius_m?: number
        }
        Returns: {
          address: string
          avg_rating: number
          category: string
          city: string
          cover_url: string
          distance_m: number
          district: string
          id: string
          is_active: boolean
          is_verified: boolean
          lat: number
          lng: number
          logo_url: string
          name: string
          neighborhood: string
          public_slug: string
          review_count: number
          slug: string
        }[]
      }
      normalize_for_moderation_v1: { Args: { p_text: string }; Returns: string }
      normalize_tr_location_text: { Args: { input: string }; Returns: string }
      normalize_tr_text: { Args: { p: string }; Returns: string }
      notify_favorite_revisit_reminders_v1: {
        Args: { p_batch_size?: number }
        Returns: number
      }
      notify_user_v1: {
        Args: {
          p_body: string
          p_data?: Json
          p_title: string
          p_type: string
          p_user_id: string
        }
        Returns: string
      }
      owner_add_business_to_chain_v1: {
        Args: {
          p_branch_label: string
          p_business_id: string
          p_chain_id: string
        }
        Returns: undefined
      }
      owner_approve_menu_price_suggestion_v1: {
        Args: { p_suggestion_id: string }
        Returns: Json
      }
      owner_approve_price_suggestion_v1: {
        Args: { p_suggestion_id: string }
        Returns: Json
      }
      owner_approve_suspended_claim_v1: {
        Args: { p_claim_id: string }
        Returns: Json
      }
      owner_archive_menu_item_v1: { Args: { p_item_id: string }; Returns: Json }
      owner_archive_menu_v1: { Args: { p_menu_id: string }; Returns: Json }
      owner_bulk_import_menu_items_v1: {
        Args: { p_menu_id: string; p_rows: Json }
        Returns: Json
      }
      owner_create_chain_v1: {
        Args: { p_business_id: string; p_chain_name: string }
        Returns: string
      }
      owner_create_menu_item_v1: {
        Args: {
          p_catalog_item_id?: number
          p_currency?: string
          p_description?: string
          p_name: string
          p_price_cents?: number
          p_section_id: string
        }
        Returns: Json
      }
      owner_create_menu_section_v1: {
        Args: { p_menu_id: string; p_sort_order?: number; p_title: string }
        Returns: Json
      }
      owner_create_menu_v1: {
        Args: {
          p_active_from?: string
          p_active_to?: string
          p_business_id: string
          p_kind?: string
          p_title: string
        }
        Returns: Json
      }
      owner_create_perk_v1: {
        Args: {
          p_business_id: string
          p_description?: string
          p_ends_at?: string
          p_requires_checkin?: boolean
          p_starts_at?: string
          p_title: string
        }
        Returns: Json
      }
      owner_delete_campaign_v1: {
        Args: { p_business_id: string; p_id: string }
        Returns: undefined
      }
      owner_delete_menu_item_v1: { Args: { p_item_id: string }; Returns: Json }
      owner_delete_menu_section_v1: {
        Args: { p_delete_items?: boolean; p_section_id: string }
        Returns: Json
      }
      owner_delete_menu_v1: { Args: { p_menu_id: string }; Returns: Json }
      owner_delete_qr_code_v1: {
        Args: { p_business_id: string; p_id: string }
        Returns: undefined
      }
      owner_delete_variant_group_v1: {
        Args: { p_group_id: string }
        Returns: Json
      }
      owner_delete_variant_option_v1: {
        Args: { p_option_id: string }
        Returns: Json
      }
      owner_empty_trash_v1: { Args: { p_business_id: string }; Returns: Json }
      owner_find_chained_business_v1: { Args: never; Returns: string }
      owner_force_delete_menu_item_photo_v1: {
        Args: { p_photo_id: string }
        Returns: Json
      }
      owner_force_delete_menu_item_v1: {
        Args: { p_item_id: string }
        Returns: Json
      }
      owner_force_delete_menu_v1: { Args: { p_menu_id: string }; Returns: Json }
      owner_fulfill_suspended_claim_v1: {
        Args: { p_claim_id: string; p_code: string }
        Returns: Json
      }
      owner_get_campaign_stats_v1: {
        Args: { p_business_id: string; p_period_days?: number }
        Returns: Json
      }
      owner_get_chain_overview_v1: {
        Args: { p_business_id: string }
        Returns: Json
      }
      owner_get_sponsorship_catalog_v1: {
        Args: { p_business_id: string }
        Returns: {
          business_impressions_30d: number
          business_live_units: number
          business_unique_users_30d: number
          currency_code: string
          duration_days: number
          inventory_limit: number
          latest_lead_status: string
          package_id: string
          package_name: string
          price_cents: number
          price_display: string
          surface: string
          surface_live_units: number
          surface_open_slots: number
        }[]
      }
      owner_kpi_summary_v1: {
        Args: { p_business_id: string; p_days?: number }
        Returns: {
          business_views: number
          directions_clicks: number
          outbound_clicks: number
          search_impressions: number
        }[]
      }
      owner_list_accessible_businesses_v1: {
        Args: {
          p_actor_user_id?: string
          p_limit?: number
          p_offset?: number
          p_role_override?: string
        }
        Returns: {
          branch_label: string
          business_id: string
          business_name: string
          chain_id: string
          chain_name: string
          city: string
          claim_status: string
          claimed_at: string
          district: string
          owner_role: string
        }[]
      }
      owner_list_addable_businesses_v1: {
        Args: never
        Returns: {
          business_id: string
          city: string
          name: string
        }[]
      }
      owner_list_campaigns_v1: {
        Args: {
          p_business_id: string
          p_page?: number
          p_page_size?: number
          p_status?: string
          p_type?: string
        }
        Returns: Json
      }
      owner_list_menu_price_suggestions_v1: {
        Args: {
          p_business_id: string
          p_limit?: number
          p_offset?: number
          p_status?: string
        }
        Returns: {
          created_at: string
          created_by: string
          currency: string
          current_price_cents: number
          item_name: string
          menu_item_id: string
          status: string
          suggested_price_cents: number
          suggestion_id: string
        }[]
      }
      owner_list_my_business_submissions_v1: {
        Args: { p_limit?: number; p_offset?: number; p_status?: string }
        Returns: {
          address: string
          admin_note: string
          category: string
          city: string
          created_at: string
          district: string
          id: string
          name: string
          phone: string
          status: string
          website: string
        }[]
      }
      owner_list_my_businesses_v1: {
        Args: { p_limit?: number; p_offset?: number; p_status?: string }
        Returns: {
          business_id: string
          business_name: string
          city: string
          claim_status: string
          claimed_at: string
          district: string
        }[]
      }
      owner_list_my_businesses_v2: {
        Args: { p_limit?: number; p_offset?: number; p_status?: string }
        Returns: {
          branch_label: string
          business_id: string
          business_name: string
          chain_id: string
          chain_name: string
          city: string
          claim_status: string
          claimed_at: string
          district: string
          owner_role: string
        }[]
      }
      owner_list_perks_v1: {
        Args: { p_business_id: string }
        Returns: {
          business_id: string
          created_at: string
          description: string
          ends_at: string
          id: string
          requires_checkin: boolean
          starts_at: string
          status: string
          title: string
        }[]
      }
      owner_list_price_suggestions_v1: {
        Args: {
          p_business_id: string
          p_limit: number
          p_offset: number
          p_status: string
        }
        Returns: {
          anomaly_flags: Json
          anomaly_score: number
          business_id: string
          business_name: string
          conflict_state: string
          conflict_variants_24h: number
          created_at: string
          created_by: string
          currency: string
          current_price_cents: number
          item_name: string
          menu_item_id: string
          quality_confidence: number
          status: string
          suggested_price_cents: number
          suggestion_id: string
        }[]
      }
      owner_list_qr_codes_v1: { Args: { p_business_id: string }; Returns: Json }
      owner_list_reservations_v1: {
        Args: {
          p_business_id: string
          p_date_from?: string
          p_date_to?: string
          p_limit?: number
          p_offset?: number
          p_status?: string
        }
        Returns: Json
      }
      owner_list_suspended_claims_v1: {
        Args: {
          p_business_id: string
          p_limit?: number
          p_offset?: number
          p_status?: string
        }
        Returns: {
          amount_cents: number
          claim_created_at: string
          claim_id: string
          claim_status: string
          claimant_name: string
          claimant_user_id: string
          currency: string
          fulfilled_at: string
          meal_id: string
          meal_message: string
          verify_code: string
        }[]
      }
      owner_override_price_suggestion_v1: {
        Args: {
          p_force_price_cents?: number
          p_reason: string
          p_suggestion_id: string
        }
        Returns: Json
      }
      owner_permanently_delete_menu_item_photo_v1: {
        Args: { p_photo_id: string }
        Returns: Json
      }
      owner_permanently_delete_menu_item_v1: {
        Args: { p_item_id: string }
        Returns: Json
      }
      owner_permanently_delete_menu_v1: {
        Args: { p_menu_id: string }
        Returns: Json
      }
      owner_publish_menu_item_v1: { Args: { p_item_id: string }; Returns: Json }
      owner_publish_menu_v1: { Args: { p_menu_id: string }; Returns: Json }
      owner_reject_menu_price_suggestion_v1: {
        Args: { p_note?: string; p_suggestion_id: string }
        Returns: Json
      }
      owner_reject_price_suggestion_v1: {
        Args: { p_reason?: string; p_suggestion_id: string }
        Returns: Json
      }
      owner_remove_business_from_chain_v1: {
        Args: { p_business_id: string }
        Returns: undefined
      }
      owner_reorder_chain_branch_v1: {
        Args: { p_business_id: string; p_new_sort_order: number }
        Returns: undefined
      }
      owner_reorder_menu_sections_v1: {
        Args: { p_menu_id: string; p_section_ids: string[] }
        Returns: Json
      }
      owner_restore_menu_item_photo_v1: {
        Args: { p_photo_id: string }
        Returns: Json
      }
      owner_restore_menu_item_v1: { Args: { p_item_id: string }; Returns: Json }
      owner_restore_menu_v1: { Args: { p_menu_id: string }; Returns: Json }
      owner_restore_menu_version_v1: {
        Args: { p_archive_current_menu_id?: string; p_snapshot_id: string }
        Returns: Json
      }
      owner_set_item_available_v1: {
        Args: { p_available: boolean; p_item_id: string }
        Returns: Json
      }
      owner_set_onboarding_progress_v1: {
        Args: { p_business_id: string; p_step_completed: number }
        Returns: Json
      }
      owner_set_perk_status_v1: {
        Args: { p_perk_id: string; p_status: string }
        Returns: Json
      }
      owner_soft_delete_menu_item_photo_v1: {
        Args: { p_photo_id: string }
        Returns: Json
      }
      owner_submit_new_business_v1: {
        Args: {
          p_address: string
          p_category: string
          p_city: string
          p_district: string
          p_name: string
          p_phone?: string
          p_website?: string
        }
        Returns: Json
      }
      owner_update_business_amenities_v1: {
        Args: { p_amenity_keys: string[]; p_business_id: string }
        Returns: Json
      }
      owner_update_business_commerce_links_v1: {
        Args: {
          p_business_id: string
          p_order_getir_url?: string
          p_order_trendyolgo_url?: string
          p_order_yemeksepeti_url?: string
          p_reservation_url?: string
        }
        Returns: Json
      }
      owner_update_business_location_v1: {
        Args: {
          p_address?: string
          p_business_id: string
          p_lat: number
          p_lng: number
        }
        Returns: Json
      }
      owner_update_business_meal_card_providers_v1: {
        Args: { p_business_id: string; p_provider_keys: string[] }
        Returns: Json
      }
      owner_update_business_profile_v1: {
        Args: {
          p_business_id: string
          p_cover_url?: string
          p_logo_url?: string
        }
        Returns: Json
      }
      owner_update_menu_item_v1: {
        Args: {
          p_catalog_item_id?: number
          p_currency?: string
          p_description?: string
          p_item_id: string
          p_name?: string
          p_price_cents?: number
        }
        Returns: Json
      }
      owner_update_menu_section_v1: {
        Args: { p_section_id: string; p_title: string }
        Returns: Json
      }
      owner_update_menu_v1: {
        Args: {
          p_active_from?: string
          p_active_to?: string
          p_kind?: string
          p_menu_id: string
          p_title?: string
        }
        Returns: Json
      }
      owner_update_reservation_status_v1: {
        Args: {
          p_business_id: string
          p_id: string
          p_owner_note?: string
          p_status: string
        }
        Returns: undefined
      }
      owner_upsert_business_hours_v1: {
        Args: { p_business_id: string; p_close: string; p_open: string }
        Returns: Json
      }
      owner_upsert_campaign_v1: {
        Args: {
          p_business_id: string
          p_description?: string
          p_discount_percent?: number
          p_ends_at?: string
          p_id?: string
          p_image_url?: string
          p_starts_at?: string
          p_status?: string
          p_title: string
          p_type: string
        }
        Returns: string
      }
      owner_upsert_menu_item_allergens_v1: {
        Args: { p_allergens: Json; p_item_id: string }
        Returns: Json
      }
      owner_upsert_menu_item_ingredients_v1: {
        Args: {
          p_detected_by?: string
          p_diet: Json
          p_ingredients: Json
          p_item_id: string
        }
        Returns: Json
      }
      owner_upsert_menu_item_nutrition_v1: {
        Args: {
          p_calorie_max: number
          p_calorie_min: number
          p_carbs_max_g: number
          p_carbs_min_g: number
          p_fat_max_g: number
          p_fat_min_g: number
          p_item_id: string
          p_protein_max_g: number
          p_protein_min_g: number
          p_serving_est_g?: number
          p_source?: string
          p_usda_fdc_ids?: Json
        }
        Returns: Json
      }
      owner_upsert_qr_code_v1: {
        Args: {
          p_business_id: string
          p_description?: string
          p_id?: string
          p_is_active?: boolean
          p_language?: string
          p_name: string
          p_target_url?: string
          p_type?: string
        }
        Returns: string
      }
      owner_upsert_variant_group_v1: {
        Args: {
          p_group_id?: string
          p_group_type?: string
          p_is_required?: boolean
          p_item_id: string
          p_name?: string
          p_selection?: string
          p_sort_order?: number
        }
        Returns: Json
      }
      owner_upsert_variant_option_v1: {
        Args: {
          p_group_id: string
          p_is_available?: boolean
          p_is_default?: boolean
          p_label?: string
          p_option_id?: string
          p_price_modifier_cents?: number
          p_sort_order?: number
        }
        Returns: Json
      }
      pick_one_menu_item_v1: {
        Args: { p_radius_km?: number; p_user_lat: number; p_user_lng: number }
        Returns: Json
      }
      populate_geometry_columns:
        | { Args: { tbl_oid: unknown; use_typmod?: boolean }; Returns: number }
        | { Args: { use_typmod?: boolean }; Returns: string }
      postgis_constraint_dims: {
        Args: { geomcolumn: string; geomschema: string; geomtable: string }
        Returns: number
      }
      postgis_constraint_srid: {
        Args: { geomcolumn: string; geomschema: string; geomtable: string }
        Returns: number
      }
      postgis_constraint_type: {
        Args: { geomcolumn: string; geomschema: string; geomtable: string }
        Returns: string
      }
      postgis_extensions_upgrade: { Args: never; Returns: string }
      postgis_full_version: { Args: never; Returns: string }
      postgis_geos_version: { Args: never; Returns: string }
      postgis_lib_build_date: { Args: never; Returns: string }
      postgis_lib_revision: { Args: never; Returns: string }
      postgis_lib_version: { Args: never; Returns: string }
      postgis_libjson_version: { Args: never; Returns: string }
      postgis_liblwgeom_version: { Args: never; Returns: string }
      postgis_libprotobuf_version: { Args: never; Returns: string }
      postgis_libxml_version: { Args: never; Returns: string }
      postgis_proj_version: { Args: never; Returns: string }
      postgis_scripts_build_date: { Args: never; Returns: string }
      postgis_scripts_installed: { Args: never; Returns: string }
      postgis_scripts_released: { Args: never; Returns: string }
      postgis_svn_version: { Args: never; Returns: string }
      postgis_type_name: {
        Args: {
          coord_dimension: number
          geomname: string
          use_new_name?: boolean
        }
        Returns: string
      }
      postgis_version: { Args: never; Returns: string }
      postgis_wagyu_version: { Args: never; Returns: string }
      profile_level_from_xp_v1: {
        Args: { p_total_xp: number }
        Returns: number
      }
      promote_temp_upload_to_menu_asset_v1: {
        Args: {
          p_asset_type: string
          p_menu_version: number
          p_temp_upload_id: string
        }
        Returns: Json
      }
      public_list_incident_updates_v1: {
        Args: { p_limit?: number }
        Returns: {
          action_taken: string
          created_at: string
          id: string
          incident_key: string
          status: string
          summary: string
          title: string
        }[]
      }
      public_menu_share_view_v1: { Args: { p_menu_id: string }; Returns: Json }
      purge_expired_business_audit_log: { Args: never; Returns: undefined }
      purge_rate_limit_buckets_v1: { Args: never; Returns: undefined }
      recompute_business_last_review_at: {
        Args: { p_business_id: string }
        Returns: string
      }
      recompute_profile_progress_v1: {
        Args: { p_user_id: string }
        Returns: undefined
      }
      recompute_user_achievements_v1: {
        Args: { p_user_id: string }
        Returns: undefined
      }
      record_user_device_fingerprint_v1: {
        Args: { p_fingerprint: string; p_user_id: string }
        Returns: Json
      }
      record_user_risk_signal_v1: {
        Args: {
          p_ip_hash?: string
          p_signal_key: string
          p_signal_meta?: Json
          p_signal_weight?: number
          p_user_id: string
        }
        Returns: Json
      }
      redeem_loyalty_reward_v1: { Args: { p_member_id: string }; Returns: Json }
      refresh_businesses_with_stats_mv: { Args: never; Returns: undefined }
      register_user_device_v1: {
        Args: {
          p_app_version?: string
          p_fcm_token: string
          p_platform: string
        }
        Returns: string
      }
      reject_menu_ai_analysis_v1: {
        Args: { p_analysis_id: string }
        Returns: undefined
      }
      reject_owner_claim: {
        Args: { p_claim_id: string; p_note?: string }
        Returns: undefined
      }
      remove_customer_tag_v1: { Args: { p_tag_id: string }; Returns: undefined }
      remove_from_collection_v1: {
        Args: { p_business_id: string; p_collection_id: string }
        Returns: Json
      }
      request_header_v1: { Args: { p_name: string }; Returns: string }
      request_ip_v1: { Args: never; Returns: unknown }
      resolve_actor_role_v1: { Args: { p_user_id: string }; Returns: string }
      revoke_team_member_v1: {
        Args: { p_business_id: string; p_membership_id: string }
        Returns: Json
      }
      round_coord_3dp_v1: { Args: { p_value: number }; Returns: number }
      sanitize_geo_jsonb_v1: { Args: { p_meta: Json }; Returns: Json }
      sanitize_plain_text_v1: { Args: { p_text: string }; Returns: string }
      scan_loyalty_qr_v1: {
        Args: { p_amount?: number; p_business_id: string; p_user_id: string }
        Returns: Json
      }
      scheduled_menu_activation: { Args: never; Returns: undefined }
      search_admin_v1: {
        Args: { p_limit?: number; p_q: string }
        Returns: {
          category: string
          created_at: string
          item_id: string
          meta: Json
          score: number
          search_token: string
          subtitle: string
          title: string
        }[]
      }
      search_businesses_in_boundary_v1: {
        Args: {
          p_boundary_id: string
          p_limit?: number
          p_offset?: number
          p_query: string
        }
        Returns: {
          address: string
          avg_rating: number
          category: string
          id: string
          lat: number
          lng: number
          name: string
          review_count: number
          slug: string
        }[]
      }
      search_businesses_v1: {
        Args: {
          p_city?: string
          p_district?: string
          p_lat?: number
          p_limit?: number
          p_lng?: number
          p_offset?: number
          p_query: string
          p_radius_km?: number
        }
        Returns: {
          address: string
          avg_rating: number
          category: string
          city: string
          distance_km: number
          district: string
          id: string
          is_active: boolean
          is_open_now: boolean
          lat: number
          lng: number
          meal_card_providers: Json
          median_price_cents: number
          name: string
          owner_verified: boolean
          quality_score: number
          recent_price_verified_count: number
          review_count: number
          slug: string
          trust_score: number
        }[]
      }
      search_food_catalog_v1: {
        Args: { p_limit?: number; p_q: string }
        Returns: {
          category_id: string
          category_name: string
          id: number
          name: string
        }[]
      }
      search_menu_items_v1: {
        Args: {
          p_is_gluten_free?: boolean
          p_is_halal?: boolean
          p_is_lactose_free?: boolean
          p_is_vegan?: boolean
          p_is_vegetarian?: boolean
          p_limit?: number
          p_max_calories?: number
          p_offset?: number
          p_q?: string
          p_radius_km?: number
          p_user_lat: number
          p_user_lng: number
          p_verified_price_only?: boolean
        }
        Returns: {
          address: string
          bad_30d: number
          business_id: string
          business_name: string
          calories: number
          city: string
          currency: string
          distance_km: number
          district: string
          is_gluten_free: boolean
          is_halal: boolean
          is_lactose_free: boolean
          is_vegan: boolean
          is_vegetarian: boolean
          item_description: string
          item_name: string
          menu_item_id: string
          ok_30d: number
          price_cents: number
          price_status: string
        }[]
      }
      search_menu_items_v2: {
        Args: {
          p_is_gluten_free?: boolean
          p_is_halal?: boolean
          p_is_lactose_free?: boolean
          p_is_vegan?: boolean
          p_is_vegetarian?: boolean
          p_limit?: number
          p_max_calories?: number
          p_offset?: number
          p_q?: string
          p_radius_km?: number
          p_user_lat: number
          p_user_lng: number
          p_verified_price_only?: boolean
        }
        Returns: {
          address: string
          bad_30d: number
          business_id: string
          business_name: string
          calories: number
          city: string
          currency: string
          distance_km: number
          district: string
          image_url: string
          is_gluten_free: boolean
          is_halal: boolean
          is_lactose_free: boolean
          is_today_special: boolean
          is_vegan: boolean
          is_vegetarian: boolean
          item_description: string
          item_name: string
          menu_item_id: string
          ok_30d: number
          price_cents: number
          price_status: string
          special_note: string
        }[]
      }
      search_nearby_businesses_v1: {
        Args: {
          p_category?: string
          p_lat: number
          p_limit?: number
          p_lng: number
          p_query?: string
          p_radius_km?: number
        }
        Returns: {
          address: string
          category: string
          city: string
          distance_km: number
          district: string
          id: string
          lat: number
          lng: number
          name: string
        }[]
      }
      search_nearby_businesses_v2: {
        Args: {
          p_category?: string
          p_lat: number
          p_limit?: number
          p_lng: number
          p_query?: string
          p_radius_km?: number
        }
        Returns: {
          address: string
          category: string
          city: string
          distance_km: number
          district: string
          id: string
          lat: number
          lng: number
          name: string
          quality_score: number
        }[]
      }
      search_nearby_businesses_v3:
        | {
            Args: {
              p_category?: string
              p_lat: number
              p_limit?: number
              p_lng: number
              p_open_now?: boolean
              p_query?: string
              p_radius_km?: number
            }
            Returns: {
              address: string
              category: string
              city: string
              distance_km: number
              district: string
              id: string
              is_open_now: boolean
              lat: number
              lng: number
              median_price_cents: number
              name: string
              quality_score: number
            }[]
          }
        | {
            Args: {
              p_city?: string
              p_district?: string
              p_limit?: number
              p_offset?: number
              p_query?: string
              p_radius_km?: number
              p_user_lat: number
              p_user_lng: number
            }
            Returns: {
              address: string
              category: string
              city: string
              distance_km: number
              district: string
              id: string
              is_open_now: boolean
              lat: number
              lng: number
              median_price_cents: number
              name: string
              price_level: string
            }[]
          }
      send_business_campaign_v1: {
        Args: { p_business_id: string; p_message: string; p_title: string }
        Returns: Json
      }
      set_active_menu_v1: {
        Args: { p_business_id: string; p_menu_id: string }
        Returns: Json
      }
      set_favorite_email_optin_v1: {
        Args: { p_business_id: string; p_email_optin: boolean }
        Returns: Json
      }
      set_favorite_v2: {
        Args: {
          p_business_id: string
          p_idempotency_key?: string
          p_is_favorited: boolean
        }
        Returns: Json
      }
      set_follow_v2: {
        Args: {
          p_followee_id: string
          p_following: boolean
          p_idempotency_key?: string
        }
        Returns: Json
      }
      set_group_offer_vote_v2: {
        Args: {
          p_idempotency_key?: string
          p_offer_id: string
          p_voted: boolean
        }
        Returns: Json
      }
      set_loyalty_program_active_v1: {
        Args: { p_is_active: boolean; p_program_id: string }
        Returns: undefined
      }
      set_menu_item_nutrition_v1: {
        Args: {
          p_calories_max?: number
          p_calories_min?: number
          p_menu_item_id: string
          p_portion_size?: number
          p_portion_unit?: string
        }
        Returns: Json
      }
      set_menu_item_photo_vote_v2: {
        Args: { p_idempotency_key?: string; p_photo_id: string; p_vote: number }
        Returns: Json
      }
      set_menu_item_price_vote_v2: {
        Args: {
          p_idempotency_key?: string
          p_menu_item_id: string
          p_vote: number
        }
        Returns: Json
      }
      set_today_special_v1: {
        Args: { p_is_special: boolean; p_menu_item_id: string; p_note?: string }
        Returns: Json
      }
      st_3dclosestpoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_3ddistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_3dintersects: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_3dlongestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_3dmakebox: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_3dmaxdistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_3dshortestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_addpoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_angle:
        | { Args: { line1: unknown; line2: unknown }; Returns: number }
        | {
            Args: { pt1: unknown; pt2: unknown; pt3: unknown; pt4?: unknown }
            Returns: number
          }
      st_area:
        | { Args: { geog: unknown; use_spheroid?: boolean }; Returns: number }
        | { Args: { "": string }; Returns: number }
      st_asencodedpolyline: {
        Args: { geom: unknown; nprecision?: number }
        Returns: string
      }
      st_asewkt: { Args: { "": string }; Returns: string }
      st_asgeojson:
        | {
            Args: { geog: unknown; maxdecimaldigits?: number; options?: number }
            Returns: string
          }
        | {
            Args: { geom: unknown; maxdecimaldigits?: number; options?: number }
            Returns: string
          }
        | {
            Args: {
              geom_column?: string
              maxdecimaldigits?: number
              pretty_bool?: boolean
              r: Record<string, unknown>
            }
            Returns: string
          }
        | { Args: { "": string }; Returns: string }
      st_asgml:
        | {
            Args: {
              geog: unknown
              id?: string
              maxdecimaldigits?: number
              nprefix?: string
              options?: number
            }
            Returns: string
          }
        | {
            Args: { geom: unknown; maxdecimaldigits?: number; options?: number }
            Returns: string
          }
        | { Args: { "": string }; Returns: string }
        | {
            Args: {
              geog: unknown
              id?: string
              maxdecimaldigits?: number
              nprefix?: string
              options?: number
              version: number
            }
            Returns: string
          }
        | {
            Args: {
              geom: unknown
              id?: string
              maxdecimaldigits?: number
              nprefix?: string
              options?: number
              version: number
            }
            Returns: string
          }
      st_askml:
        | {
            Args: { geog: unknown; maxdecimaldigits?: number; nprefix?: string }
            Returns: string
          }
        | {
            Args: { geom: unknown; maxdecimaldigits?: number; nprefix?: string }
            Returns: string
          }
        | { Args: { "": string }; Returns: string }
      st_aslatlontext: {
        Args: { geom: unknown; tmpl?: string }
        Returns: string
      }
      st_asmarc21: { Args: { format?: string; geom: unknown }; Returns: string }
      st_asmvtgeom: {
        Args: {
          bounds: unknown
          buffer?: number
          clip_geom?: boolean
          extent?: number
          geom: unknown
        }
        Returns: unknown
      }
      st_assvg:
        | {
            Args: { geog: unknown; maxdecimaldigits?: number; rel?: number }
            Returns: string
          }
        | {
            Args: { geom: unknown; maxdecimaldigits?: number; rel?: number }
            Returns: string
          }
        | { Args: { "": string }; Returns: string }
      st_astext: { Args: { "": string }; Returns: string }
      st_astwkb:
        | {
            Args: {
              geom: unknown
              prec?: number
              prec_m?: number
              prec_z?: number
              with_boxes?: boolean
              with_sizes?: boolean
            }
            Returns: string
          }
        | {
            Args: {
              geom: unknown[]
              ids: number[]
              prec?: number
              prec_m?: number
              prec_z?: number
              with_boxes?: boolean
              with_sizes?: boolean
            }
            Returns: string
          }
      st_asx3d: {
        Args: { geom: unknown; maxdecimaldigits?: number; options?: number }
        Returns: string
      }
      st_azimuth:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: number }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: number }
      st_boundingdiagonal: {
        Args: { fits?: boolean; geom: unknown }
        Returns: unknown
      }
      st_buffer:
        | {
            Args: { geom: unknown; options?: string; radius: number }
            Returns: unknown
          }
        | {
            Args: { geom: unknown; quadsegs: number; radius: number }
            Returns: unknown
          }
      st_centroid: { Args: { "": string }; Returns: unknown }
      st_clipbybox2d: {
        Args: { box: unknown; geom: unknown }
        Returns: unknown
      }
      st_closestpoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_collect: { Args: { geom1: unknown; geom2: unknown }; Returns: unknown }
      st_concavehull: {
        Args: {
          param_allow_holes?: boolean
          param_geom: unknown
          param_pctconvex: number
        }
        Returns: unknown
      }
      st_contains: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_containsproperly: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_coorddim: { Args: { geometry: unknown }; Returns: number }
      st_coveredby:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_covers:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_crosses: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_curvetoline: {
        Args: { flags?: number; geom: unknown; tol?: number; toltype?: number }
        Returns: unknown
      }
      st_delaunaytriangles: {
        Args: { flags?: number; g1: unknown; tolerance?: number }
        Returns: unknown
      }
      st_difference: {
        Args: { geom1: unknown; geom2: unknown; gridsize?: number }
        Returns: unknown
      }
      st_disjoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_distance:
        | {
            Args: { geog1: unknown; geog2: unknown; use_spheroid?: boolean }
            Returns: number
          }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: number }
      st_distancesphere:
        | { Args: { geom1: unknown; geom2: unknown }; Returns: number }
        | {
            Args: { geom1: unknown; geom2: unknown; radius: number }
            Returns: number
          }
      st_distancespheroid: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_dwithin: {
        Args: {
          geog1: unknown
          geog2: unknown
          tolerance: number
          use_spheroid?: boolean
        }
        Returns: boolean
      }
      st_equals: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_expand:
        | { Args: { box: unknown; dx: number; dy: number }; Returns: unknown }
        | {
            Args: { box: unknown; dx: number; dy: number; dz?: number }
            Returns: unknown
          }
        | {
            Args: {
              dm?: number
              dx: number
              dy: number
              dz?: number
              geom: unknown
            }
            Returns: unknown
          }
      st_force3d: { Args: { geom: unknown; zvalue?: number }; Returns: unknown }
      st_force3dm: {
        Args: { geom: unknown; mvalue?: number }
        Returns: unknown
      }
      st_force3dz: {
        Args: { geom: unknown; zvalue?: number }
        Returns: unknown
      }
      st_force4d: {
        Args: { geom: unknown; mvalue?: number; zvalue?: number }
        Returns: unknown
      }
      st_generatepoints:
        | { Args: { area: unknown; npoints: number }; Returns: unknown }
        | {
            Args: { area: unknown; npoints: number; seed: number }
            Returns: unknown
          }
      st_geogfromtext: { Args: { "": string }; Returns: unknown }
      st_geographyfromtext: { Args: { "": string }; Returns: unknown }
      st_geohash:
        | { Args: { geog: unknown; maxchars?: number }; Returns: string }
        | { Args: { geom: unknown; maxchars?: number }; Returns: string }
      st_geomcollfromtext: { Args: { "": string }; Returns: unknown }
      st_geometricmedian: {
        Args: {
          fail_if_not_converged?: boolean
          g: unknown
          max_iter?: number
          tolerance?: number
        }
        Returns: unknown
      }
      st_geometryfromtext: { Args: { "": string }; Returns: unknown }
      st_geomfromewkt: { Args: { "": string }; Returns: unknown }
      st_geomfromgeojson:
        | { Args: { "": Json }; Returns: unknown }
        | { Args: { "": Json }; Returns: unknown }
        | { Args: { "": string }; Returns: unknown }
      st_geomfromgml: { Args: { "": string }; Returns: unknown }
      st_geomfromkml: { Args: { "": string }; Returns: unknown }
      st_geomfrommarc21: { Args: { marc21xml: string }; Returns: unknown }
      st_geomfromtext: { Args: { "": string }; Returns: unknown }
      st_gmltosql: { Args: { "": string }; Returns: unknown }
      st_hasarc: { Args: { geometry: unknown }; Returns: boolean }
      st_hausdorffdistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_hexagon: {
        Args: { cell_i: number; cell_j: number; origin?: unknown; size: number }
        Returns: unknown
      }
      st_hexagongrid: {
        Args: { bounds: unknown; size: number }
        Returns: Record<string, unknown>[]
      }
      st_interpolatepoint: {
        Args: { line: unknown; point: unknown }
        Returns: number
      }
      st_intersection: {
        Args: { geom1: unknown; geom2: unknown; gridsize?: number }
        Returns: unknown
      }
      st_intersects:
        | { Args: { geog1: unknown; geog2: unknown }; Returns: boolean }
        | { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_isvaliddetail: {
        Args: { flags?: number; geom: unknown }
        Returns: Database["public"]["CompositeTypes"]["valid_detail"]
        SetofOptions: {
          from: "*"
          to: "valid_detail"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      st_length:
        | { Args: { geog: unknown; use_spheroid?: boolean }; Returns: number }
        | { Args: { "": string }; Returns: number }
      st_letters: { Args: { font?: Json; letters: string }; Returns: unknown }
      st_linecrossingdirection: {
        Args: { line1: unknown; line2: unknown }
        Returns: number
      }
      st_linefromencodedpolyline: {
        Args: { nprecision?: number; txtin: string }
        Returns: unknown
      }
      st_linefromtext: { Args: { "": string }; Returns: unknown }
      st_linelocatepoint: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_linetocurve: { Args: { geometry: unknown }; Returns: unknown }
      st_locatealong: {
        Args: { geometry: unknown; leftrightoffset?: number; measure: number }
        Returns: unknown
      }
      st_locatebetween: {
        Args: {
          frommeasure: number
          geometry: unknown
          leftrightoffset?: number
          tomeasure: number
        }
        Returns: unknown
      }
      st_locatebetweenelevations: {
        Args: { fromelevation: number; geometry: unknown; toelevation: number }
        Returns: unknown
      }
      st_longestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_makebox2d: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_makeline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_makevalid: {
        Args: { geom: unknown; params: string }
        Returns: unknown
      }
      st_maxdistance: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: number
      }
      st_minimumboundingcircle: {
        Args: { inputgeom: unknown; segs_per_quarter?: number }
        Returns: unknown
      }
      st_mlinefromtext: { Args: { "": string }; Returns: unknown }
      st_mpointfromtext: { Args: { "": string }; Returns: unknown }
      st_mpolyfromtext: { Args: { "": string }; Returns: unknown }
      st_multilinestringfromtext: { Args: { "": string }; Returns: unknown }
      st_multipointfromtext: { Args: { "": string }; Returns: unknown }
      st_multipolygonfromtext: { Args: { "": string }; Returns: unknown }
      st_node: { Args: { g: unknown }; Returns: unknown }
      st_normalize: { Args: { geom: unknown }; Returns: unknown }
      st_offsetcurve: {
        Args: { distance: number; line: unknown; params?: string }
        Returns: unknown
      }
      st_orderingequals: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_overlaps: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: boolean
      }
      st_perimeter: {
        Args: { geog: unknown; use_spheroid?: boolean }
        Returns: number
      }
      st_pointfromtext: { Args: { "": string }; Returns: unknown }
      st_pointm: {
        Args: {
          mcoordinate: number
          srid?: number
          xcoordinate: number
          ycoordinate: number
        }
        Returns: unknown
      }
      st_pointz: {
        Args: {
          srid?: number
          xcoordinate: number
          ycoordinate: number
          zcoordinate: number
        }
        Returns: unknown
      }
      st_pointzm: {
        Args: {
          mcoordinate: number
          srid?: number
          xcoordinate: number
          ycoordinate: number
          zcoordinate: number
        }
        Returns: unknown
      }
      st_polyfromtext: { Args: { "": string }; Returns: unknown }
      st_polygonfromtext: { Args: { "": string }; Returns: unknown }
      st_project: {
        Args: { azimuth: number; distance: number; geog: unknown }
        Returns: unknown
      }
      st_quantizecoordinates: {
        Args: {
          g: unknown
          prec_m?: number
          prec_x: number
          prec_y?: number
          prec_z?: number
        }
        Returns: unknown
      }
      st_reduceprecision: {
        Args: { geom: unknown; gridsize: number }
        Returns: unknown
      }
      st_relate: { Args: { geom1: unknown; geom2: unknown }; Returns: string }
      st_removerepeatedpoints: {
        Args: { geom: unknown; tolerance?: number }
        Returns: unknown
      }
      st_segmentize: {
        Args: { geog: unknown; max_segment_length: number }
        Returns: unknown
      }
      st_setsrid:
        | { Args: { geog: unknown; srid: number }; Returns: unknown }
        | { Args: { geom: unknown; srid: number }; Returns: unknown }
      st_sharedpaths: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_shortestline: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_simplifypolygonhull: {
        Args: { geom: unknown; is_outer?: boolean; vertex_fraction: number }
        Returns: unknown
      }
      st_split: { Args: { geom1: unknown; geom2: unknown }; Returns: unknown }
      st_square: {
        Args: { cell_i: number; cell_j: number; origin?: unknown; size: number }
        Returns: unknown
      }
      st_squaregrid: {
        Args: { bounds: unknown; size: number }
        Returns: Record<string, unknown>[]
      }
      st_srid:
        | { Args: { geog: unknown }; Returns: number }
        | { Args: { geom: unknown }; Returns: number }
      st_subdivide: {
        Args: { geom: unknown; gridsize?: number; maxvertices?: number }
        Returns: unknown[]
      }
      st_swapordinates: {
        Args: { geom: unknown; ords: unknown }
        Returns: unknown
      }
      st_symdifference: {
        Args: { geom1: unknown; geom2: unknown; gridsize?: number }
        Returns: unknown
      }
      st_symmetricdifference: {
        Args: { geom1: unknown; geom2: unknown }
        Returns: unknown
      }
      st_tileenvelope: {
        Args: {
          bounds?: unknown
          margin?: number
          x: number
          y: number
          zoom: number
        }
        Returns: unknown
      }
      st_touches: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_transform:
        | {
            Args: { from_proj: string; geom: unknown; to_proj: string }
            Returns: unknown
          }
        | {
            Args: { from_proj: string; geom: unknown; to_srid: number }
            Returns: unknown
          }
        | { Args: { geom: unknown; to_proj: string }; Returns: unknown }
      st_triangulatepolygon: { Args: { g1: unknown }; Returns: unknown }
      st_union:
        | { Args: { geom1: unknown; geom2: unknown }; Returns: unknown }
        | {
            Args: { geom1: unknown; geom2: unknown; gridsize: number }
            Returns: unknown
          }
      st_voronoilines: {
        Args: { extend_to?: unknown; g1: unknown; tolerance?: number }
        Returns: unknown
      }
      st_voronoipolygons: {
        Args: { extend_to?: unknown; g1: unknown; tolerance?: number }
        Returns: unknown
      }
      st_within: { Args: { geom1: unknown; geom2: unknown }; Returns: boolean }
      st_wkbtosql: { Args: { wkb: string }; Returns: unknown }
      st_wkttosql: { Args: { "": string }; Returns: unknown }
      st_wrapx: {
        Args: { geom: unknown; move: number; wrap: number }
        Returns: unknown
      }
      submit_account_deletion_request_v1: {
        Args: { p_reason?: string }
        Returns: undefined
      }
      submit_business_suggestion:
        | {
            Args: {
              p_address: string
              p_category: string
              p_city: string
              p_district: string
              p_name: string
              p_note?: string
            }
            Returns: number
          }
        | {
            Args: {
              p_address?: string
              p_category: string
              p_city?: string
              p_district?: string
              p_name: string
              p_notes?: string
              p_phone?: string
              p_website?: string
            }
            Returns: string
          }
      submit_business_suggestion_v1: {
        Args: {
          p_address?: string
          p_category: string
          p_city?: string
          p_district?: string
          p_name: string
          p_notes?: string
          p_phone?: string
          p_website?: string
        }
        Returns: Json
      }
      submit_business_suggestion_v2: {
        Args: {
          p_address?: string
          p_category: string
          p_city?: string
          p_district?: string
          p_idempotency_key?: string
          p_name: string
          p_notes?: string
          p_phone?: string
          p_website?: string
        }
        Returns: Json
      }
      submit_checkin_v1: {
        Args: { p_business_id: string; p_note?: string }
        Returns: Json
      }
      submit_group_offer_v1: {
        Args: {
          p_business_id: string
          p_includes?: Json
          p_message?: string
          p_offered_total_cents: number
          p_request_id: string
        }
        Returns: Json
      }
      submit_menu_item_price_suggestion_v1: {
        Args: {
          p_currency?: string
          p_menu_item_id: string
          p_note?: string
          p_suggested_price_cents: number
        }
        Returns: Json
      }
      submit_menu_item_price_suggestion_v2: {
        Args: {
          p_currency?: string
          p_evidence_url?: string
          p_menu_item_id: string
          p_note?: string
          p_suggested_price_cents: number
        }
        Returns: Json
      }
      submit_menu_item_price_suggestion_v3: {
        Args: {
          p_captured_at?: string
          p_client_id?: string
          p_currency?: string
          p_evidence_url?: string
          p_menu_item_id: string
          p_note?: string
          p_suggested_price_cents: number
        }
        Returns: Json
      }
      submit_menu_item_price_suggestion_v4: {
        Args: {
          p_captured_at?: string
          p_client_id?: string
          p_currency?: string
          p_evidence_url?: string
          p_menu_item_id: string
          p_note?: string
          p_suggested_price_cents: number
        }
        Returns: Json
      }
      submit_menu_item_price_suggestion_v5: {
        Args: {
          p_captured_at?: string
          p_client_id?: string
          p_currency?: string
          p_evidence_url?: string
          p_idempotency_key?: string
          p_menu_item_id: string
          p_note?: string
          p_suggested_price_cents: number
        }
        Returns: Json
      }
      submit_menu_item_suggestion_v1: {
        Args: {
          p_action: string
          p_business_id: string
          p_menu_item_id: string
          p_payload: Json
        }
        Returns: Json
      }
      submit_menu_item_suggestion_v2: {
        Args: {
          p_action: string
          p_business_id: string
          p_idempotency_key?: string
          p_menu_item_id: string
          p_payload: Json
        }
        Returns: Json
      }
      submit_mission_proof_v1: {
        Args: { p_mission_id: string; p_photo_id: string }
        Returns: Json
      }
      submit_moderation_appeal_v1: {
        Args: {
          p_details?: string
          p_reason: string
          p_source_id: string
          p_source_type: string
        }
        Returns: Json
      }
      submit_owner_claim_v1: {
        Args: {
          p_business_id: string
          p_evidence_storage_path?: string
          p_evidence_url?: string
          p_full_name: string
          p_note?: string
          p_phone: string
        }
        Returns: Json
      }
      submit_owner_review_reply_v1: {
        Args: { p_reply_text: string; p_review_id: string }
        Returns: Json
      }
      submit_presence_v1: {
        Args: { p_business_id: string; p_crowd: string }
        Returns: Json
      }
      submit_presence_v2: {
        Args: {
          p_business_id: string
          p_crowd: string
          p_idempotency_key?: string
        }
        Returns: Json
      }
      submit_privacy_request_v1: {
        Args: { p_details?: string; p_request_type: string }
        Returns: undefined
      }
      submit_receipt_submission_v1: {
        Args: { p_business_id: string; p_image_url: string; p_matches?: Json }
        Returns: Json
      }
      submit_report_v1:
        | {
            Args: {
              p_business_id?: string
              p_details?: string
              p_menu_item_photo_id?: string
              p_reason?: string
              p_review_id?: string
            }
            Returns: Json
          }
        | {
            Args: {
              p_business_id?: string
              p_details?: string
              p_reason?: string
              p_review_id?: string
            }
            Returns: Json
          }
      submit_report_v2: {
        Args: {
          p_business_id?: string
          p_details?: string
          p_idempotency_key?: string
          p_menu_item_photo_id?: string
          p_reason?: string
          p_review_id?: string
        }
        Returns: Json
      }
      submit_review_reply: {
        Args: { p_content: string; p_review_id: string }
        Returns: Json
      }
      submit_review_v1: {
        Args: {
          p_business_id: string
          p_content?: string
          p_rating: number
          p_title?: string
        }
        Returns: Json
      }
      submit_review_v2: {
        Args: {
          p_business_id: string
          p_content?: string
          p_idempotency_key?: string
          p_rating: number
          p_title?: string
        }
        Returns: Json
      }
      submit_review_v3: {
        Args: {
          p_atmosphere_rating?: number
          p_business_id: string
          p_cleanliness_rating?: number
          p_content?: string
          p_idempotency_key?: string
          p_overall_rating: number
          p_price_performance_rating?: number
          p_service_speed_rating?: number
          p_taste_rating?: number
          p_title?: string
        }
        Returns: Json
      }
      submit_sponsorship_lead_v1: {
        Args: {
          p_business_id: string
          p_message: string
          p_phone: string
          p_preferred_surface: string
          p_preferred_targeting?: Json
        }
        Returns: Json
      }
      submit_suspended_meal_claim_v1: {
        Args: { p_note?: string; p_suspended_meal_id: string }
        Returns: Json
      }
      submit_table_feedback_v1: {
        Args: {
          p_business_id: string
          p_client_id?: string
          p_note?: string
          p_rating: number
          p_table_no: string
        }
        Returns: Json
      }
      submit_table_order_v1: {
        Args: {
          p_business_id: string
          p_items_json: Json
          p_note?: string
          p_table_number: string
        }
        Returns: Json
      }
      taste_recommendations_from_match_v1: {
        Args: { p_limit?: number; p_match_user_id: string }
        Returns: {
          business_id: string
          business_name: string
          city: string
          district: string
          match_rating: number
          match_review_excerpt: string
          match_review_title: string
        }[]
      }
      taste_recommendations_from_match_v2: {
        Args: { p_limit?: number; p_match_user_id: string }
        Returns: {
          business_id: string
          business_name: string
          city: string
          district: string
          match_rating: number
          match_review_created_at: string
          match_review_excerpt: string
          match_review_title: string
        }[]
      }
      tg_business_stats_apply_review_change_old_business: {
        Args: {
          p_business_id: string
          p_old_created: string
          p_old_rating: number
        }
        Returns: undefined
      }
      toggle_collection_follow_v1: {
        Args: { p_collection_key: string }
        Returns: {
          followers_count: number
          is_following: boolean
        }[]
      }
      toggle_favorite_v1: {
        Args: { p_business_id: string }
        Returns: {
          is_favorited: boolean
        }[]
      }
      toggle_follow_v1: { Args: { p_followee_id: string }; Returns: Json }
      toggle_saved_campaign_v1: { Args: { p_story_id: string }; Returns: Json }
      touch_support_ticket_v1: {
        Args: { p_ticket_id: string }
        Returns: undefined
      }
      unfollow_business_v1: { Args: { p_business_id: string }; Returns: Json }
      unlockrows: { Args: { "": string }; Returns: number }
      unregister_user_device_v1: {
        Args: { p_fcm_token?: string }
        Returns: number
      }
      update_business_follow_email_subscription_v1: {
        Args: { p_business_id: string; p_subscribed: boolean }
        Returns: undefined
      }
      update_loyalty_program_v1: {
        Args: {
          p_name: string
          p_program_id: string
          p_reward_desc: string
          p_reward_threshold: number
        }
        Returns: undefined
      }
      update_menu_item_availability_v1: {
        Args: { p_available: boolean; p_item_id: string }
        Returns: undefined
      }
      update_my_marketing_email_opt_in_v1: {
        Args: { p_value: boolean }
        Returns: undefined
      }
      update_table_order_status_v1: {
        Args: { p_order_id: string; p_status: string }
        Returns: Json
      }
      update_team_member_v1: {
        Args: {
          p_business_id: string
          p_membership_id: string
          p_role: string
          p_scope?: string
        }
        Returns: Json
      }
      update_visit_details_v1: {
        Args: {
          p_amount_cents?: number
          p_note?: string
          p_rating?: number
          p_visit_id: string
        }
        Returns: Json
      }
      updategeometrysrid: {
        Args: {
          catalogn_name: string
          column_name: string
          new_srid_in: number
          schema_name: string
          table_name: string
        }
        Returns: string
      }
      upsert_business_hours_v1: {
        Args: { p_business_id: string; p_hours: Json }
        Returns: undefined
      }
      upsert_business_social_links_v1: {
        Args: {
          p_business_id: string
          p_facebook?: string
          p_instagram?: string
          p_tiktok?: string
          p_website?: string
          p_whatsapp?: string
        }
        Returns: undefined
      }
      upsert_business_special_hour_v1: {
        Args: {
          p_business_id: string
          p_close_time?: string
          p_date: string
          p_is_closed?: boolean
          p_note?: string
          p_open_time?: string
        }
        Returns: undefined
      }
      upsert_collab_vote_v1: {
        Args: { p_item_id: string; p_vote: number }
        Returns: Json
      }
      upsert_collection_share_v1: {
        Args: {
          p_business_ids: string[]
          p_collection_key: string
          p_name: string
        }
        Returns: {
          slug: string
        }[]
      }
      upsert_custom_domain_v1: {
        Args: { p_business_id: string; p_domain: string }
        Returns: Json
      }
      upsert_menu_item_translation_v1: {
        Args: {
          p_description?: string
          p_item_id: string
          p_locale: string
          p_name: string
        }
        Returns: Json
      }
      upsert_menu_section_translation_v1: {
        Args: { p_locale: string; p_name: string; p_section_id: string }
        Returns: Json
      }
      upsert_my_diet_profile_v1: {
        Args: {
          p_is_gluten_free: boolean
          p_is_halal: boolean
          p_is_lactose_free: boolean
          p_is_vegan: boolean
          p_is_vegetarian: boolean
          p_max_calories: number
        }
        Returns: Json
      }
      upsert_team_member_v1: {
        Args: {
          p_business_id: string
          p_email: string
          p_role: string
          p_scope?: string
        }
        Returns: Json
      }
      upsert_user_location_prefs_v1:
        | {
            Args: { p_city: string; p_district: string; p_mode?: string }
            Returns: Json
          }
        | {
            Args: {
              p_city: string
              p_district: string
              p_mode?: string
              p_neighborhood?: string
            }
            Returns: Json
          }
        | {
            Args: {
              p_city: string
              p_district: string
              p_lat?: number
              p_lng?: number
              p_mode?: string
              p_neighborhood?: string
            }
            Returns: Json
          }
      vote_business_fee_v1: {
        Args: {
          p_business_id: string
          p_field: string
          p_note?: string
          p_value: boolean
        }
        Returns: Json
      }
      vote_menu_item_photo_v1: {
        Args: { p_photo_id: string; p_vote: number }
        Returns: Json
      }
      vote_menu_item_price_v1: {
        Args: { p_menu_item_id: string; p_vote: number }
        Returns: Json
      }
    }
    Enums: {
      contrib_status: "pending" | "approved" | "rejected"
      crowd_level: "quiet" | "normal" | "busy"
      menu_price_suggestion_status: "pending" | "approved" | "rejected"
      menu_status: "draft" | "published" | "archived"
      push_campaign_segment:
        | "all_followers"
        | "loyal_top20"
        | "inactive_30d"
        | "new_30d"
      story_type: "menu" | "crowd" | "promo" | "update"
      suspended_claim_status: "pending" | "approved" | "rejected" | "fulfilled"
      suspended_meal_status: "active" | "claimed" | "expired" | "cancelled"
      translation_entity_type: "business" | "category" | "item"
    }
    CompositeTypes: {
      geometry_dump: {
        path: number[] | null
        geom: unknown
      }
      valid_detail: {
        valid: boolean | null
        reason: string | null
        location: unknown
      }
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      contrib_status: ["pending", "approved", "rejected"],
      crowd_level: ["quiet", "normal", "busy"],
      menu_price_suggestion_status: ["pending", "approved", "rejected"],
      menu_status: ["draft", "published", "archived"],
      push_campaign_segment: [
        "all_followers",
        "loyal_top20",
        "inactive_30d",
        "new_30d",
      ],
      story_type: ["menu", "crowd", "promo", "update"],
      suspended_claim_status: ["pending", "approved", "rejected", "fulfilled"],
      suspended_meal_status: ["active", "claimed", "expired", "cancelled"],
      translation_entity_type: ["business", "category", "item"],
    },
  },
} as const

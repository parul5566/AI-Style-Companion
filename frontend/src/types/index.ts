// API Types matching backend schemas

export interface User {
  id: number;
  email: string;
  full_name: string;
  is_active: boolean;
  created_at: string;
}

export interface TokenResponse {
  access_token: string;
  token_type: string;
  user_id: number;
  email: string;
  full_name: string;
}

export interface UserProfile {
  id: number;
  user_id: number;
  gender?: string | null;
  age_range?: string | null;
  budget_min?: number | null;
  budget_max?: number | null;
  preferred_colors?: string[] | null;
  avoided_colors?: string[] | null;
  style_preferences?: string[] | null;
  favorite_occasions?: string[] | null;
  body_type?: string | null;
  onboarding_completed: boolean;
}

export interface WardrobeItem {
  id: number;
  user_id: number;
  name: string;
  category: string;
  subcategory?: string | null;
  color_primary?: string | null;
  color_secondary?: string | null;
  pattern?: string | null;
  fabric?: string | null;
  brand?: string | null;
  formality_level?: string | null;
  season?: string | null;
  image_path?: string | null;
  ai_tags?: Record<string, unknown> | null;
  is_favorite: boolean;
  times_worn: number;
  last_worn_date?: string | null;
  purchase_price?: number | null;
  created_at: string;
}

export interface WeatherInfo {
  city: string;
  temperature_c: number;
  feels_like_c?: number | null;
  condition_text: string;
  humidity?: number | null;
  wind_kph?: number | null;
}

export interface WardrobeStats {
  total_items: number;
  by_category: Record<string, number>;
  favorites_count: number;
  recently_worn_count: number;
}

export interface MissingPieceItem {
  category: string;
  name: string;
  reason: string;
  priority: string;
  suggested_price_range?: string | null;
}

export interface DashboardSummary {
  weather: WeatherInfo | null;
  today_outfit: OutfitResponse | null;
  wardrobe_stats: WardrobeStats;
  missing_items: MissingPieceItem[];
  upcoming_events: Array<{ id: number; title: string; event_type: string; event_date: string }>;
  subscription_tier: string;
  tryon_credits: number;
}

export interface OutfitItemSlot {
  role: string;
  item: WardrobeItem;
}

export interface OutfitResponse {
  id?: number | null;
  name: string;
  occasion?: string | null;
  weather_context?: string | null;
  ai_confidence_score?: number | null;
  is_ai_generated: boolean;
  items: OutfitItemSlot[];
  ai_reasoning?: string | null;
  created_at?: string | null;
}

export interface ChatMessage {
  id?: number | null;
  conversation_id: number;
  role: string;
  content: string;
  created_at?: string | null;
}

export interface ChatConversation {
  id: number;
  title?: string | null;
  context_type: string;
  messages: ChatMessage[];
  created_at?: string | null;
}

export interface SubscriptionInfo {
  id: number;
  user_id: number;
  tier: string;
  tryon_credits_remaining: number;
  tryon_credits_monthly: number;
  is_active: boolean;
}

export interface TierInfo {
  name: string;
  credits_monthly: number;
  features: string[];
  price_label: string;
}

export interface MissingPieceResponse {
  event_type: string;
  have: string[];
  missing: MissingPieceItem[];
  summary?: string | null;
}

import api from './client';
import type {
  TokenResponse, User, UserProfile, WardrobeItem,
  DashboardSummary, OutfitResponse, ChatMessage,
  ChatConversation, SubscriptionInfo, TierInfo, MissingPieceResponse,
} from '../types';

// Auth
export const auth = {
  register: (email: string, password: string, full_name: string) =>
    api.post<TokenResponse>('/auth/register', { email, password, full_name }).then(r => r.data),
  login: (email: string, password: string) =>
    api.post<TokenResponse>('/auth/login', { email, password }).then(r => r.data),
  me: () => api.get<User>('/auth/me').then(r => r.data),
};

// Profile
export const profile = {
  get: () => api.get<UserProfile>('/profile').then(r => r.data),
  update: (data: Partial<UserProfile>) => api.put<UserProfile>('/profile', data).then(r => r.data),
};

// Wardrobe
export const wardrobe = {
  list: (params?: { category?: string; is_favorite?: boolean; search?: string }) =>
    api.get<WardrobeItem[]>('/wardrobe/items', { params }).then(r => r.data),
  create: (data: Partial<WardrobeItem>) =>
    api.post<WardrobeItem>('/wardrobe/items', data).then(r => r.data),
  update: (id: number, data: Partial<WardrobeItem>) =>
    api.put<WardrobeItem>(`/wardrobe/items/${id}`, data).then(r => r.data),
  delete: (id: number) => api.delete(`/wardrobe/items/${id}`),
  upload: (file: File) => {
    const formData = new FormData();
    formData.append('file', file);
    return api.post<WardrobeItem>('/wardrobe/items/upload', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    }).then(r => r.data);
  },
};

// Outfits
export const outfits = {
  recommend: (data: { occasion?: string; city?: string; weather_temp_c?: number; weather_condition?: string }) =>
    api.post<OutfitResponse>('/outfits/recommend', data).then(r => r.data),
  history: () => api.get<OutfitResponse[]>('/outfits/history').then(r => r.data),
  feedback: (outfit_id: number, feedback: string) =>
    api.post(`/outfits/${outfit_id}/feedback`, { feedback }).then(r => r.data),
};

// AI
export const ai = {
  tag: (description: string) =>
    api.post('/ai/tag', null, { params: { description } }).then(r => r.data),
  missingPieces: (data: { event_type: string; dress_code?: string; budget_max?: number }) =>
    api.post<MissingPieceResponse>('/ai/missing-pieces', data).then(r => r.data),
};

// Chat
export const chat = {
  send: (data: { message: string; conversation_id?: number; context_type?: string }) =>
    api.post<ChatMessage>('/chat/message', data).then(r => r.data),
  conversations: () => api.get<ChatConversation[]>('/chat/conversations').then(r => r.data),
};

// Dashboard
export const dashboard = {
  summary: (city?: string) =>
    api.get<DashboardSummary>('/dashboard/summary', { params: { city } }).then(r => r.data),
};

// Weather
export const weather = {
  get: (city: string) =>
    api.get('/weather', { params: { city } }).then(r => r.data),
};

// Subscriptions
export const subscriptions = {
  get: () => api.get<SubscriptionInfo>('/subscriptions').then(r => r.data),
  tiers: () => api.get<TierInfo[]>('/subscriptions/tiers').then(r => r.data),
  updateTier: (tier: string) => api.put<SubscriptionInfo>('/subscriptions/tier', { tier }).then(r => r.data),
};

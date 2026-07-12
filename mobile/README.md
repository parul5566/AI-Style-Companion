# AI Style Companion — Flutter Mobile App

A complete, production-ready Flutter mobile application for the AI Style Companion platform.

## Quick Start

```bash
cd mobile
flutter pub get
flutter run
```

## Configuration

Update `lib/core/config.dart` with your backend URL:

```dart
static const String baseUrl = 'https://your-backend-url/api';
```

## Architecture

```
lib/
├── core/                      # App-wide config & theme
│   ├── config.dart            # API URL, storage keys, constants
│   └── theme.dart             # Dark glassmorphism Material 3 theme
├── data/
│   ├── models/                # Dart models matching backend schemas
│   │   ├── user_model.dart    # User, TokenResponse, UserProfile
│   │   ├── wardrobe_model.dart # WardrobeItem, AITagResult, categories
│   │   ├── outfit_model.dart  # OutfitResponse, OutfitItemSlot, MissingPiece
│   │   ├── chat_model.dart    # ChatMessage, ChatConversation
│   │   ├── dashboard_model.dart # DashboardSummary, WeatherInfo, WardrobeStats
│   │   ├── subscription_model.dart # Subscription, TierInfo
│   │   └── event_model.dart   # EventItem
│   ├── services/
│   │   └── api_client.dart    # Dio client, JWT interceptor, all API calls
│   └── providers/
│       └── auth_provider.dart # Auth state (login/register/logout/onboarding)
├── shared/
│   └── widgets/
│       └── widgets.dart       # GlassCard, LoadingSpinner, ErrorDisplay, etc.
└── features/
    ├── auth/                  # Login + Register screens
    ├── onboarding/            # 6-step style profile setup
    ├── dashboard/             # Weather, stats, quick actions, missing items
    ├── wardrobe/              # CRUD, filters, search, AI photo upload
    ├── stylist/               # Outfit recommendations + missing piece analysis
    ├── chat/                  # AI fashion assistant chat
    ├── subscription/          # Plan tiers + upgrade/downgrade
    ├── profile/               # View/edit profile, logout
    ├── events/                # Calendar events for outfit planning
    └── main_nav.dart          # Bottom navigation (5 tabs)
```

## Screens

| Screen | Features |
|--------|----------|
| **Login/Register** | JWT auth, form validation, error handling |
| **Onboarding** | 6-step wizard: gender, age, styles, colors, budget, occasions |
| **Dashboard** | Weather widget, wardrobe stats, quick actions, missing items |
| **Wardrobe** | Grid view, category filter, search, favorites, AI upload, CRUD |
| **AI Stylist** | Outfit recommendations + missing piece gap analysis |
| **Chat** | AI fashion assistant with conversation history |
| **Subscription** | 4 tiers (free/basic/plus/premium), credits management |
| **Profile** | View/edit style profile, logout |
| **Events** | Calendar events with date/time picker, dress codes |

## API Coverage

All 27 backend endpoints are wired:

| Endpoint | Method | Flutter Method |
|----------|--------|----------------|
| `/api/auth/register` | POST | `ApiClient.register()` |
| `/api/auth/login` | POST | `ApiClient.login()` |
| `/api/auth/me` | GET | `ApiClient.getMe()` |
| `/api/profile` | GET/PUT | `ApiClient.getProfile()` / `updateProfile()` |
| `/api/wardrobe/items` | GET/POST | `ApiClient.listWardrobeItems()` / `createWardrobeItem()` |
| `/api/wardrobe/items/{id}` | PUT/DELETE | `ApiClient.updateWardrobeItem()` / `deleteWardrobeItem()` |
| `/api/wardrobe/items/upload` | POST | `ApiClient.uploadWardrobeItem()` |
| `/api/outfits/recommend` | POST | `ApiClient.recommendOutfit()` |
| `/api/outfits/history` | GET | `ApiClient.outfitHistory()` |
| `/api/outfits/{id}/feedback` | POST | `ApiClient.outfitFeedback()` |
| `/api/ai/tag` | POST | `ApiClient.aiTag()` |
| `/api/ai/missing-pieces` | POST | `ApiClient.missingPieces()` |
| `/api/chat/message` | POST | `ApiClient.sendChatMessage()` |
| `/api/chat/conversations` | GET | `ApiClient.getConversations()` |
| `/api/dashboard/summary` | GET | `ApiClient.dashboardSummary()` |
| `/api/weather` | GET | `ApiClient.getWeather()` |
| `/api/subscriptions` | GET | `ApiClient.getSubscription()` |
| `/api/subscriptions/tiers` | GET | `ApiClient.getTiers()` |
| `/api/subscriptions/tier` | PUT | `ApiClient.updateTier()` |
| `/api/events` | GET/POST | `ApiClient.listEvents()` / `createEvent()` |
| `/api/events/{id}` | DELETE | `ApiClient.deleteEvent()` |

## Dependencies

- `dio` — HTTP client with JWT interceptor
- `provider` — State management
- `shared_preferences` — JWT token persistence
- `image_picker` — Gallery photo upload for AI tagging
- `google_fonts` — Poppins typography
- `intl` — Date/time formatting

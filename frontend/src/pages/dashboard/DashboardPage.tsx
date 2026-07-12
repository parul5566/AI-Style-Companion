import { useEffect, useState } from 'react';
import { CloudSun, Shirt, Heart, Sparkles, AlertCircle, Calendar, Crown } from 'lucide-react';
import { dashboard as dashboardApi } from '../../api';
import type { DashboardSummary } from '../../types';
import { AppLayout } from '../../components/AppLayout';

const CATEGORY_ICONS: Record<string, string> = {
  shirt: '👔', tshirt: '👕', jeans: '👖', trousers: '👖', jacket: '🧥',
  blazer: '🧥', coat: '🧥', dress: '👗', skirt: '👗', shoes: '👞',
  sneakers: '👟', boots: '🥾', watch: '⌚', belt: '👖', hat: '🎩',
  bag: '👜', accessory: '💍', other: '📦',
};

export function DashboardPage() {
  const [data, setData] = useState<DashboardSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [city, setCity] = useState('London');

  useEffect(() => {
    loadDashboard();
  }, []);

  const loadDashboard = async () => {
    setLoading(true);
    try {
      const res = await dashboardApi.summary(city);
      setData(res);
    } catch (err) {
      console.error('Dashboard load failed', err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <AppLayout>
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900 sm:text-3xl">Dashboard</h1>
        <p className="mt-1 text-sm text-gray-500 sm:text-base">Your fashion overview at a glance</p>
      </div>

      {loading ? (
        <div className="grid grid-cols-1 gap-6 md:grid-cols-3">
          {[...Array(6)].map((_, i) => (
            <div key={i} className="h-40 rounded-2xl shimmer" />
          ))}
        </div>
      ) : data ? (
        <div className="space-y-6">
          {/* Top row: Weather + Today's outfit + Stats */}
          <div className="grid grid-cols-1 gap-4 sm:gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {/* Weather */}
            <div className="glass card-hover rounded-2xl p-6">
              <div className="mb-4 flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-sky-400 to-blue-500">
                  <CloudSun className="h-5 w-5 text-white" />
                </div>
                <h3 className="font-semibold text-gray-900">Weather</h3>
              </div>
              {data.weather ? (
                <div>
                  <div className="flex items-baseline gap-2">
                    <span className="text-4xl font-bold text-gray-900">{Math.round(data.weather.temperature_c)}°</span>
                    <span className="text-sm text-gray-500">C in {data.weather.city}</span>
                  </div>
                  <p className="mt-1 text-sm text-gray-600">{data.weather.condition_text}</p>
                  <div className="mt-3 flex gap-4 text-xs text-gray-500">
                    <span>Feels {Math.round(data.weather.feels_like_c || 0)}°C</span>
                    <span>{data.weather.humidity || 0}% humidity</span>
                  </div>
                </div>
              ) : (
                <p className="text-sm text-gray-500">Weather unavailable</p>
              )}
              <div className="mt-3 flex gap-2">
                <input
                  value={city}
                  onChange={(e) => setCity(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && loadDashboard()}
                  className="flex-1 rounded-lg border border-gray-200 bg-white/50 px-3 py-1.5 text-xs outline-none focus:border-indigo-400"
                  placeholder="City name"
                />
                <button onClick={loadDashboard} className="rounded-lg bg-indigo-500 px-3 py-1.5 text-xs text-white">
                  Update
                </button>
              </div>
            </div>

            {/* Wardrobe Stats */}
            <div className="glass card-hover rounded-2xl p-6">
              <div className="mb-4 flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-purple-500 to-pink-500">
                  <Shirt className="h-5 w-5 text-white" />
                </div>
                <h3 className="font-semibold text-gray-900">Wardrobe</h3>
              </div>
              <div className="flex items-baseline gap-2">
                <span className="text-4xl font-bold text-gray-900">{data.wardrobe_stats.total_items}</span>
                <span className="text-sm text-gray-500">total items</span>
              </div>
              <div className="mt-3 flex gap-4 text-xs text-gray-500">
                <span className="flex items-center gap-1"><Heart className="h-3 w-3" /> {data.wardrobe_stats.favorites_count} favorites</span>
              </div>
              {Object.keys(data.wardrobe_stats.by_category).length > 0 && (
                <div className="mt-3 flex flex-wrap gap-1">
                  {Object.entries(data.wardrobe_stats.by_category).slice(0, 6).map(([cat, count]) => (
                    <span key={cat} className="rounded-full bg-gray-100 px-2 py-0.5 text-xs text-gray-600">
                      {CATEGORY_ICONS[cat] || '📦'} {count}
                    </span>
                  ))}
                </div>
              )}
            </div>

            {/* Subscription */}
            <div className="glass card-hover rounded-2xl p-6">
              <div className="mb-4 flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-amber-400 to-orange-500">
                  <Crown className="h-5 w-5 text-white" />
                </div>
                <h3 className="font-semibold text-gray-900">Plan</h3>
              </div>
              <div>
                <span className="text-2xl font-bold capitalize text-gray-900">{data.subscription_tier}</span>
                <p className="text-sm text-gray-500">membership</p>
              </div>
              <div className="mt-3 flex items-center gap-2">
                <Sparkles className="h-4 w-4 text-amber-500" />
                <span className="text-sm text-gray-600">{data.tryon_credits} try-on credits</span>
              </div>
            </div>
          </div>

          {/* Missing items + Events */}
          <div className="grid grid-cols-1 gap-4 sm:gap-6 lg:grid-cols-2">
            {/* Missing items */}
            <div className="glass card-hover rounded-2xl p-6">
              <div className="mb-4 flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-red-400 to-rose-500">
                  <AlertCircle className="h-5 w-5 text-white" />
                </div>
                <h3 className="font-semibold text-gray-900">Missing Items</h3>
              </div>
              {data.missing_items.length > 0 ? (
                <div className="space-y-2">
                  {data.missing_items.map((item, i) => (
                    <div key={i} className="flex items-center justify-between rounded-xl bg-white/50 p-3">
                      <div>
                        <p className="text-sm font-medium text-gray-900">{item.name}</p>
                        <p className="text-xs text-gray-500">{item.reason}</p>
                      </div>
                      <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${
                        item.priority === 'high' ? 'bg-red-100 text-red-700' :
                        item.priority === 'medium' ? 'bg-amber-100 text-amber-700' :
                        'bg-gray-100 text-gray-600'
                      }`}>{item.priority}</span>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-sm text-gray-500">Your wardrobe looks complete! No critical missing items detected.</p>
              )}
            </div>

            {/* Upcoming events */}
            <div className="glass card-hover rounded-2xl p-6">
              <div className="mb-4 flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-teal-400 to-emerald-500">
                  <Calendar className="h-5 w-5 text-white" />
                </div>
                <h3 className="font-semibold text-gray-900">Upcoming Events</h3>
              </div>
              {data.upcoming_events.length > 0 ? (
                <div className="space-y-2">
                  {data.upcoming_events.map((event, i) => (
                    <div key={i} className="flex items-center justify-between rounded-xl bg-white/50 p-3">
                      <div>
                        <p className="text-sm font-medium text-gray-900">{event.title}</p>
                        <p className="text-xs text-gray-500">{event.event_type}</p>
                      </div>
                      <span className="text-xs text-gray-500">
                        {new Date(event.event_date).toLocaleDateString()}
                      </span>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-sm text-gray-500">No upcoming events. Add events to get tailored outfit recommendations!</p>
              )}
            </div>
          </div>
        </div>
      ) : (
        <div className="text-center text-gray-500">Failed to load dashboard.</div>
      )}
    </AppLayout>
  );
}

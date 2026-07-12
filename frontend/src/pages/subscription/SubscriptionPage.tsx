import { useEffect, useState } from 'react';
import { Check, Crown, Sparkles } from 'lucide-react';
import { subscriptions as subApi } from '../../api';
import type { TierInfo, SubscriptionInfo } from '../../types';
import { AppLayout } from '../../components/AppLayout';

const TIER_STYLES: Record<string, string> = {
  free: 'from-gray-400 to-gray-500',
  basic: 'from-blue-500 to-cyan-500',
  plus: 'from-indigo-500 to-purple-600',
  premium: 'from-amber-400 via-orange-500 to-pink-500',
};

export function SubscriptionPage() {
  const [tiers, setTiers] = useState<TierInfo[]>([]);
  const [current, setCurrent] = useState<SubscriptionInfo | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => { load(); }, []);

  const load = async () => {
    try {
      const [t, c] = await Promise.all([subApi.tiers(), subApi.get()]);
      setTiers(t);
      setCurrent(c);
    } catch { /* ignore */ }
  };

  const switchTier = async (tier: string) => {
    setLoading(true);
    try {
      await subApi.updateTier(tier);
      await load();
    } catch { /* ignore */ } finally { setLoading(false); }
  };

  return (
    <AppLayout>
      <div className="mb-6">
        <h1 className="flex items-center gap-2 text-2xl font-bold text-gray-900 sm:text-3xl">
          <Crown className="h-6 w-6 text-amber-500 sm:h-7 sm:w-7" /> Subscription Plans
        </h1>
        <p className="mt-1 text-sm text-gray-500 sm:text-base">Choose the plan that fits your style journey</p>
      </div>

      {current && (
        <div className="mb-8 glass rounded-2xl p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-500">Current Plan</p>
              <p className="text-2xl font-bold capitalize text-gray-900">{current.tier}</p>
            </div>
            <div className="flex items-center gap-2 rounded-xl bg-amber-50 px-4 py-2">
              <Sparkles className="h-5 w-5 text-amber-500" />
              <span className="text-sm font-medium text-amber-700">{current.tryon_credits_remaining} try-on credits remaining</span>
            </div>
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 sm:gap-6 lg:grid-cols-4">
        {tiers.map((tier) => {
          const isCurrent = current?.tier === tier.name;
          return (
            <div key={tier.name} className={`relative overflow-hidden rounded-2xl p-6 ${
              isCurrent ? 'ring-2 ring-indigo-500' : ''
            } ${tier.name === 'premium' ? 'glass' : 'bg-white shadow-lg'}`}>
              {tier.name === 'premium' && (
                <div className="absolute right-0 top-0 rounded-bl-2xl bg-gradient-to-r from-amber-400 to-orange-500 px-3 py-1 text-xs font-bold text-white">
                  POPULAR
                </div>
              )}
              <div className={`mb-4 inline-flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br ${TIER_STYLES[tier.name] || 'from-gray-400 to-gray-500'}`}>
                <Crown className="h-6 w-6 text-white" />
              </div>
              <h3 className="text-xl font-bold capitalize text-gray-900">{tier.name}</h3>
              <p className="mt-1 text-2xl font-bold text-gray-900">{tier.price_label}</p>
              <p className="mt-1 text-sm text-gray-500">{tier.credits_monthly} try-on credits/month</p>

              <div className="mt-6 space-y-2">
                {tier.features.map((f, i) => (
                  <div key={i} className="flex items-center gap-2 text-sm text-gray-600">
                    <Check className="h-4 w-4 text-green-500" />
                    <span className="capitalize">{f.replace(/_/g, ' ')}</span>
                  </div>
                ))}
              </div>

              <button
                onClick={() => switchTier(tier.name)}
                disabled={isCurrent || loading}
                className={`mt-6 w-full rounded-xl py-2.5 text-sm font-semibold transition ${
                  isCurrent
                    ? 'cursor-default bg-gray-100 text-gray-400'
                    : `bg-gradient-to-r ${TIER_STYLES[tier.name] || 'from-gray-400 to-gray-500'} text-white shadow-lg hover:shadow-xl`
                }`}
              >
                {isCurrent ? 'Current Plan' : 'Switch to ' + tier.name}
              </button>
            </div>
          );
        })}
      </div>
    </AppLayout>
  );
}

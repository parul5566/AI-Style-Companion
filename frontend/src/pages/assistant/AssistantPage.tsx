import { useState } from 'react';
import { Sparkles, Wand2, AlertCircle, CheckCircle2, Loader2, Shirt } from 'lucide-react';
import { outfits as outfitApi, ai as aiApi } from '../../api';
import type { OutfitResponse, MissingPieceResponse } from '../../types';
import { AppLayout } from '../../components/AppLayout';

const CATEGORY_EMOJI: Record<string, string> = {
  shirt: '👔', tshirt: '👕', jeans: '👖', trousers: '👖', jacket: '🧥', blazer: '🧥',
  coat: '🧥', dress: '👗', skirt: '👗', shoes: '👞', sneakers: '👟', boots: '🥾',
  watch: '⌚', belt: '👖', hat: '🎩', bag: '👜', accessory: '💍', other: '📦',
};

export function AssistantPage() {
  const [tab, setTab] = useState<'outfit' | 'missing'>('outfit');

  // Outfit recommendation
  const [occasion, setOccasion] = useState('casual');
  const [city, setCity] = useState('London');
  const [outfit, setOutfit] = useState<OutfitResponse | null>(null);
  const [loadingOutfit, setLoadingOutfit] = useState(false);

  // Missing pieces
  const [eventType, setEventType] = useState('wedding');
  const [dressCode, setDressCode] = useState('');
  const [budgetMax, setBudgetMax] = useState('');
  const [missing, setMissing] = useState<MissingPieceResponse | null>(null);
  const [loadingMissing, setLoadingMissing] = useState(false);

  const getOutfit = async () => {
    setLoadingOutfit(true);
    setOutfit(null);
    try {
      const res = await outfitApi.recommend({ occasion, city });
      setOutfit(res);
    } catch {
      setOutfit(null);
    } finally {
      setLoadingOutfit(false);
    }
  };

  const getMissing = async () => {
    setLoadingMissing(true);
    setMissing(null);
    try {
      const res = await aiApi.missingPieces({
        event_type: eventType,
        dress_code: dressCode || undefined,
        budget_max: budgetMax ? parseInt(budgetMax) : undefined,
      });
      setMissing(res);
    } catch {
      setMissing(null);
    } finally {
      setLoadingMissing(false);
    }
  };

  return (
    <AppLayout>
      <div className="mb-6">
        <h1 className="flex items-center gap-2 text-2xl font-bold text-gray-900 sm:text-3xl">
          <Sparkles className="h-6 w-6 text-indigo-600 sm:h-7 sm:w-7" /> AI Stylist
        </h1>
        <p className="mt-1 text-sm text-gray-500 sm:text-base">Get outfit recommendations and wardrobe analysis powered by AI</p>
      </div>

      {/* Tabs */}
      <div className="mb-6 flex flex-wrap gap-2">
        <button onClick={() => setTab('outfit')}
          className={`flex items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition ${
            tab === 'outfit' ? 'bg-gradient-to-r from-indigo-600 to-purple-600 text-white shadow-md' : 'bg-white text-gray-600 hover:bg-gray-100'
          }`}>
          <Wand2 className="h-4 w-4" /> Outfit Recommender
        </button>
        <button onClick={() => setTab('missing')}
          className={`flex items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-medium transition ${
            tab === 'missing' ? 'bg-gradient-to-r from-indigo-600 to-purple-600 text-white shadow-md' : 'bg-white text-gray-600 hover:bg-gray-100'
          }`}>
          <AlertCircle className="h-4 w-4" /> Missing Piece Detector
        </button>
      </div>

      {tab === 'outfit' && (
        <div className="space-y-6">
          {/* Controls */}
          <div className="glass rounded-2xl p-6">
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
              <div>
                <label className="mb-1.5 block text-sm font-medium text-gray-700">Occasion</label>
                <select value={occasion} onChange={e => setOccasion(e.target.value)}
                  className="w-full rounded-xl border border-gray-200 bg-white/50 px-3 py-2.5 text-sm outline-none focus:border-indigo-400">
                  {['casual', 'work', 'date', 'interview', 'wedding', 'party', 'business meeting', 'travel'].map(o =>
                    <option key={o} value={o}>{o}</option>
                  )}
                </select>
              </div>
              <div>
                <label className="mb-1.5 block text-sm font-medium text-gray-700">City (for weather)</label>
                <input value={city} onChange={e => setCity(e.target.value)}
                  className="w-full rounded-xl border border-gray-200 bg-white/50 px-3 py-2.5 text-sm outline-none focus:border-indigo-400" />
              </div>
              <div className="flex items-end">
                <button onClick={getOutfit} disabled={loadingOutfit}
                  className="flex w-full items-center justify-center gap-2 rounded-xl bg-gradient-to-r from-indigo-600 to-purple-600 px-4 py-2.5 text-sm font-semibold text-white shadow-lg shadow-indigo-500/30 disabled:opacity-50">
                  {loadingOutfit ? <Loader2 className="h-4 w-4 animate-spin" /> : <Sparkles className="h-4 w-4" />}
                  {loadingOutfit ? 'Styling...' : 'Recommend Outfit'}
                </button>
              </div>
            </div>
          </div>

          {/* Result */}
          {outfit && (
            <div className="glass fade-in rounded-2xl p-6">
              <div className="mb-4 flex items-center justify-between">
                <div>
                  <h2 className="text-xl font-bold text-gray-900">{outfit.name}</h2>
                  {outfit.ai_reasoning && <p className="mt-1 text-sm text-gray-500">{outfit.ai_reasoning}</p>}
                </div>
                {outfit.ai_confidence_score != null && (
                  <div className="text-right">
                    <div className="text-2xl font-bold text-indigo-600">{Math.round(outfit.ai_confidence_score * 100)}%</div>
                    <div className="text-xs text-gray-500">confidence</div>
                  </div>
                )}
              </div>

              {outfit.items.length > 0 ? (
                <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 sm:gap-4 lg:grid-cols-5">
                  {outfit.items.map((slot, i) => (
                    <div key={i} className="rounded-xl border border-gray-200 bg-white/50 p-4 text-center">
                      <div className="mb-2 text-4xl">{CATEGORY_EMOJI[slot.item.category] || '📦'}</div>
                      <p className="text-xs font-semibold text-gray-900">{slot.item.name}</p>
                      <span className="mt-1 inline-block rounded-full bg-indigo-100 px-2 py-0.5 text-xs text-indigo-600">{slot.role}</span>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="flex items-center gap-2 rounded-xl bg-amber-50 p-4 text-sm text-amber-700">
                  <Shirt className="h-5 w-5" />
                  Add items to your wardrobe to get personalized recommendations!
                </div>
              )}
            </div>
          )}
        </div>
      )}

      {tab === 'missing' && (
        <div className="space-y-6">
          <div className="glass rounded-2xl p-6">
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
              <div>
                <label className="mb-1.5 block text-sm font-medium text-gray-700">Event Type</label>
                <select value={eventType} onChange={e => setEventType(e.target.value)}
                  className="w-full rounded-xl border border-gray-200 bg-white/50 px-3 py-2.5 text-sm outline-none focus:border-indigo-400">
                  {['wedding', 'interview', 'date', 'work', 'party', 'business meeting', 'travel', 'gym'].map(e =>
                    <option key={e} value={e}>{e}</option>
                  )}
                </select>
              </div>
              <div>
                <label className="mb-1.5 block text-sm font-medium text-gray-700">Dress Code (optional)</label>
                <input value={dressCode} onChange={e => setDressCode(e.target.value)}
                  className="w-full rounded-xl border border-gray-200 bg-white/50 px-3 py-2.5 text-sm outline-none focus:border-indigo-400"
                  placeholder="e.g. black tie" />
              </div>
              <div className="flex items-end gap-2">
                <div className="flex-1">
                  <label className="mb-1.5 block text-sm font-medium text-gray-700">Max Budget ($)</label>
                  <input type="number" value={budgetMax} onChange={e => setBudgetMax(e.target.value)}
                    className="w-full rounded-xl border border-gray-200 bg-white/50 px-3 py-2.5 text-sm outline-none focus:border-indigo-400"
                    placeholder="500" />
                </div>
                <button onClick={getMissing} disabled={loadingMissing}
                  className="flex items-center gap-2 rounded-xl bg-gradient-to-r from-indigo-600 to-purple-600 px-4 py-2.5 text-sm font-semibold text-white shadow-lg shadow-indigo-500/30 disabled:opacity-50">
                  {loadingMissing ? <Loader2 className="h-4 w-4 animate-spin" /> : <AlertCircle className="h-4 w-4" />}
                  Analyze
                </button>
              </div>
            </div>
          </div>

          {missing && (
            <div className="glass fade-in rounded-2xl p-6">
              {missing.summary && (
                <div className="mb-4 rounded-xl bg-indigo-50 px-4 py-3 text-sm text-indigo-700">{missing.summary}</div>
              )}

              {/* Have */}
              {missing.have.length > 0 && (
                <div className="mb-6">
                  <h3 className="mb-2 flex items-center gap-2 font-semibold text-gray-900">
                    <CheckCircle2 className="h-5 w-5 text-green-500" /> You Have
                  </h3>
                  <div className="flex flex-wrap gap-2">
                    {missing.have.map((h, i) => (
                      <span key={i} className="rounded-full bg-green-100 px-3 py-1 text-sm text-green-700">
                        {CATEGORY_EMOJI[h?.toLowerCase()] || '✓'} {h}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              {/* Missing */}
              {missing.missing.length > 0 && (
                <div>
                  <h3 className="mb-3 flex items-center gap-2 font-semibold text-gray-900">
                    <AlertCircle className="h-5 w-5 text-red-500" /> Missing Items
                  </h3>
                  <div className="space-y-2">
                    {missing.missing.map((item, i) => (
                      <div key={i} className="flex items-center justify-between rounded-xl border border-gray-200 bg-white/50 p-4">
                        <div>
                          <p className="font-medium text-gray-900">{item.name}</p>
                          <p className="text-xs text-gray-500">{item.reason}</p>
                          {item.suggested_price_range && <p className="mt-1 text-xs text-gray-400">💰 {item.suggested_price_range}</p>}
                        </div>
                        <span className={`rounded-full px-3 py-1 text-xs font-medium ${
                          item.priority === 'high' ? 'bg-red-100 text-red-700' :
                          item.priority === 'medium' ? 'bg-amber-100 text-amber-700' :
                          'bg-gray-100 text-gray-600'
                        }`}>{item.priority}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      )}
    </AppLayout>
  );
}

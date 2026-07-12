import { useEffect, useState, useRef } from 'react';
import { Plus, Search, Heart, Trash2, Upload, X, Edit3, Loader2 } from 'lucide-react';
import { wardrobe as wardrobeApi } from '../../api';
import type { WardrobeItem } from '../../types';
import { AppLayout } from '../../components/AppLayout';

const CATEGORIES = ['All', 'shirt', 'tshirt', 'jeans', 'trousers', 'jacket', 'blazer', 'coat', 'dress', 'skirt', 'shoes', 'sneakers', 'boots', 'watch', 'belt', 'hat', 'bag', 'accessory'];
const CATEGORY_EMOJI: Record<string, string> = {
  shirt: '👔', tshirt: '👕', jeans: '👖', trousers: '👖', jacket: '🧥', blazer: '🧥',
  coat: '🧥', dress: '👗', skirt: '👗', shoes: '👞', sneakers: '👟', boots: '🥾',
  watch: '⌚', belt: '👖', hat: '🎩', bag: '👜', accessory: '💍', other: '📦',
};
const FORMALITY: Record<string, string> = { casual: '🟢', smart_casual: '🟡', business: '🟠', formal: '🔴', black_tie: '⚫' };

export function WardrobePage() {
  const [items, setItems] = useState<WardrobeItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [category, setCategory] = useState('All');
  const [showFavOnly, setShowFavOnly] = useState(false);
  const [showAddModal, setShowAddModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState<WardrobeItem | null>(null);
  const [uploading, setUploading] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);

  useEffect(() => { loadItems(); }, []);

  const loadItems = async () => {
    setLoading(true);
    try {
      const params: any = {};
      if (category !== 'All') params.category = category;
      if (showFavOnly) params.is_favorite = true;
      if (search) params.search = search;
      const res = await wardrobeApi.list(params);
      setItems(res);
    } catch { /* ignore */ } finally { setLoading(false); }
  };

  useEffect(() => { loadItems(); }, [category, showFavOnly]);

  const handleUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploading(true);
    try {
      await wardrobeApi.upload(file);
      await loadItems();
    } catch (err) {
      alert('Upload failed. Please try again.');
    } finally {
      setUploading(false);
      if (fileRef.current) fileRef.current.value = '';
    }
  };

  const toggleFavorite = async (item: WardrobeItem) => {
    try {
      await wardrobeApi.update(item.id, { is_favorite: !item.is_favorite });
      await loadItems();
    } catch { /* ignore */ }
  };

  const deleteItem = async (id: number) => {
    if (!confirm('Delete this item?')) return;
    try {
      await wardrobeApi.delete(id);
      await loadItems();
    } catch { /* ignore */ }
  };

  return (
    <AppLayout>
      <div className="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 sm:text-3xl">My Wardrobe</h1>
          <p className="mt-1 text-sm text-gray-500 sm:text-base">{items.length} items in your collection</p>
        </div>
        <div className="flex flex-wrap gap-2">
          <input ref={fileRef} type="file" accept="image/*" onChange={handleUpload} className="hidden" />
          <button
            onClick={() => fileRef.current?.click()}
            disabled={uploading}
            className="flex items-center gap-2 rounded-xl bg-gradient-to-r from-indigo-600 to-purple-600 px-3 py-2.5 text-xs font-semibold text-white shadow-lg shadow-indigo-500/30 transition hover:shadow-xl disabled:opacity-50 sm:px-4 sm:text-sm"
          >
            {uploading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Upload className="h-4 w-4" />}
            {uploading ? 'AI Tagging...' : 'Upload & AI Tag'}
          </button>
          <button
            onClick={() => setShowAddModal(true)}
            className="flex items-center gap-2 rounded-xl border border-gray-200 bg-white px-3 py-2.5 text-xs font-semibold text-gray-700 transition hover:bg-gray-50 sm:px-4 sm:text-sm"
          >
            <Plus className="h-4 w-4" /> Add Manually
          </button>
        </div>
      </div>

      {/* Filters */}
      <div className="mb-6 flex flex-wrap items-center gap-3">
        <div className="relative flex-1 min-w-[200px]">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && loadItems()}
            className="w-full rounded-xl border border-gray-200 bg-white py-2.5 pl-10 pr-4 text-sm outline-none focus:border-indigo-400"
            placeholder="Search items..."
          />
        </div>
        <button
          onClick={() => setShowFavOnly(!showFavOnly)}
          className={`flex items-center gap-2 rounded-xl border px-4 py-2.5 text-sm font-medium transition ${
            showFavOnly ? 'border-pink-400 bg-pink-50 text-pink-600' : 'border-gray-200 bg-white text-gray-600'
          }`}
        >
          <Heart className={`h-4 w-4 ${showFavOnly ? 'fill-pink-500 text-pink-500' : ''}`} />
          Favorites
        </button>
      </div>

      {/* Category pills */}
      <div className="mb-6 flex flex-wrap gap-2">
        {CATEGORIES.map((cat) => (
          <button
            key={cat}
            onClick={() => setCategory(cat)}
            className={`rounded-full px-4 py-1.5 text-sm font-medium capitalize transition ${
              category === cat
                ? 'bg-gradient-to-r from-indigo-600 to-purple-600 text-white shadow-md'
                : 'bg-white text-gray-600 hover:bg-gray-100'
            }`}
          >
            {cat === 'All' ? 'All' : `${CATEGORY_EMOJI[cat] || '📦'} ${cat}`}
          </button>
        ))}
      </div>

      {/* Items grid */}
      {loading ? (
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 sm:gap-4 lg:grid-cols-4 xl:grid-cols-5">
          {[...Array(10)].map((_, i) => <div key={i} className="h-48 rounded-2xl shimmer sm:h-64" />)}
        </div>
      ) : items.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-20 text-center">
          <div className="mb-4 text-6xl">👗</div>
          <h3 className="text-lg font-semibold text-gray-900">Your wardrobe is empty</h3>
          <p className="mt-1 text-sm text-gray-500">Upload garment photos to auto-tag with AI, or add items manually.</p>
        </div>
      ) : (
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 sm:gap-4 lg:grid-cols-4 xl:grid-cols-5">
          {items.map((item) => (
            <div key={item.id} className="group glass card-hover overflow-hidden rounded-2xl fade-in">
              {/* Image or placeholder */}
              <div className="relative h-36 overflow-hidden bg-gradient-to-br from-indigo-100 to-purple-100 sm:h-48">
                {item.image_path ? (
                  <img src={item.image_path} alt={item.name} className="h-full w-full object-cover" />
                ) : (
                  <div className="flex h-full items-center justify-center text-5xl">
                    {CATEGORY_EMOJI[item.category] || '📦'}
                  </div>
                )}
                {/* Fav button */}
                <button
                  onClick={() => toggleFavorite(item)}
                  className="absolute right-2 top-2 rounded-full bg-white/80 p-1.5 backdrop-blur transition hover:bg-white"
                >
                  <Heart className={`h-4 w-4 ${item.is_favorite ? 'fill-pink-500 text-pink-500' : 'text-gray-400'}`} />
                </button>
              </div>
              {/* Info */}
              <div className="p-3">
                <h3 className="truncate text-sm font-semibold text-gray-900">{item.name}</h3>
                <p className="mt-0.5 text-xs capitalize text-gray-500">{item.category}</p>
                <div className="mt-2 flex items-center justify-between">
                  <div className="flex items-center gap-1.5">
                    {item.color_primary && (
                      <span className="flex items-center gap-1 text-xs text-gray-500">
                        <span className="inline-block h-3 w-3 rounded-full border border-gray-200" style={{ background: colorToHex(item.color_primary) }} />
                        {item.color_primary}
                      </span>
                    )}
                    {item.formality_level && (
                      <span className="text-xs" title={item.formality_level}>
                        {FORMALITY[item.formality_level] || '⚪'}
                      </span>
                    )}
                  </div>
                  <div className="flex gap-1 opacity-100 transition sm:opacity-0 sm:group-hover:opacity-100">
                    <button onClick={() => setShowEditModal(item)} className="rounded-lg p-1 hover:bg-gray-100">
                      <Edit3 className="h-3.5 w-3.5 text-gray-400" />
                    </button>
                    <button onClick={() => deleteItem(item.id)} className="rounded-lg p-1 hover:bg-red-50">
                      <Trash2 className="h-3.5 w-3.5 text-red-400" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Add Modal */}
      {showAddModal && (
        <ItemModal
          onClose={() => setShowAddModal(false)}
          onSaved={() => { setShowAddModal(false); loadItems(); }}
        />
      )}
      {showEditModal && (
        <ItemModal
          item={showEditModal}
          onClose={() => setShowEditModal(null)}
          onSaved={() => { setShowEditModal(null); loadItems(); }}
        />
      )}
    </AppLayout>
  );
}

function colorToHex(name: string): string {
  const map: Record<string, string> = {
    black: '#000', white: '#fff', navy: '#1e3a8a', blue: '#3b82f6', gray: '#6b7280',
    grey: '#6b7280', red: '#ef4444', green: '#22c55e', brown: '#92400e', beige: '#e8d8c4',
    pink: '#ec4899', purple: '#a855f7', olive: '#808000', orange: '#f97316', yellow: '#eab308',
    cream: '#fffdd0', charcoal: '#36454f', tan: '#d2b48c', teal: '#14b8a6',
  };
  return map[name.toLowerCase()] || '#ccc';
}

function ItemModal({ item, onClose, onSaved }: { item?: WardrobeItem; onClose: () => void; onSaved: () => void }) {
  const [form, setForm] = useState({
    name: item?.name || '',
    category: item?.category || 'shirt',
    color_primary: item?.color_primary || '',
    pattern: item?.pattern || '',
    brand: item?.brand || '',
    formality_level: item?.formality_level || 'casual',
    season: item?.season || 'all_season',
    purchase_price: item?.purchase_price || '',
  });
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    setSaving(true);
    try {
      const payload: any = { ...form };
      if (payload.purchase_price) payload.purchase_price = parseFloat(payload.purchase_price);
      else delete payload.purchase_price;
      if (item) {
        await wardrobeApi.update(item.id, payload);
      } else {
        await wardrobeApi.create(payload);
      }
      onSaved();
    } catch {
      alert('Save failed');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/30 p-0 backdrop-blur-sm sm:items-center sm:p-4" onClick={onClose}>
      <div className="max-h-[90vh] w-full overflow-y-auto rounded-t-2xl bg-white p-5 shadow-2xl sm:max-w-lg sm:rounded-2xl sm:p-6" onClick={e => e.stopPropagation()}>
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-bold text-gray-900">{item ? 'Edit Item' : 'Add Item'}</h2>
          <button onClick={onClose}><X className="h-5 w-5 text-gray-400" /></button>
        </div>
        <div className="space-y-3">
          <div>
            <label className="mb-1 block text-xs font-medium text-gray-600">Name</label>
            <input value={form.name} onChange={e => setForm({ ...form, name: e.target.value })}
              className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-indigo-400" />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="mb-1 block text-xs font-medium text-gray-600">Category</label>
              <select value={form.category} onChange={e => setForm({ ...form, category: e.target.value })}
                className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-indigo-400">
                {CATEGORIES.slice(1).map(c => <option key={c} value={c}>{c}</option>)}
              </select>
            </div>
            <div>
              <label className="mb-1 block text-xs font-medium text-gray-600">Color</label>
              <input value={form.color_primary} onChange={e => setForm({ ...form, color_primary: e.target.value })}
                className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-indigo-400" />
            </div>
            <div>
              <label className="mb-1 block text-xs font-medium text-gray-600">Pattern</label>
              <input value={form.pattern} onChange={e => setForm({ ...form, pattern: e.target.value })}
                className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-indigo-400" />
            </div>
            <div>
              <label className="mb-1 block text-xs font-medium text-gray-600">Brand</label>
              <input value={form.brand} onChange={e => setForm({ ...form, brand: e.target.value })}
                className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-indigo-400" />
            </div>
            <div>
              <label className="mb-1 block text-xs font-medium text-gray-600">Formality</label>
              <select value={form.formality_level} onChange={e => setForm({ ...form, formality_level: e.target.value })}
                className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-indigo-400">
                {['casual', 'smart_casual', 'business', 'formal', 'black_tie'].map(f => <option key={f} value={f}>{f.replace('_', ' ')}</option>)}
              </select>
            </div>
            <div>
              <label className="mb-1 block text-xs font-medium text-gray-600">Season</label>
              <select value={form.season} onChange={e => setForm({ ...form, season: e.target.value })}
                className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-indigo-400">
                {['all_season', 'spring', 'summer', 'autumn', 'winter'].map(s => <option key={s} value={s}>{s.replace('_', ' ')}</option>)}
              </select>
            </div>
          </div>
          <div>
            <label className="mb-1 block text-xs font-medium text-gray-600">Purchase Price ($)</label>
            <input type="number" value={form.purchase_price} onChange={e => setForm({ ...form, purchase_price: e.target.value as any })}
              className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm outline-none focus:border-indigo-400" />
          </div>
        </div>
        <button onClick={handleSave} disabled={saving || !form.name}
          className="mt-4 w-full rounded-xl bg-gradient-to-r from-indigo-600 to-purple-600 py-2.5 text-sm font-semibold text-white disabled:opacity-50">
          {saving ? 'Saving...' : 'Save'}
        </button>
      </div>
    </div>
  );
}

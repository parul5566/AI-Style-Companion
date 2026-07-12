import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Check, ChevronRight, Sparkles } from 'lucide-react';
import { profile as profileApi } from '../../api';

const COLORS = ['Black', 'White', 'Navy', 'Blue', 'Gray', 'Red', 'Green', 'Brown', 'Beige', 'Pink', 'Purple', 'Olive'];
const STYLES = ['Casual', 'Formal', 'Streetwear', 'Minimalist', 'Classic', 'Trendy', 'Bohemian', 'Sporty', 'Smart Casual', 'Vintage'];
const OCCASIONS = ['Work', 'Date Night', 'Wedding', 'Party', 'Gym', 'Travel', 'Interview', 'Casual Outing', 'Business Meeting'];
const BUDGETS = [
  { label: 'Budget-Conscious', min: 0, max: 100 },
  { label: 'Mid-Range', min: 100, max: 500 },
  { label: 'Premium', min: 500, max: 2000 },
  { label: 'Luxury', min: 2000, max: 10000 },
];

export function OnboardingPage() {
  const navigate = useNavigate();
  const [step, setStep] = useState(0);
  const [data, setData] = useState({
    gender: '',
    preferred_colors: [] as string[],
    avoided_colors: [] as string[],
    style_preferences: [] as string[],
    favorite_occasions: [] as string[],
    budget_min: 0,
    budget_max: 500,
  });

  const toggle = (key: 'preferred_colors' | 'avoided_colors' | 'style_preferences' | 'favorite_occasions', val: string) => {
    setData((prev) => {
      const arr = prev[key];
      return { ...prev, [key]: arr.includes(val) ? arr.filter(v => v !== val) : [...arr, val] };
    });
  };

  const finish = async () => {
    try {
      await profileApi.update({ ...data, onboarding_completed: true });
    } catch { /* ignore — profile update optional */ }
    navigate('/dashboard');
  };

  const steps = [
    // Step 0: Welcome
    {
      title: 'Welcome to Style Companion!',
      subtitle: 'Let\'s personalize your fashion experience in a few quick steps.',
      content: (
        <div className="text-center">
          <div className="mb-6 inline-flex h-20 w-20 items-center justify-center rounded-3xl bg-gradient-to-br from-indigo-500 to-purple-600">
            <Sparkles className="h-10 w-10 text-white" />
          </div>
          <p className="text-gray-600">I'll learn your style, colors, and preferences to give you the best outfit recommendations.</p>
        </div>
      ),
    },
    // Step 1: Gender
    {
      title: 'Tell us about yourself',
      subtitle: 'This helps us tailor recommendations.',
      content: (
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-4 sm:gap-4">
          {['Male', 'Female', 'Other', 'Prefer not to say'].map((g) => (
            <button
              key={g}
              onClick={() => setData({ ...data, gender: g.toLowerCase().replace(' ', '_') })}
              className={`rounded-2xl border-2 p-4 text-sm font-medium transition ${
                data.gender === g.toLowerCase().replace(' ', '_')
                  ? 'border-indigo-500 bg-indigo-50 text-indigo-700'
                  : 'border-gray-200 hover:border-gray-300'
              }`}
            >
              {g}
            </button>
          ))}
        </div>
      ),
    },
    // Step 2: Colors
    {
      title: 'Your Favorite Colors',
      subtitle: 'Pick the colors you love wearing.',
      content: (
        <div className="flex flex-wrap gap-3">
          {COLORS.map((c) => {
            const selected = data.preferred_colors.includes(c);
            return (
              <button
                key={c}
                onClick={() => toggle('preferred_colors', c)}
                className={`flex items-center gap-2 rounded-full border-2 px-4 py-2 text-sm font-medium transition ${
                  selected ? 'border-indigo-500 bg-indigo-50 text-indigo-700' : 'border-gray-200 hover:border-gray-300'
                }`}
              >
                {selected && <Check className="h-4 w-4" />}
                {c}
              </button>
            );
          })}
        </div>
      ),
    },
    // Step 3: Style
    {
      title: 'Your Style Preferences',
      subtitle: 'Select the styles that resonate with you.',
      content: (
        <div className="flex flex-wrap gap-3">
          {STYLES.map((s) => {
            const selected = data.style_preferences.includes(s);
            return (
              <button
                key={s}
                onClick={() => toggle('style_preferences', s)}
                className={`flex items-center gap-2 rounded-full border-2 px-4 py-2 text-sm font-medium transition ${
                  selected ? 'border-indigo-500 bg-indigo-50 text-indigo-700' : 'border-gray-200 hover:border-gray-300'
                }`}
              >
                {selected && <Check className="h-4 w-4" />}
                {s}
              </button>
            );
          })}
        </div>
      ),
    },
    // Step 4: Occasions
    {
      title: 'Favorite Occasions',
      subtitle: 'What do you dress up for most?',
      content: (
        <div className="flex flex-wrap gap-3">
          {OCCASIONS.map((o) => {
            const selected = data.favorite_occasions.includes(o);
            return (
              <button
                key={o}
                onClick={() => toggle('favorite_occasions', o)}
                className={`flex items-center gap-2 rounded-full border-2 px-4 py-2 text-sm font-medium transition ${
                  selected ? 'border-indigo-500 bg-indigo-50 text-indigo-700' : 'border-gray-200 hover:border-gray-300'
                }`}
              >
                {selected && <Check className="h-4 w-4" />}
                {o}
              </button>
            );
          })}
        </div>
      ),
    },
    // Step 5: Budget
    {
      title: 'Your Shopping Budget',
      subtitle: 'Help us suggest items in your price range.',
      content: (
        <div className="space-y-3">
          {BUDGETS.map((b) => {
            const selected = data.budget_min === b.min && data.budget_max === b.max;
            return (
              <button
                key={b.label}
                onClick={() => setData({ ...data, budget_min: b.min, budget_max: b.max })}
                className={`flex w-full items-center justify-between rounded-2xl border-2 p-4 transition ${
                  selected ? 'border-indigo-500 bg-indigo-50' : 'border-gray-200 hover:border-gray-300'
                }`}
              >
                <span className="font-medium text-gray-900">{b.label}</span>
                <span className="text-sm text-gray-500">${b.min} - ${b.max}</span>
              </button>
            );
          })}
        </div>
      ),
    },
  ];

  const current = steps[step];
  const isLast = step === steps.length - 1;

  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-indigo-600 via-purple-600 to-pink-500 p-3 sm:p-4">
      <div className="w-full max-w-2xl">
        {/* Progress */}
        <div className="mb-4 flex gap-2 sm:mb-6">
          {steps.map((_, i) => (
            <div
              key={i}
              className={`h-1.5 flex-1 rounded-full transition-all ${
                i <= step ? 'bg-white' : 'bg-white/30'
              }`}
            />
          ))}
        </div>

        <div className="glass rounded-2xl p-5 shadow-2xl fade-in sm:rounded-3xl sm:p-8" key={step}>
          <h2 className="text-xl font-bold text-gray-900 sm:text-2xl">{current.title}</h2>
          <p className="mt-1 text-sm text-gray-500">{current.subtitle}</p>
          <div className="mt-6 mb-6 sm:mt-8 sm:mb-8">{current.content}</div>

          <div className="flex justify-between">
            <button
              onClick={() => step > 0 && setStep(step - 1)}
              className={`rounded-xl px-6 py-3 text-sm font-medium transition ${
                step === 0 ? 'invisible' : 'text-gray-600 hover:bg-gray-100'
              }`}
            >
              Back
            </button>
            <button
              onClick={() => (isLast ? finish() : setStep(step + 1))}
              className="flex items-center gap-2 rounded-xl bg-gradient-to-r from-indigo-600 to-purple-600 px-6 py-3 text-sm font-semibold text-white shadow-lg shadow-indigo-500/30 transition hover:shadow-xl"
            >
              {isLast ? 'Complete Setup' : 'Continue'}
              <ChevronRight className="h-4 w-4" />
            </button>
          </div>
        </div>

        {step > 0 && (
          <button
            onClick={finish}
            className="mt-4 w-full text-center text-sm text-white/60 hover:text-white"
          >
            Skip for now
          </button>
        )}
      </div>
    </div>
  );
}

import { useEffect, useRef, useState } from 'react';
import { Send, Sparkles, MessageSquare } from 'lucide-react';
import { chat as chatApi } from '../../api';
import type { ChatMessage } from '../../types';
import { AppLayout } from '../../components/AppLayout';

export function ChatPage() {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState('');
  const [conversationId, setConversationId] = useState<number | null>(null);
  const [loading, setLoading] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    loadConversations();
  }, []);

  useEffect(() => {
    scrollRef.current?.scrollTo(0, scrollRef.current.scrollHeight);
  }, [messages, loading]);

  const loadConversations = async () => {
    try {
      const convs = await chatApi.conversations();
      if (convs.length > 0) {
        const latest = convs[0];
        setConversationId(latest.id);
        setMessages(latest.messages);
      }
    } catch { /* ignore */ }
  };

  const send = async () => {
    if (!input.trim() || loading) return;
    const userMsg: ChatMessage = {
      conversation_id: conversationId || 0,
      role: 'user',
      content: input,
    };
    setMessages(prev => [...prev, userMsg]);
    const msg = input;
    setInput('');
    setLoading(true);

    try {
      const res = await chatApi.send({ message: msg, conversation_id: conversationId || undefined });
      setConversationId(res.conversation_id);
      setMessages(prev => [...prev, res]);
    } catch {
      setMessages(prev => [...prev, {
        conversation_id: conversationId || 0,
        role: 'assistant',
        content: 'Sorry, I encountered an error. Please try again.',
      }]);
    } finally {
      setLoading(false);
    }
  };

  const suggestions = [
    'What should I wear today?',
    'Suggest an outfit for a job interview',
    'How do I style a navy blazer?',
    'What colors go well with olive green?',
  ];

  return (
    <AppLayout>
      <div className="mb-4 flex items-center gap-2 sm:mb-6">
        <Sparkles className="h-6 w-6 text-indigo-600 sm:h-7 sm:w-7" />
        <h1 className="text-2xl font-bold text-gray-900 sm:text-3xl">AI Fashion Chat</h1>
      </div>

      <div className="flex h-[calc(100vh-180px)] flex-col rounded-2xl glass sm:h-[calc(100vh-200px)]">
        {/* Messages */}
        <div ref={scrollRef} className="flex-1 overflow-y-auto p-4 space-y-4 sm:p-6">
          {messages.length === 0 && (
            <div className="flex h-full flex-col items-center justify-center text-center">
              <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-gradient-to-br from-indigo-500 to-purple-600">
                <MessageSquare className="h-8 w-8 text-white" />
              </div>
              <h3 className="text-lg font-semibold text-gray-900">Ask me anything about fashion!</h3>
              <p className="mt-1 text-sm text-gray-500">I have access to your wardrobe and style preferences</p>
              <div className="mt-6 flex flex-wrap justify-center gap-2">
                {suggestions.map((s, i) => (
                  <button key={i} onClick={() => { setInput(s); }}
                    className="rounded-full border border-gray-200 bg-white/50 px-4 py-2 text-sm text-gray-600 transition hover:border-indigo-300 hover:bg-indigo-50">
                    {s}
                  </button>
                ))}
              </div>
            </div>
          )}

          {messages.map((msg, i) => (
            <div key={i} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'} fade-in`}>
              <div className={`max-w-[70%] rounded-2xl px-4 py-3 ${
                msg.role === 'user'
                  ? 'bg-gradient-to-r from-indigo-600 to-purple-600 text-white'
                  : 'bg-white border border-gray-200 text-gray-800'
              }`}>
                <p className="text-sm whitespace-pre-wrap">{msg.content}</p>
              </div>
            </div>
          ))}

          {loading && (
            <div className="flex justify-start fade-in">
              <div className="rounded-2xl bg-white border border-gray-200 px-4 py-3">
                <div className="flex gap-1">
                  <span className="typing-dot h-2 w-2 rounded-full bg-gray-400"></span>
                  <span className="typing-dot h-2 w-2 rounded-full bg-gray-400"></span>
                  <span className="typing-dot h-2 w-2 rounded-full bg-gray-400"></span>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Input */}
        <div className="border-t border-gray-200 p-3 sm:p-4">
          <div className="flex gap-2">
            <input
              value={input}
              onChange={e => setInput(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && send()}
              placeholder="Ask about outfits, styling, fashion tips..."
              className="flex-1 rounded-xl border border-gray-200 bg-white px-4 py-3 text-sm outline-none focus:border-indigo-400"
              disabled={loading}
            />
            <button onClick={send} disabled={loading || !input.trim()}
              className="flex items-center gap-2 rounded-xl bg-gradient-to-r from-indigo-600 to-purple-600 px-5 py-3 text-sm font-semibold text-white shadow-lg shadow-indigo-500/30 transition hover:shadow-xl disabled:opacity-50">
              <Send className="h-4 w-4" />
            </button>
          </div>
        </div>
      </div>
    </AppLayout>
  );
}

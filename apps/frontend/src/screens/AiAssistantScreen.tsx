import React, { useState } from 'react';
import { TabType, AiChatMessage } from '../types';
import { Bot, Send, User, ArrowRight, PackageCheck, BarChart2, Zap, Loader2, Trash2, Check } from 'lucide-react';
import './AiAssistantScreen.css';

interface AiAssistantScreenProps {
  onNavigateTab: (tab: TabType) => void;
  messages: AiChatMessage[];
  loading: boolean;
  onSend: (text: string) => Promise<{ user: AiChatMessage; ai: AiChatMessage }>;
  onConfirmAction: (actionId: string) => Promise<void>;
  onClear: () => Promise<void>;
  refresh: () => Promise<void>;
}

export const AiAssistantScreen: React.FC<AiAssistantScreenProps> = ({
  onNavigateTab, messages, loading, onSend, onConfirmAction, onClear, refresh,
}) => {
  const [inputText, setInputText] = useState<string>('');
  const [sending, setSending] = useState(false);

  const quickPrompts = [
    { title: 'Cek Stok', prompt: 'stok apa yang menipis?', icon: PackageCheck },
    { title: 'Analisis Omzet', prompt: 'Bagaimana tren penjualan minggu ini?', icon: BarChart2 },
    { title: 'Prediksi', prompt: 'Kapan waktu teramai transaksi?', icon: Zap },
  ];

  const handleSend = async (textToSend?: string) => {
    const text = textToSend || inputText;
    if (!text.trim()) return;
    if (!textToSend) setInputText('');
    setSending(true);
    try {
      await onSend(text);
    } finally { setSending(false); }
  };

  return (
    <div className="page-screen ai-screen-container animate-fade-in">
      <div className="screen-header">
        <div className="ai-title-group">
          <div className="ai-bot-avatar"><Bot size={24} color="#ffffff" /></div>
          <div>
            <h1 className="screen-title">AI Assistant 'Tiga Angkatan'</h1>
            <p className="screen-sub">Ditenagai NLP backend. Mampu mencatat stok & pengeluaran otomatis.</p>
          </div>
        </div>
        <button onClick={onClear} className="btn-secondary btn-sm" title="Hapus semua pesan">
          <Trash2 size={14} /> Clear
        </button>
      </div>

      <div className="card-base ai-chat-card">
        <div className="quick-prompts-bar">
          <span className="prompts-label">Tanyakan pada AI:</span>
          <div className="prompts-scroll">
            {quickPrompts.map((item, idx) => {
              const IconComponent = item.icon;
              return (
                <button key={idx} onClick={() => handleSend(item.prompt)} className="prompt-chip">
                  <IconComponent size={14} className="chip-icon" /><span>{item.title}</span>
                </button>
              );
            })}
          </div>
        </div>

        <div className="messages-stream">
          {loading && messages.length === 0 ? (
            <div className="empty-state-small">Memuat percakapan dari server...</div>
          ) : messages.map((msg) => {
            const isAi = msg.sender === 'ai';
            return (
              <div key={msg.id} className={`message-bubble-wrap ${isAi ? 'ai' : 'user'}`}>
                <div className={`message-avatar ${isAi ? 'ai-avatar' : 'user-avatar'}`}>
                  {isAi ? <Bot size={16} /> : <User size={16} />}
                </div>
                <div className="message-content-box">
                  <div className="message-header-info">
                    <span className="sender-name">{isAi ? 'AI Assistant' : 'Anda'}</span>
                    <span className="timestamp">{msg.timestamp}</span>
                  </div>
                  <p className="message-text">{msg.text}</p>

                  {msg.recommendations && msg.recommendations.length > 0 && (
                    <div className="recommendations-container">
                      {msg.recommendations.map((rec, rIdx) => (
                        <div key={rIdx} className="rec-card">
                          <span className="rec-title">{rec.title}</span>
                          <button onClick={() => onNavigateTab(rec.actionTab)} className="btn-primary btn-rec-action">
                            {rec.actionText} <ArrowRight size={14} />
                          </button>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            );
          })}

          {sending && (
            <div className="message-bubble-wrap ai">
              <div className="message-avatar ai-avatar"><Bot size={16} /></div>
              <div className="typing-indicator-box">
                <span className="typing-dot"></span>
                <span className="typing-dot"></span>
                <span className="typing-dot"></span>
                <span className="typing-text">AI sedang menganalisis...</span>
              </div>
            </div>
          )}
        </div>

        <div className="chat-input-bar">
          <input
            type="text"
            placeholder="Coba: 'beli gula 5kg 170rb' atau 'stok menipis?'"
            value={inputText}
            onChange={(e) => setInputText(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSend()}
            className="ai-chat-input"
          />
          <button onClick={() => handleSend()} disabled={!inputText.trim() || sending} className="btn-primary btn-send-chat">
            {sending ? <Loader2 size={16} className="spin" /> : <Send size={16} />}
          </button>
        </div>
      </div>
    </div>
  );
};

export default AiAssistantScreen;

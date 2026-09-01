import React, { useState } from 'react';
import { TabType, AiChatMessage } from '../types';
import { Bot, Send, Sparkles, User, ArrowRight, RefreshCw, BarChart2, PackageCheck, Zap } from 'lucide-react';
import './AiAssistantScreen.css';

interface AiAssistantScreenProps {
  onNavigateTab: (tab: TabType) => void;
  messages: AiChatMessage[];
  setMessages: React.Dispatch<React.SetStateAction<AiChatMessage[]>>;
}

export const AiAssistantScreen: React.FC<AiAssistantScreenProps> = ({
  onNavigateTab,
  messages,
  setMessages
}) => {
  const [inputText, setInputText] = useState<string>('');
  const [isTyping, setIsTyping] = useState<boolean>(false);

  const quickPrompts = [
    { title: 'Restock Produk', prompt: 'Produk mana yang perlu saya restock hari ini?', icon: PackageCheck },
    { title: 'Analisis Omzet', prompt: 'Bagaimana tren penjualan toko minggu ini?', icon: BarChart2 },
    { title: 'Prediksi Pelanggan', prompt: 'Kapan waktu teramai transaksi biasanya terjadi?', icon: Zap },
  ];

  const handleSendMessage = (textToSend?: string) => {
    const text = textToSend || inputText;
    if (!text.trim()) return;

    const userMsg: AiChatMessage = {
      id: `msg-${Date.now()}`,
      sender: 'user',
      text,
      timestamp: new Date().toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })
    };

    setMessages((prev) => [...prev, userMsg]);
    if (!textToSend) setInputText('');
    setIsTyping(true);

    // Simulate smart AI response
    setTimeout(() => {
      let responseText = 'Berdasarkan analisis data transaksi toko Anda: Omzet hari ini stabil di Rp 1.450.000 dengan 18 transaksi. Produk terlaris adalah Beras Pandan Wangi 5kg.';
      let recs: { title: string; actionText: string; actionTab: TabType }[] = [];

      if (text.toLowerCase().includes('restock') || text.toLowerCase().includes('stok')) {
        responseText = '⚠️ **Perhatian Restock**: Stok Susu Indomilk Kental Manis sisa 2 kaleng (di bawah min 10) dan Gula Pasir Gulaku sisa 3kg. Disarankan melakukan pemesanan kulakan hari ini agar tidak kehabisan stok esok hari.';
        recs = [{ title: 'Buka Manajemen Stok', actionText: 'Lihat Stok', actionTab: 'stock' }];
      } else if (text.toLowerCase().includes('omzet') || text.toLowerCase().includes('penjualan')) {
        responseText = '📊 **Analisis Omzet**: Penjualan Anda naik +12.5% dibanding hari kemarin. Kategori Sembako menyumbang 68% dari total pendapatan toko.';
        recs = [{ title: 'Buka Laporan Keuangan', actionText: 'Lihat Keuangan', actionTab: 'finance' }];
      } else {
        recs = [
          { title: 'Periksa Produk Menipis', actionText: 'Ke Stok', actionTab: 'stock' },
          { title: 'Catat Pengeluaran Baru', actionText: 'Ke Keuangan', actionTab: 'finance' }
        ];
      }

      const aiMsg: AiChatMessage = {
        id: `msg-${Date.now() + 1}`,
        sender: 'ai',
        text: responseText,
        timestamp: new Date().toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }),
        recommendations: recs
      };

      setMessages((prev) => [...prev, aiMsg]);
      setIsTyping(false);
    }, 1200);
  };

  return (
    <div className="page-screen ai-screen-container animate-fade-in">
      {/* Header */}
      <div className="screen-header">
        <div className="ai-title-group">
          <div className="ai-bot-avatar">
            <Bot size={24} color="#ffffff" />
          </div>
          <div>
            <h1 className="screen-title">AI Assistant 'Tiga Angkatan'</h1>
            <p className="screen-sub">Asisten pintar bisnis untuk analisis penjualan & otomatisasi stok.</p>
          </div>
        </div>
      </div>

      {/* Main Chat Workspace */}
      <div className="card-base ai-chat-card">
        {/* Quick Suggestion Chips */}
        <div className="quick-prompts-bar">
          <span className="prompts-label">Tanyakan pada AI:</span>
          <div className="prompts-scroll">
            {quickPrompts.map((item, idx) => {
              const IconComponent = item.icon;
              return (
                <button
                  key={idx}
                  onClick={() => handleSendMessage(item.prompt)}
                  className="prompt-chip"
                >
                  <IconComponent size={14} className="chip-icon" />
                  <span>{item.title}</span>
                </button>
              );
            })}
          </div>
        </div>

        {/* Message Conversation Stream */}
        <div className="messages-stream">
          {messages.map((msg) => {
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

                  {/* Recommendation Card Actions if attached */}
                  {msg.recommendations && msg.recommendations.length > 0 && (
                    <div className="recommendations-container">
                      {msg.recommendations.map((rec, rIdx) => (
                        <div key={rIdx} className="rec-card">
                          <span className="rec-title">{rec.title}</span>
                          <button
                            onClick={() => onNavigateTab(rec.actionTab)}
                            className="btn-primary btn-rec-action"
                          >
                            {rec.actionText}
                            <ArrowRight size={14} />
                          </button>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            );
          })}

          {isTyping && (
            <div className="message-bubble-wrap ai">
              <div className="message-avatar ai-avatar">
                <Bot size={16} />
              </div>
              <div className="typing-indicator-box">
                <span className="typing-dot"></span>
                <span className="typing-dot"></span>
                <span className="typing-dot"></span>
                <span className="typing-text">AI sedang menganalisis data...</span>
              </div>
            </div>
          )}
        </div>

        {/* Chat Input Bar */}
        <div className="chat-input-bar">
          <input
            type="text"
            placeholder="Ketik pertanyaan bisnis Anda (misal: 'Bagaimana tren omzet minggu ini?')..."
            value={inputText}
            onChange={(e) => setInputText(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSendMessage()}
            className="ai-chat-input"
          />
          <button
            onClick={() => handleSendMessage()}
            disabled={!inputText.trim()}
            className="btn-primary btn-send-chat"
          >
            <Send size={16} />
          </button>
        </div>
      </div>
    </div>
  );
};

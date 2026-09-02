import React, { useState, useEffect, useRef, useMemo } from 'react';
import { TabType, AiChatMessage } from '../types';
import type { AdaptedAiMessage } from '../lib/adapters';
import {
  Bot,
  Send,
  User,
  ArrowRight,
  PackageCheck,
  BarChart2,
  Zap,
  Loader2,
  Trash2,
  Copy,
  Check,
  Sparkles,
  AlertTriangle,
  Receipt,
  FileText,
  Clock,
  CheckCircle2,
  Lightbulb,
  ClipboardCheck,
} from 'lucide-react';
import { animateScreenEntrance } from '../lib/animations';
import './AiAssistantScreen.css';

interface AiAssistantScreenProps {
  onNavigateTab: (tab: TabType) => void;
  messages: AiChatMessage[];
  messagesRaw: AdaptedAiMessage[];
  loading: boolean;
  onSend: (text: string) => Promise<{ user: AiChatMessage; ai: AiChatMessage }>;
  onConfirmAction: (actionId: string) => Promise<void>;
  onClear: () => Promise<void>;
  refresh: () => Promise<void>;
}

export const AiAssistantScreen: React.FC<AiAssistantScreenProps> = ({
  onNavigateTab, messages, messagesRaw, loading, onSend, onConfirmAction, onClear, refresh,
}) => {
  // Map message.id -> AdaptedAiMessage for quick lookup of action payloads.
  const rawById = useMemo(() => {
    const m = new Map<string, AdaptedAiMessage>();
    (messagesRaw || []).forEach((r) => m.set(r.id, r));
    return m;
  }, [messagesRaw]);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    animateScreenEntrance(containerRef.current);
  }, []);

  const [inputText, setInputText] = useState<string>('');
  const [sending, setSending] = useState(false);
  const [copiedId, setCopiedId] = useState<string | null>(null);

  const capabilities = [
    {
      title: 'Deteksi Stok & Restock',
      desc: 'Analisis sisa bahan baku & hitung kebutuhan kulakan sebelum jam sibuk.',
      prompt: 'stok apa yang menipis dan perlu segera di-restock?',
      icon: PackageCheck,
      badge: 'Inventaris',
    },
    {
      title: 'Evaluasi Margin & Omzet',
      desc: 'Hitung laba bersih, margin %, dan produk paling laris hari ini.',
      prompt: 'Bagaimana tren omzet dan margin laba bersih hari ini?',
      icon: BarChart2,
      badge: 'Finansial',
    },
    {
      title: 'Generator Promo WhatsApp',
      desc: 'Buatkan pesan broadcast promo paket kopi hemat yang memikat.',
      prompt: 'buatkan draf promo kopi hemat sore untuk broadcast WhatsApp',
      icon: Zap,
      badge: 'Marketing',
    },
    {
      title: 'Catat Kulakan Bebas (NLP)',
      desc: 'Ketik bahasa santai: "beli susu uht 12L 280rb" untuk catat otomatis.',
      prompt: 'catat pengeluaran kulakan susu uht 12 liter senilai 288000',
      icon: Receipt,
      badge: 'Pencatatan',
    },
  ];

  const handleSend = async (textToSend?: string) => {
    const text = textToSend || inputText;
    if (!text.trim()) return;
    if (!textToSend) setInputText('');
    setSending(true);
    try {
      await onSend(text);
    } finally {
      setSending(false);
    }
  };

  const handleCopyText = (id: string, text: string) => {
    navigator.clipboard?.writeText(text);
    setCopiedId(id);
    setTimeout(() => setCopiedId(null), 2000);
  };

  return (
    <div ref={containerRef} className="page-screen ai-screen-container">
      {/* ── Screen Header ── */}
      <div className="screen-header gsap-reveal">
        <div className="ai-title-group">
          <div className="ai-bot-avatar">
            <img src="/iconAisistenku.png" alt="AIsistenku" className="ai-bot-header-logo" />
          </div>
          <div>
            <div className="ai-title-row">
              <h1 className="screen-title">AIsistenku (AI Copilot Bisnis)</h1>
              <span className="copilot-badge-live">
                <span className="live-pulse"></span>
                Terkoneksi Database Toko
              </span>
            </div>
            <p className="screen-sub">
              Asisten berbasis NLP untuk analisis data POS, deteksi dini stok habis, dan draf promosi digital.
            </p>
          </div>
        </div>

        <button onClick={onClear} className="btn-secondary btn-sm" title="Hapus riwayat chat">
          <Trash2 size={14} /> Clear Chat
        </button>
      </div>

      {/* ── 2-Column Copilot Workspace ── */}
      <div className="ai-copilot-layout">
        {/* Left Column (Capabilities & Health Context) */}
        <div className="ai-context-sidebar gsap-reveal">
          {/* Store Live Intelligence Box */}
          <div className="card-base store-intelligence-card">
            <div className="intel-header">
              <div className="intel-title-wrap">
                <Lightbulb size={16} className="text-teal" />
                <span className="intel-title">Status Analisis Toko</span>
              </div>
              <span className="intel-score-chip">Skor 92/100</span>
            </div>

            <div className="intel-items-list">
              <div className="intel-row">
                <span className="intel-label">Bahan Kritis (&lt; Batas Min)</span>
                <span className="intel-val warning-text">2 Bahan Baku</span>
              </div>
              <div className="intel-row">
                <span className="intel-label">Menu Terlaris</span>
                <span className="intel-val">Iced Latte (42 cup)</span>
              </div>
              <div className="intel-row">
                <span className="intel-label">Estimasi Margin Laba</span>
                <span className="intel-val text-teal">74.0%</span>
              </div>
            </div>

            <div className="intel-suggestion">
              <AlertTriangle size={13} className="text-amber" />
              <span>Gula Aren &amp; Susu UHT perlu restock sebelum jam 16.00 WIB.</span>
            </div>
          </div>

          {/* Capability Launchers */}
          <div className="capabilities-header">
            <span className="capabilities-title">Tugas &amp; Perintah Cepat</span>
          </div>

          <div className="capabilities-list">
            {capabilities.map((cap, idx) => {
              const IconComponent = cap.icon;
              return (
                <div
                  key={idx}
                  onClick={() => handleSend(cap.prompt)}
                  className="card-base capability-item-card"
                  title="Klik untuk langsung tanyakan ke AI"
                >
                  <div className="cap-top-row">
                    <div className="cap-icon-box">
                      <IconComponent size={16} />
                    </div>
                    <span className="cap-badge">{cap.badge}</span>
                  </div>
                  <h4 className="cap-title">{cap.title}</h4>
                  <p className="cap-desc">{cap.desc}</p>
                </div>
              );
            })}
          </div>
        </div>

        {/* Right Column (Interactive Chat Stream) */}
        <div className="card-base ai-main-chat-card gsap-reveal">
          {/* Quick Prompt Suggestion Bar */}
          <div className="chat-quick-suggestions">
            <span className="sugg-label">Saran Topik:</span>
            <div className="sugg-scroll">
              <button
                type="button"
                onClick={() => handleSend('stok apa yang menipis?')}
                className="sugg-chip"
              >
                <PackageCheck size={13} />
                <span>Cek Stok Menipis</span>
              </button>
              <button
                type="button"
                onClick={() => handleSend('Bagaimana tren omzet dan margin hari ini?')}
                className="sugg-chip"
              >
                <BarChart2 size={13} />
                <span>Analisis Omzet</span>
              </button>
              <button
                type="button"
                onClick={() => handleSend('buatkan draf promo kopi hemat sore untuk whatsapp')}
                className="sugg-chip"
              >
                <Zap size={13} />
                <span>Draf Promo WA</span>
              </button>
            </div>
          </div>

          {/* Messages Stream */}
          <div className="messages-stream">
            {loading && messages.length === 0 ? (
              <div className="empty-state-small">Menghubungkan ke server AI...</div>
            ) : (
              messages.map((msg) => {
                const isAi = msg.sender === 'ai';
                const raw = rawById.get(msg.id);
                const actionPayload = raw?.actionPayload;
                const actionStatus = raw?.actionStatus || actionPayload?.status;
                const isRestockConfirm =
                  isAi &&
                  actionPayload?.intent === 'ADD_STOCK_AND_EXPENSE' &&
                  actionStatus === 'pending';
                const isConfirmed =
                  isAi &&
                  actionPayload?.intent === 'ADD_STOCK_AND_EXPENSE' &&
                  actionStatus === 'confirmed';
                return (
                  <div key={msg.id} className={`message-bubble-wrap ${isAi ? 'ai' : 'user'}`}>
                    <div className={`message-avatar ${isAi ? 'ai-avatar' : 'user-avatar'}`}>
                      {isAi ? (
                        <img src="/iconAisistenku.png" alt="AIsistenku" className="ai-msg-avatar-logo" />
                      ) : (
                        <User size={16} />
                      )}
                    </div>

                    <div className="message-content-box">
                      <div className="message-header-info">
                        <span className="sender-name">
                          {isAi ? 'AIsistenku Copilot' : 'Kasir Utama'}
                        </span>
                        <span className="timestamp">{msg.timestamp}</span>
                      </div>

                      <div className="message-text-body">
                        {msg.text.split('\n').map((line, pIdx) => {
                          if (!line.trim()) return <div key={pIdx} className="msg-space" />;
                          
                          // Format bold text like **bold**
                          const parts = line.split(/(\*\*.*?\*\*)/g);
                          return (
                            <p key={pIdx} className="msg-paragraph">
                              {parts.map((part, partIdx) => {
                                if (part.startsWith('**') && part.endsWith('**')) {
                                  return (
                                    <strong key={partIdx} className="msg-bold">
                                      {part.slice(2, -2)}
                                    </strong>
                                  );
                                }
                                return part;
                              })}
                            </p>
                          );
                        })}
                      </div>

                      {/* If AI message contains promo or copyable text, show copy button */}
                      {isAi && (
                        <div className="message-footer-tools">
                          <button
                            type="button"
                            onClick={() => handleCopyText(msg.id, msg.text)}
                            className="btn-copy-msg"
                            title="Salin jawaban AI"
                          >
                            {copiedId === msg.id ? (
                              <>
                                <Check size={12} className="text-teal" />
                                <span>Tersalin ke Clipboard</span>
                              </>
                            ) : (
                              <>
                                <Copy size={12} />
                                <span>Salin Jawaban</span>
                              </>
                            )}
                          </button>
                        </div>
                      )}

                      {/* Interactive Recommendation Action Cards */}
                      {msg.recommendations && msg.recommendations.length > 0 && (
                        <div className="recommendations-container">
                          {msg.recommendations.map((rec, rIdx) => (
                            <div key={rIdx} className="rec-card">
                              <div className="rec-info">
                                <CheckCircle2 size={15} className="text-teal" />
                                <span className="rec-title">{rec.title}</span>
                              </div>
                              <button
                                type="button"
                                onClick={() => onNavigateTab(rec.actionTab)}
                                className="btn-primary btn-rec-action"
                              >
                                <span>{rec.actionText}</span>
                                <ArrowRight size={13} />
                              </button>
                            </div>
                          ))}
                        </div>
                      )}

                      {/* Restock/Expense confirm card from AI action payload */}
                      {isRestockConfirm && actionPayload && (
                        <div className="ai-action-confirm-card">
                          <div className="ai-action-confirm-head">
                            <ClipboardCheck size={16} className="text-teal" />
                            <span>Konfirmasi Pencatatan Otomatis</span>
                          </div>
                          <div className="ai-action-confirm-body">
                            <div className="ai-action-confirm-row">
                              <span>Item</span>
                              <strong>{actionPayload.itemName}</strong>
                            </div>
                            <div className="ai-action-confirm-row">
                              <span>Jumlah</span>
                              <strong>
                                {actionPayload.quantity} {actionPayload.unit}
                              </strong>
                            </div>
                            <div className="ai-action-confirm-row">
                              <span>Estimasi Biaya</span>
                              <strong>
                                Rp {Number(actionPayload.expenseAmount || 0).toLocaleString('id-ID')}
                              </strong>
                            </div>
                          </div>
                          <button
                            type="button"
                            onClick={() => onConfirmAction(actionPayload.actionId)}
                            className="btn-primary btn-confirm-action"
                          >
                            <Check size={14} />
                            <span>Konfirmasi &amp; Catat</span>
                          </button>
                        </div>
                      )}

                      {isConfirmed && (
                        <div className="ai-action-confirmed-pill">
                          <CheckCircle2 size={14} className="text-teal" />
                          <span>
                            Tercatat: {actionPayload?.quantity} {actionPayload?.unit} {actionPayload?.itemName} • Rp{' '}
                            {Number(actionPayload?.expenseAmount || 0).toLocaleString('id-ID')}
                          </span>
                        </div>
                      )}
                    </div>
                  </div>
                );
              })
            )}

            {sending && (
              <div className="message-bubble-wrap ai">
                <div className="message-avatar ai-avatar">
                  <Bot size={18} />
                </div>
                <div className="typing-indicator-box">
                  <span className="typing-dot"></span>
                  <span className="typing-dot"></span>
                  <span className="typing-dot"></span>
                  <span className="typing-text">AIsistenku sedang menganalisis data toko...</span>
                </div>
              </div>
            )}
          </div>

          {/* Interactive Chat Input Bar */}
          <div className="chat-input-bar">
            <div className="chat-input-wrapper">
              <input
                type="text"
                placeholder="Tanyakan analisis bisnis atau ketik perintah (contoh: 'stok apa yang menipis?')..."
                value={inputText}
                onChange={(e) => setInputText(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault();
                    handleSend();
                  }
                }}
                className="ai-chat-input"
              />
              <span className="input-hint">Tekan ↵ Enter untuk kirim</span>
            </div>

            <button
              type="button"
              onClick={() => handleSend()}
              disabled={!inputText.trim() || sending}
              className="btn-primary btn-send-chat"
              title="Kirim pesan"
            >
              {sending ? <Loader2 size={16} className="spin" /> : <Send size={16} />}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AiAssistantScreen;

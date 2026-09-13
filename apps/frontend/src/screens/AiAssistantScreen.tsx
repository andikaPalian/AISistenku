import React, { useState, useEffect, useRef, useMemo } from 'react';
import { TabType, AiChatMessage, StockAlert } from '../types';
import type { AdaptedAiMessage } from '../lib/adapters';
import {
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
  CheckCircle2,
  Lightbulb,
  ClipboardCheck,
  MessageSquare,
} from 'lucide-react';
import { animateScreenEntrance } from '../lib/animations';
import './AiAssistantScreen.css';

export interface AiAssistantScreenProps {
  onNavigateTab: (tab: TabType) => void;
  messages: AiChatMessage[];
  messagesRaw: AdaptedAiMessage[];
  loading: boolean;
  onSend: (text: string) => Promise<{ user: AiChatMessage; ai: AiChatMessage }>;
  onConfirmAction: (actionId: string) => Promise<void>;
  onClear: () => Promise<void>;
  refresh: () => Promise<void>;
  stockAlerts?: StockAlert[];
  dashboard?: any;
  stocks?: any[];
}

export const AiAssistantScreen: React.FC<AiAssistantScreenProps> = ({
  onNavigateTab,
  messages,
  messagesRaw,
  loading,
  onSend,
  onConfirmAction,
  onClear,
  stockAlerts = [],
  dashboard,
}) => {
  // Map message.id -> AdaptedAiMessage for quick lookup of action payloads.
  const rawById = useMemo(() => {
    const m = new Map<string, AdaptedAiMessage>();
    (messagesRaw || []).forEach((r) => m.set(r.id, r));
    return m;
  }, [messagesRaw]);

  const containerRef = useRef<HTMLDivElement>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  const [inputText, setInputText] = useState<string>('');
  const [sending, setSending] = useState(false);
  const [copiedId, setCopiedId] = useState<string | null>(null);

  useEffect(() => {
    animateScreenEntrance(containerRef.current);
  }, []);

  // Auto scroll to latest message
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, sending]);

  // Derive real live store metrics
  const criticalCount = stockAlerts.length;
  const criticalNames = stockAlerts
    .slice(0, 2)
    .map((s) => s.productName)
    .join(' & ');
  const storeHealthScore = criticalCount === 0 ? 98 : criticalCount <= 2 ? 85 : 68;
  const storeHealthStatus =
    storeHealthScore >= 90 ? 'Optimal' : storeHealthScore >= 75 ? 'Perlu Restock' : 'Kritis';

  const todaySalesFormatted = dashboard?.todayRevenue
    ? `Rp ${Number(dashboard.todayRevenue).toLocaleString('id-ID')}`
    : 'Rp 0';

  const todayOrdersFormatted = dashboard?.todayOrdersCount
    ? `${dashboard.todayOrdersCount} Pesanan`
    : '0 Pesanan';

  const capabilities = [
    {
      title: 'Deteksi Stok & Restock',
      desc: 'Analisis sisa bahan baku & hitung kebutuhan kulakan sebelum jam sibuk.',
      prompt: 'stok apa yang menipis dan perlu segera di-restock?',
      icon: PackageCheck,
      badge: 'Inventaris',
    },
    {
      title: 'Evaluasi Omzet Hari Ini',
      desc: 'Hitung omzet, transaksi kasir terkini, dan tren penjualan toko.',
      prompt: 'Bagaimana tren omzet dan jumlah penjualan hari ini?',
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
      desc: 'Ketik bahasa santai untuk catat stok atau pengeluaran operasional.',
      prompt: 'catat pengeluaran beli susu fresh milk 12 liter senilai 280000',
      icon: Receipt,
      badge: 'Pencatatan',
    },
  ];

  const handleSend = async (textToSend?: string) => {
    const text = textToSend || inputText;
    if (!text.trim() || sending) return;
    if (!textToSend) setInputText('');
    setSending(true);
    try {
      await onSend(text);
    } finally {
      setSending(false);
      inputRef.current?.focus();
    }
  };

  const handleCopyText = (id: string, text: string) => {
    navigator.clipboard?.writeText(text);
    setCopiedId(id);
    setTimeout(() => setCopiedId(null), 2200);
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
              <h1 className="screen-title">AIsistenku</h1>
            </div>
            {/* <p className="screen-sub">
              Asisten berbasis AI &amp; NLP untuk analisis data POS, deteksi dini stok habis, dan
              draf promosi digital.
            </p> */}
          </div>
        </div>

        <button
          onClick={onClear}
          className="btn-secondary btn-sm btn-clear-chat"
          title="Hapus riwayat percakapan"
        >
          <Trash2 size={14} /> Clear Chat
        </button>
      </div>

      {/* ── 2-Column Copilot Workspace ── */}
      <div className="ai-copilot-layout">
        {/* Left Column (Store Context & Quick Capabilities) */}
        <div className="ai-context-sidebar gsap-reveal">
          {/* Store Live Intelligence Box */}
          <div className="store-intelligence-card">
            <div className="intel-header">
              <div className="intel-title-wrap">
                <Lightbulb size={16} className="text-teal" />
                <span className="intel-title">Status Analisis Toko</span>
              </div>
              <span
                className={`intel-score-chip ${
                  storeHealthScore >= 90 ? 'score-good' : 'score-warn'
                }`}
              >
                Skor {storeHealthScore}/100 • {storeHealthStatus}
              </span>
            </div>

            <div className="intel-items-list">
              <div className="intel-row">
                <span className="intel-label">Bahan Kritis (&lt; Batas Min)</span>
                {criticalCount > 0 ? (
                  <span className="intel-pill-badge warning">{criticalCount} Bahan Baku</span>
                ) : (
                  <span className="intel-pill-badge success">Semua Aman (0 Kritis)</span>
                )}
              </div>
              <div className="intel-row">
                <span className="intel-label">Penjualan Kasir Hari Ini</span>
                <span className="intel-val text-teal">{todaySalesFormatted}</span>
              </div>
              <div className="intel-row">
                <span className="intel-label">Transaksi Selesai</span>
                <span className="intel-val">{todayOrdersFormatted}</span>
              </div>
            </div>

            <div
              className={`intel-alert-box ${criticalCount > 0 ? 'alert-warning' : 'alert-success'}`}
            >
              {criticalCount > 0 ? (
                <>
                  <AlertTriangle size={15} className="alert-icon-warn" />
                  <span>
                    <strong>{criticalNames}</strong> berada di bawah batas minimum. Segera lakukan
                    restock.
                  </span>
                </>
              ) : (
                <>
                  <CheckCircle2 size={15} className="alert-icon-success" />
                  <span>
                    Seluruh inventaris bahan baku dalam kondisi aman dan siap operasional.
                  </span>
                </>
              )}
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
                  className="capability-item-card"
                  role="button"
                  tabIndex={0}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') handleSend(cap.prompt);
                  }}
                  title="Klik untuk langsung tanyakan ke AIsistenku"
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
        <div className="ai-main-chat-card gsap-reveal">
          {/* Quick Prompt Suggestion Bar */}
          <div className="chat-quick-suggestions">
            <span className="sugg-label">Saran Topik:</span>
            <div className="sugg-scroll">
              <button
                type="button"
                onClick={() => handleSend('stok apa yang menipis dan perlu segera di-restock?')}
                className="sugg-chip"
              >
                <PackageCheck size={13} />
                <span>Cek Stok Menipis</span>
              </button>
              <button
                type="button"
                onClick={() => handleSend('Bagaimana tren omzet dan jumlah penjualan hari ini?')}
                className="sugg-chip"
              >
                <BarChart2 size={13} />
                <span>Analisis Omzet Hari Ini</span>
              </button>
              <button
                type="button"
                onClick={() =>
                  handleSend('buatkan draf promo kopi hemat sore untuk broadcast WhatsApp')
                }
                className="sugg-chip"
              >
                <Zap size={13} />
                <span>Draf Promo WhatsApp</span>
              </button>
              <button
                type="button"
                onClick={() =>
                  handleSend('catat pengeluaran beli susu fresh milk 12 liter senilai 280000')
                }
                className="sugg-chip"
              >
                <Receipt size={13} />
                <span>Catat Beli Bahan Baku</span>
              </button>
            </div>
          </div>

          {/* Messages Stream */}
          <div className="messages-stream">
            {loading && messages.length === 0 ? (
              <div className="ai-empty-state">
                <div className="ai-empty-avatar">
                  <Loader2 size={24} className="spin text-teal" />
                </div>
                <h3 className="ai-empty-title">Menghubungkan ke AIsistenku...</h3>
                <p className="ai-empty-desc">
                  Memuat riwayat percakapan dan sinkronisasi database toko.
                </p>
              </div>
            ) : messages.length === 0 ? (
              <div className="ai-empty-state">
                <div className="ai-empty-avatar">
                  <img src="/iconAisistenku.png" alt="AIsistenku" className="ai-empty-logo" />
                </div>
                <h3 className="ai-empty-title">AIsistenku Siap Membantu Toko Anda</h3>
                <p className="ai-empty-desc">
                  Ajukan pertanyaan seputar stok bahan baku, analisis omzet harian kasir, pencatatan
                  pengeluaran, atau minta ide promosi digital.
                </p>
                <div className="ai-empty-prompts">
                  <button
                    type="button"
                    onClick={() => handleSend('stok apa yang menipis dan perlu segera di-restock?')}
                    className="empty-prompt-btn"
                  >
                    <PackageCheck size={14} className="text-teal" />
                    <span>Cek stok bahan menipis</span>
                  </button>
                  <button
                    type="button"
                    onClick={() =>
                      handleSend('Bagaimana tren omzet dan jumlah penjualan hari ini?')
                    }
                    className="empty-prompt-btn"
                  >
                    <BarChart2 size={14} className="text-teal" />
                    <span>Evaluasi omzet &amp; transaksi hari ini</span>
                  </button>
                  <button
                    type="button"
                    onClick={() =>
                      handleSend('buatkan draf promo kopi hemat sore untuk broadcast WhatsApp')
                    }
                    className="empty-prompt-btn"
                  >
                    <Sparkles size={14} className="text-teal" />
                    <span>Buat draf promosi WhatsApp</span>
                  </button>
                </div>
              </div>
            ) : (
              messages.map((msg) => {
                const isAi = msg.sender === 'ai';
                const raw = rawById.get(msg.id);
                const actionPayload = raw?.actionPayload;
                const actionStatus = raw?.actionStatus || actionPayload?.status;
                const isRestockConfirm =
                  isAi &&
                  (actionPayload?.intent === 'add_stock' ||
                    actionPayload?.intent === 'add_expense' ||
                    actionPayload?.intent === 'ADD_STOCK_AND_EXPENSE') &&
                  actionStatus === 'pending';
                const isConfirmed =
                  isAi &&
                  (actionPayload?.intent === 'add_stock' ||
                    actionPayload?.intent === 'add_expense' ||
                    actionPayload?.intent === 'ADD_STOCK_AND_EXPENSE') &&
                  actionStatus === 'confirmed';

                return (
                  <div key={msg.id} className={`message-bubble-wrap ${isAi ? 'ai' : 'user'}`}>
                    <div className={`message-avatar ${isAi ? 'ai-avatar' : 'user-avatar'}`}>
                      {isAi ? (
                        <img
                          src="/iconAisistenku.png"
                          alt="AIsistenku"
                          className="ai-msg-avatar-logo"
                        />
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
                            {actionPayload.item && (
                              <div className="ai-action-confirm-row">
                                <span>Bahan / Item</span>
                                <strong>{actionPayload.item}</strong>
                              </div>
                            )}
                            {actionPayload.quantity && (
                              <div className="ai-action-confirm-row">
                                <span>Jumlah</span>
                                <strong>
                                  {actionPayload.quantity} {actionPayload.unit || 'unit'}
                                </strong>
                              </div>
                            )}
                            {actionPayload.amount && (
                              <div className="ai-action-confirm-row">
                                <span>Estimasi Biaya</span>
                                <strong>
                                  Rp {Number(actionPayload.amount).toLocaleString('id-ID')}
                                </strong>
                              </div>
                            )}
                          </div>
                          <button
                            type="button"
                            onClick={() =>
                              onConfirmAction(actionPayload.actionId || (raw as any)?.actionId)
                            }
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
                          <span>Aksi telah berhasil dikonfirmasi dan dicatat ke sistem toko.</span>
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
                  <img src="/iconAisistenku.png" alt="AIsistenku" className="ai-msg-avatar-logo" />
                </div>
                <div className="typing-indicator-box">
                  <div className="typing-dots-cluster">
                    <span className="typing-dot"></span>
                    <span className="typing-dot"></span>
                    <span className="typing-dot"></span>
                  </div>
                  <span className="typing-text">
                    AIsistenku sedang menganalisis database toko...
                  </span>
                </div>
              </div>
            )}

            <div ref={messagesEndRef} />
          </div>

          {/* Interactive Chat Input Bar */}
          <div className="chat-input-bar">
            <div className="chat-input-wrapper">
              <MessageSquare size={16} className="input-icon-lead" />
              <input
                ref={inputRef}
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
                disabled={sending}
                className="ai-chat-input"
              />
              <span className="input-hint">Tekan ↵ Enter</span>
            </div>

            <button
              type="button"
              onClick={() => handleSend()}
              disabled={!inputText.trim() || sending}
              className="btn-send-chat"
              title="Kirim pesan ke AIsistenku"
            >
              {sending ? <Loader2 size={18} className="spin" /> : <Send size={18} />}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AiAssistantScreen;

import React from 'react';
import { X, Bell, AlertTriangle, TrendingUp, Sparkles, CheckCircle2, Clock } from 'lucide-react';
import { StockAlert } from '../../types';

interface NotificationModalProps {
  isOpen: boolean;
  onClose: () => void;
  stockAlerts: StockAlert[];
  onNavigateTab: (tab: any) => void;
}

export const NotificationModal: React.FC<NotificationModalProps> = ({
  isOpen,
  onClose,
  stockAlerts,
  onNavigateTab,
}) => {
  if (!isOpen) return null;

  const notifications = [
    ...stockAlerts.map((alert) => ({
      id: `alert-${alert.id}`,
      title: `Stok Kritis: ${alert.productName}`,
      desc: `Sisa ${alert.currentStock} ${alert.unit} (Batas minimum: ${alert.minStock} ${alert.unit}). Segera lakukan restock bahan baku.`,
      time: '10 mnt lalu',
      type: 'warning',
      icon: AlertTriangle,
      action: () => {
        onNavigateTab('stock');
        onClose();
      },
      actionLabel: 'Lihat Stok',
    })),
    {
      id: 'notif-sales',
      title: 'Target Penjualan Harian +14.2%',
      desc: 'Omzet hari ini telah melampaui rata-rata harian dengan total 32 pesanan kasir.',
      time: '1 jam lalu',
      type: 'success',
      icon: TrendingUp,
      action: () => {
        onNavigateTab('finance');
        onClose();
      },
      actionLabel: 'Buka Laporan',
    },
    {
      id: 'notif-ai',
      title: 'AIsistenku: Rekomendasi Promo Sore',
      desc: 'Waktu puncak kunjungan dimulai pukul 16:00. Siapkan 15 porsi promo bundling es kopi.',
      time: '2 jam lalu',
      type: 'ai',
      icon: Sparkles,
      action: () => {
        onNavigateTab('ai');
        onClose();
      },
      actionLabel: 'Tanya AI',
    },
    {
      id: 'notif-shift',
      title: 'Shift Pagi Berjalan Lancar',
      desc: 'Kasir Budi Santoso aktif sejak 08:00 WIB. Saldo kas awal tercatat sesuai.',
      time: '4 jam lalu',
      type: 'info',
      icon: CheckCircle2,
      action: () => {
        onClose();
      },
      actionLabel: 'Selesai',
    },
  ];

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-card" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 460 }}>
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div
              style={{
                width: 36,
                height: 36,
                borderRadius: 10,
                backgroundColor: '#111111',
                color: '#22C55E',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <Bell size={18} />
            </div>
            <div>
              <h3>Notifikasi & Peringatan</h3>
              <p style={{ fontSize: 12, color: '#64748B', marginTop: 1 }}>
                Pemberitahuan penting operasional toko hari ini
              </p>
            </div>
          </div>
          <button type="button" onClick={onClose} className="btn-close">
            <X size={18} />
          </button>
        </div>

        <div className="modal-body" style={{ display: 'flex', flexDirection: 'column', gap: 10, maxHeight: '60vh', overflowY: 'auto' }}>
          {notifications.map((item) => {
            const IconComp = item.icon;
            const isWarning = item.type === 'warning';
            const isSuccess = item.type === 'success';
            const isAi = item.type === 'ai';

            const bg = isWarning ? '#FFFBEB' : isSuccess ? '#F0FDF4' : isAi ? '#F8FAFC' : '#F1F5F9';
            const iconBg = isWarning ? '#FEF3C7' : isSuccess ? '#DCFCE7' : isAi ? '#111111' : '#E2E8F0';
            const iconColor = isWarning ? '#D97706' : isSuccess ? '#16A34A' : isAi ? '#22C55E' : '#475569';

            return (
              <div
                key={item.id}
                style={{
                  display: 'flex',
                  alignItems: 'flex-start',
                  gap: 12,
                  padding: '12px 14px',
                  borderRadius: 12,
                  backgroundColor: bg,
                  border: `1px solid ${isWarning ? '#FDE68A' : isSuccess ? '#BBF7D0' : '#E2E8F0'}`,
                }}
              >
                <div
                  style={{
                    width: 34,
                    height: 34,
                    borderRadius: 8,
                    backgroundColor: iconBg,
                    color: iconColor,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    flexShrink: 0,
                    marginTop: 2,
                  }}
                >
                  <IconComp size={18} />
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 2 }}>
                    <h5 style={{ fontSize: 13, fontWeight: 700, color: '#111111', margin: 0 }}>
                      {item.title}
                    </h5>
                    <span style={{ fontSize: 10.5, color: '#94A3B8', display: 'flex', alignItems: 'center', gap: 3 }}>
                      <Clock size={10} /> {item.time}
                    </span>
                  </div>
                  <p style={{ fontSize: 11.5, color: '#475569', margin: '2px 0 8px 0', lineHeight: 1.45 }}>
                    {item.desc}
                  </p>
                  <button
                    type="button"
                    onClick={item.action}
                    style={{
                      padding: '4px 10px',
                      borderRadius: 6,
                      border: '1px solid #CBD5E1',
                      backgroundColor: '#FFFFFF',
                      color: '#111111',
                      fontSize: 11,
                      fontWeight: 700,
                      cursor: 'pointer',
                    }}
                  >
                    {item.actionLabel}
                  </button>
                </div>
              </div>
            );
          })}
        </div>

        <div className="modal-footer">
          <button type="button" onClick={onClose} className="btn-secondary" style={{ width: '100%', justifyContent: 'center' }}>
            Tutup
          </button>
        </div>
      </div>
    </div>
  );
};

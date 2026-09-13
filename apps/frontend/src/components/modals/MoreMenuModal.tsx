import React, { useState } from 'react';
import {
  X,
  Grid,
  QrCode,
  Users,
  Percent,
  Clock,
  Printer,
  CloudSync,
  ChevronRight,
  CheckCircle2,
} from 'lucide-react';

interface MoreMenuModalProps {
  isOpen: boolean;
  onClose: () => void;
  onNavigateTab: (tab: any) => void;
}

export const MoreMenuModal: React.FC<MoreMenuModalProps> = ({
  isOpen,
  onClose,
  onNavigateTab,
}) => {
  if (!isOpen) return null;

  const [activeMessage, setActiveMessage] = useState<string | null>(null);

  const handleAction = (label: string, fallbackMsg: string, tab?: any) => {
    if (tab) {
      onNavigateTab(tab);
      onClose();
      return;
    }
    setActiveMessage(fallbackMsg);
    setTimeout(() => {
      setActiveMessage(null);
    }, 2800);
  };

  const menuSections = [
    {
      title: 'OPERASIONAL & LAYANAN MEJA',
      items: [
        {
          icon: QrCode,
          label: 'Pengaturan Meja & QR Code',
          desc: 'Kelola 12 nomor meja, cetak QR pemesanan otomatis',
          color: '#2563EB',
          bg: '#DBEAFE',
          action: () => handleAction('Meja', 'Mode pengaturan meja aktif: 12 meja dalam status siap.'),
        },
        {
          icon: Users,
          label: 'Pelanggan & Member Loyalitas',
          desc: 'Data 148 pelanggan aktif & poin reward loyalitas',
          color: '#16A34A',
          bg: '#DCFCE7',
          action: () => handleAction('Member', 'Modul pelanggan: 148 member terdaftar dan tersinkronisasi.'),
        },
      ],
    },
    {
      title: 'PROMOSI & KEUANGAN',
      items: [
        {
          icon: Percent,
          label: 'Diskon & Voucher Promo',
          desc: 'Atur potongan harga pesanan & promo bundling kopi',
          color: '#D97706',
          bg: '#FEF3C7',
          action: () => handleAction('Diskon', 'Voucher aktif: Promo "DISKON10" dan "PAKETKOPI" sedang berjalan.'),
        },
        {
          icon: Clock,
          label: 'Rekap & Tutup Shift Kasir',
          desc: 'Lihat total setoran uang kasir & cetak rekap shift',
          color: '#7C3AED',
          bg: '#EDE9FE',
          action: () => handleAction('Shift', 'Rekap Shift Pagi: 32 transaksi tercatat, kas fisik sesuai.'),
        },
      ],
    },
    {
      title: 'PERANGKAT & SINKRONISASI',
      items: [
        {
          icon: Printer,
          label: 'Printer Struk Thermal 58/80mm',
          desc: 'Status printer: Terhubung (Bluetooth / USB ESC/POS)',
          color: '#0D9488',
          bg: '#CCFBF1',
          action: () => handleAction('Printer', 'Printer thermal siap: Ukuran kertas 58mm default aktif.'),
        },
        {
          icon: CloudSync,
          label: 'Sinkronisasi Cloud & Data Lokal',
          desc: 'Server backend online • Data 100% tersinkron',
          color: '#059669',
          bg: '#D1FAE5',
          action: () => handleAction('Sync', 'Sinkronisasi berhasil: Semua data lokal telah sinkron dengan server.'),
        },
      ],
    },
  ];

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-card" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 520 }}>
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div
              style={{
                width: 36,
                height: 36,
                borderRadius: 10,
                backgroundColor: '#F1F5F9',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#111111',
              }}
            >
              <Grid size={20} />
            </div>
            <div>
              <h3>Menu Operasional Lainnya</h3>
              <p style={{ fontSize: 12, color: '#64748B', marginTop: 1 }}>Pintasan lengkap tata kelola toko dan outlet</p>
            </div>
          </div>
          <button type="button" onClick={onClose} className="btn-close">
            <X size={18} />
          </button>
        </div>

        <div className="modal-body" style={{ padding: '16px 20px' }}>
          {activeMessage && (
            <div
              style={{
                backgroundColor: '#F0FDF4',
                border: '1px solid #86EFAC',
                color: '#15803D',
                padding: '10px 14px',
                borderRadius: 10,
                fontSize: 12.5,
                fontWeight: 600,
                display: 'flex',
                alignItems: 'center',
                gap: 8,
                marginBottom: 14,
              }}
            >
              <CheckCircle2 size={16} />
              <span>{activeMessage}</span>
            </div>
          )}

          <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
            {menuSections.map((sec, sIdx) => (
              <div key={sIdx}>
                <span
                  style={{
                    fontSize: 10.5,
                    fontWeight: 800,
                    color: '#94A3B8',
                    letterSpacing: 0.6,
                    display: 'block',
                    marginBottom: 8,
                  }}
                >
                  {sec.title}
                </span>

                <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                  {sec.items.map((item, iIdx) => {
                    const IconComp = item.icon;
                    return (
                      <div
                        key={iIdx}
                        onClick={item.action}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'space-between',
                          padding: '10px 14px',
                          borderRadius: 12,
                          border: '1px solid #E2E8F0',
                          backgroundColor: '#FFFFFF',
                          cursor: 'pointer',
                          transition: 'all 0.18s ease',
                        }}
                        onMouseEnter={(e) => {
                          e.currentTarget.style.backgroundColor = '#F8FAFC';
                          e.currentTarget.style.borderColor = '#CBD5E1';
                        }}
                        onMouseLeave={(e) => {
                          e.currentTarget.style.backgroundColor = '#FFFFFF';
                          e.currentTarget.style.borderColor = '#E2E8F0';
                        }}
                      >
                        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                          <div
                            style={{
                              width: 36,
                              height: 36,
                              borderRadius: 10,
                              backgroundColor: item.bg,
                              color: item.color,
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              flexShrink: 0,
                            }}
                          >
                            <IconComp size={18} />
                          </div>
                          <div>
                            <h5 style={{ fontSize: 13, fontWeight: 700, color: '#0F172A', margin: 0 }}>
                              {item.label}
                            </h5>
                            <p style={{ fontSize: 11.5, color: '#64748B', margin: '2px 0 0 0' }}>
                              {item.desc}
                            </p>
                          </div>
                        </div>

                        <ChevronRight size={16} color="#94A3B8" />
                      </div>
                    );
                  })}
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="modal-footer">
          <button type="button" onClick={onClose} className="btn-secondary" style={{ width: '100%', justifyContent: 'center' }}>
            Tutup Menu
          </button>
        </div>
      </div>
    </div>
  );
};

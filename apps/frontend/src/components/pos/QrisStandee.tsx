import React, { useEffect, useState } from 'react';
import QRCode from 'qrcode';
import { Copy, Check, Clock, ShieldCheck } from 'lucide-react';
import './QrisStandee.css';

interface QrisStandeeProps {
  amount: number;
  orderCode?: string;
  merchantName?: string;
}

export const QrisStandee: React.FC<QrisStandeeProps> = ({
  amount,
  orderCode = 'TA-POS',
  merchantName = 'KEDAI KOPI TIGA ANGKATAN',
}) => {
  const [qrDataUrl, setQrDataUrl] = useState<string>('');
  const [copied, setCopied] = useState<boolean>(false);
  const [timeLeft, setTimeLeft] = useState<number>(300); // 5 minutes countdown

  const nmid = 'ID1024392019283';
  const terminalId = 'A01';

  // Standard Indonesian EMVCo QRIS Payload
  const qrisPayload = React.useMemo(() => {
    const formattedAmount = Math.round(amount).toString();
    return `00020101021226590014ID.LINKAJA.WWW01189360091100201928300208${nmid}51440014ID.CO.QRIS.WWW0215ID10202409138810303UME52045812530336054${formattedAmount.length
      .toString()
      .padStart(2, '0')}${formattedAmount}5802ID59${merchantName.length
      .toString()
      .padStart(2, '0')}${merchantName}6007BANDUNG61054011562070703${terminalId}6304B7A1`;
  }, [amount, merchantName]);

  useEffect(() => {
    let isMounted = true;
    QRCode.toDataURL(qrisPayload, {
      errorCorrectionLevel: 'H',
      margin: 1,
      width: 200,
      color: {
        dark: '#0F172A',
        light: '#FFFFFF',
      },
    })
      .then((url) => {
        if (isMounted) setQrDataUrl(url);
      })
      .catch((err) => {
        console.error('Failed to generate QRIS QR code:', err);
      });

    return () => {
      isMounted = false;
    };
  }, [qrisPayload]);

  // Expiry countdown timer
  useEffect(() => {
    const timer = setInterval(() => {
      setTimeLeft((prev) => (prev > 0 ? prev - 1 : 300));
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const formatTimer = (seconds: number) => {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  const copyPayload = () => {
    navigator.clipboard.writeText(qrisPayload);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="qris-standee-container">
      {/* ── Official QRIS Header Banner ── */}
      <div className="qris-header-banner">
        <div className="qris-brand-row">
          <div className="qris-logo-official">
            <span className="qris-logo-letter">Q</span>
            <span className="qris-logo-letter">R</span>
            <span className="qris-logo-letter">I</span>
            <span className="qris-logo-letter">S</span>
          </div>
          <div className="qris-tagline-col">
            <span className="qris-tagline-main">PEMBAYARAN DIGITAL</span>
            <span className="qris-tagline-sub">STANDAR NASIONAL ASPI & BANK INDONESIA</span>
          </div>
          <div className="qris-gpn-shield">
            <ShieldCheck size={14} />
            <span>GPN</span>
          </div>
        </div>
      </div>

      {/* ── Merchant Information ── */}
      <div className="qris-merchant-info">
        <h4 className="qris-merchant-name">{merchantName}</h4>
        <div className="qris-merchant-meta">
          <span>NMID: <strong>{nmid}</strong></span>
          <span className="meta-dot">•</span>
          <span>{terminalId}</span>
          <span className="meta-dot">•</span>
          <span>{orderCode}</span>
        </div>
      </div>

      {/* ── Scannable QR Code Canvas ── */}
      <div className="qris-qr-frame">
        {qrDataUrl ? (
          <div className="qris-image-wrapper">
            <img src={qrDataUrl} alt="QRIS Standar Nasional" className="qris-qr-image" />
            {/* Center GPN Emblem Badge */}
            <div className="qris-center-badge" title="Gerbang Pembayaran Nasional">
              <span className="center-gpn-text">GPN</span>
            </div>
          </div>
        ) : (
          <div className="qris-loading-box">
            <span>Membuat QRIS...</span>
          </div>
        )}

        {/* Scan instruction with pulse */}
        <div className="qris-scan-instruction">
          <span className="pulse-beacon"></span>
          <span>Scan lewat Mobile Banking atau E-Wallet apa saja</span>
        </div>
      </div>

      {/* ── Dynamic Total & Expiry Timer ── */}
      <div className="qris-nominal-box">
        <div className="qris-amount-row">
          <span className="qris-amount-label">TOTAL TAGIHAN:</span>
          <strong className="qris-amount-val">Rp {amount.toLocaleString('id-ID')}</strong>
        </div>
        <div className="qris-timer-row">
          <Clock size={12} />
          <span>Berlaku: <strong>{formatTimer(timeLeft)}</strong></span>
        </div>
      </div>

      {/* ── Supported E-Wallets and Banks Bar ── */}
      <div className="qris-partners-section">
        <div className="partners-chips-grid">
          <span className="partner-chip bank">BCA</span>
          <span className="partner-chip bank">Mandiri</span>
          <span className="partner-chip bank">BRI</span>
          <span className="partner-chip bank">BNI</span>
          <span className="partner-chip ewallet gopay">GoPay</span>
          <span className="partner-chip ewallet ovo">OVO</span>
          <span className="partner-chip ewallet dana">DANA</span>
          <span className="partner-chip ewallet shopee">ShopeePay</span>
          <span className="partner-chip ewallet linkaja">LinkAja</span>
        </div>
        <button
          type="button"
          onClick={copyPayload}
          className="btn-qris-copy-link"
          title="Salin String Payload QRIS"
        >
          {copied ? <Check size={11} className="text-emerald" /> : <Copy size={11} />}
          <span>{copied ? 'Tersalin' : 'Salin Kode QRIS'}</span>
        </button>
      </div>
    </div>
  );
};

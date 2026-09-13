import React, { useEffect, useState } from 'react';
import './SplashScreen.css';

interface SplashScreenProps {
  onFinish: () => void;
}

/**
 * Clean, authentic, and modern Splash Screen for AISISTENKU (Web).
 * 1:1 Parity with Flutter mobile implementation (apps/mobile/lib/screens/splash_screen.dart):
 * - Solid premium Obsidian Black background (#111111)
 * - Pure, unboxed brand logo with natural scaling entrance (135x135)
 * - Crisp, modern typography with subtle staggered entrance
 * - Minimalist circular loading spinner (#22C55E)
 * - Genuine ecosystem attribution: "Tiga Angkatan • Ekosistem Terpadu"
 */
export const SplashScreen: React.FC<SplashScreenProps> = ({ onFinish }) => {
  const [fadeState, setFadeState] = useState<'in' | 'out'>('in');

  useEffect(() => {
    // 2500ms duration matching Flutter mobile implementation
    const timer = setTimeout(() => {
      setFadeState('out');
      setTimeout(() => {
        onFinish();
      }, 550); // 550ms fade matching mobile transitionDuration
    }, 2500);

    return () => clearTimeout(timer);
  }, [onFinish]);

  const handleSkip = () => {
    setFadeState('out');
    setTimeout(() => {
      onFinish();
    }, 250);
  };

  return (
    <div
      className={`splash-screen-root ${fadeState}`}
      onClick={handleSkip}
      role="button"
      tabIndex={0}
      title="Klik untuk langsung masuk"
    >
      <div className="splash-spacer-top" />

      {/* ── Centered Logo & Branding ─────────────────────────── */}
      <div className="splash-center-content">
        {/* Authentic Unboxed Logo */}
        <div className="splash-logo-wrap">
          <img
            src="/logoAisitenku.png"
            alt="AISISTENKU Logo"
            className="splash-logo-img"
            onError={(e) => {
              (e.target as HTMLImageElement).src = '/iconAisistenku.png';
            }}
          />
        </div>

        {/* Staggered Typography */}
        <div className="splash-typography-group">
          <h1 className="splash-brand-title">AISISTENKU</h1>
          <p className="splash-brand-subtitle">POS &amp; Manajemen Toko Pintar</p>
        </div>
      </div>

      <div className="splash-spacer-bottom" />

      {/* ── Bottom Minimalist Spinner & Ecosystem Footer ─────── */}
      <div className="splash-footer-group">
        <div className="splash-spinner-ring" />
        <span className="splash-footer-text">Tiga Angkatan • Ekosistem Terpadu</span>
      </div>
    </div>
  );
};

export default SplashScreen;

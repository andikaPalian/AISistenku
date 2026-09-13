import React, { useEffect, useState } from 'react';
import { ShellLayout } from './components/layout/ShellLayout';
import { LoginScreen } from './screens/LoginScreen';
import { SplashScreen } from './screens/SplashScreen';
import { isAuthenticated } from './lib/auth';

export const App: React.FC = () => {
  // Always show the authentic splash screen on fresh load, mirroring Flutter mobile
  const [showSplash, setShowSplash] = useState<boolean>(true);

  // Checks whether the user has logged in during this session
  const [authed, setAuthed] = useState<boolean>(() => {
    const isSessionEntered = sessionStorage.getItem('ta_session_entered') === 'true';
    return isAuthenticated() && isSessionEntered;
  });

  useEffect(() => {
    const handler = () => {
      const isSessionEntered = sessionStorage.getItem('ta_session_entered') === 'true';
      setAuthed(isAuthenticated() && isSessionEntered);
    };

    window.addEventListener('storage', handler);
    window.addEventListener('ta:auth-change', handler);
    return () => {
      window.removeEventListener('storage', handler);
      window.removeEventListener('ta:auth-change', handler);
    };
  }, []);

  if (showSplash) {
    return <SplashScreen onFinish={() => setShowSplash(false)} />;
  }

  return authed ? <ShellLayout /> : <LoginScreen />;
};

export default App;
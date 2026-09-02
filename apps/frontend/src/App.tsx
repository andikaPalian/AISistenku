import React, { useEffect, useState } from 'react';
import { ShellLayout } from './components/layout/ShellLayout';
import { LoginScreen } from './screens/LoginScreen';
import { isAuthenticated } from './lib/auth';

export const App: React.FC = () => {
  const [authed, setAuthed] = useState<boolean>(isAuthenticated());

  useEffect(() => {
    const handler = () => setAuthed(isAuthenticated());
    window.addEventListener('storage', handler);
    window.addEventListener('ta:auth-change', handler);
    return () => {
      window.removeEventListener('storage', handler);
      window.removeEventListener('ta:auth-change', handler);
    };
  }, []);

  return authed ? <ShellLayout /> : <LoginScreen />;
};

export default App;
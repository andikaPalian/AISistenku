import React, { useEffect, useState } from 'react';
import { ShellLayout } from './components/layout/ShellLayout';
import { LoginScreen } from './screens/LoginScreen';
import { isAuthenticated } from './lib/auth';

export const App: React.FC = () => {
  const [authed, setAuthed] = useState<boolean>(isAuthenticated());

  useEffect(() => {
    const handler = () => setAuthed(isAuthenticated());
    window.addEventListener('storage', handler);
    window.addEventListener('ta-auth-changed', handler);
    return () => {
      window.removeEventListener('storage', handler);
      window.removeEventListener('ta-auth-changed', handler);
    };
  }, []);

  if (!authed) {
    return <LoginScreen />;
  }
  return <ShellLayout />;
};

export default App;

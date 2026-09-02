import React, { useEffect, useState } from 'react';
import { ShellLayout } from './components/layout/ShellLayout';
import { LoginScreen } from './screens/LoginScreen';
import { isAuthenticated } from './lib/auth';

export const App: React.FC = () => {
  const [showLogin, setShowLogin] = useState<boolean>(false);

  // Default to ShellLayout directly with rich mockup data for design testing
  return <ShellLayout />;
};

export default App;

import { useContext } from 'react';
import { AuthContext, AuthContextType } from './AuthContext.ts';

export const useAuthContext = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuthContext must be used within an AuthProvider');
  }
  return context;
};


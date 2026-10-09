import React, { createContext, useContext, useState, useEffect } from 'react';
import { api, type AuthUser } from '../services/api';

interface AuthContextType {
  user: AuthUser | null;
  token: string | null;
  isAuthenticated: boolean;
  loading: boolean;
  login: (identifier: string, pass: string) => Promise<{ success: boolean; message?: string }>;
  register: (params: { name: string; email: string; phone: string; password: string; businessName: string }) => Promise<{ success: boolean; message?: string }>;
  sendOtp: (emailOrPhone: string) => Promise<{ success: boolean; message: string; otp?: string }>;
  verifyOtp: (emailOrPhone: string, otp: string) => Promise<{ success: boolean; message: string }>;
  forgotPassword: (emailOrPhone: string) => Promise<{ success: boolean; message: string }>;
  verifyResetOtp: (emailOrPhone: string, otp: string) => Promise<{ success: boolean; resetToken?: string; message: string }>;
  resetPassword: (params: { emailOrPhone: string; otp?: string; resetToken?: string; newPassword: string }) => Promise<{ success: boolean; message: string }>;
  logout: () => void;
  updateUser: (updated: Partial<AuthUser>) => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const initializeAuth = async () => {
      try {
        const storedToken = localStorage.getItem('enx_token');
        const storedUser = localStorage.getItem('enx_user');
        if (storedToken && storedUser) {
          setToken(storedToken);
          setUser(JSON.parse(storedUser));
        }
      } catch (err) {
        console.error('Failed to restore auth session:', err);
      } finally {
        setLoading(false);
      }
    };
    initializeAuth();
  }, []);

  const login = async (identifier: string, pass: string) => {
    setLoading(true);
    try {
      const res = await api.login(identifier, pass);
      if (res.success && res.user) {
        setUser(res.user);
        setToken(res.token || 'token_' + Date.now());
        return { success: true };
      }
      return { success: false, message: res.message || 'Login failed' };
    } finally {
      setLoading(false);
    }
  };

  const register = async (params: { name: string; email: string; phone: string; password: string; businessName: string }) => {
    setLoading(true);
    try {
      const res = await api.register(params);
      if (res.success && res.user) {
        setUser(res.user);
        setToken(res.token || 'token_' + Date.now());
        return { success: true };
      }
      return { success: false, message: res.message || 'Registration failed' };
    } finally {
      setLoading(false);
    }
  };

  const sendOtp = async (emailOrPhone: string) => {
    return await api.sendOtp(emailOrPhone);
  };

  const verifyOtp = async (emailOrPhone: string, otp: string) => {
    return await api.verifyOtp(emailOrPhone, otp);
  };

  const forgotPassword = async (emailOrPhone: string) => {
    return await api.forgotPassword(emailOrPhone);
  };

  const verifyResetOtp = async (emailOrPhone: string, otp: string) => {
    return await api.verifyResetOtp(emailOrPhone, otp);
  };

  const resetPassword = async (params: { emailOrPhone: string; otp?: string; resetToken?: string; newPassword: string }) => {
    return await api.resetPassword(params);
  };

  const logout = () => {
    api.logout();
    setUser(null);
    setToken(null);
  };

  const updateUser = (updated: Partial<AuthUser>) => {
    if (!user) return;
    const merged = { ...user, ...updated };
    setUser(merged);
    localStorage.setItem('enx_user', JSON.stringify(merged));
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        isAuthenticated: !!token && !!user,
        loading,
        login,
        register,
        sendOtp,
        verifyOtp,
        forgotPassword,
        verifyResetOtp,
        resetPassword,
        logout,
        updateUser,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

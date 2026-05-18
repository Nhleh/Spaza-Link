import React from 'react';
import { BrowserRouter, Routes, Route, useLocation } from 'react-router-dom';
import { AnimatePresence, motion } from 'motion/react';
import { AuthProvider } from './context/AuthContext';
import { NotificationProvider } from './context/NotificationContext';
import { CartProvider } from './context/CartContext';
import { BottomNav } from './components/BottomNav';
import { ProtectedRoute } from './components/ProtectedRoute';
import { ThemeProvider } from './context/ThemeContext';

// Screens
import { SplashScreen } from './screens/SplashScreen';
import { LoginScreen } from './screens/LoginScreen';
import { RegisterScreen } from './screens/RegisterScreen';
import { HomeDashboard } from './screens/HomeDashboard';
import { ProductCatalog } from './screens/ProductCatalog';
import { CartScreen } from './screens/CartScreen';
import { CheckoutScreen } from './screens/CheckoutScreen';
import { OrderTrackingScreen } from './screens/OrderTrackingScreen';
import { OrderHistoryScreen } from './screens/OrderHistoryScreen';
import { NotificationsScreen } from './screens/NotificationsScreen';
import { ProfileScreen } from './screens/ProfileScreen';
import { SupportScreen } from './screens/SupportScreen';
import { SettingsScreen } from './screens/SettingsScreen';
import { OrderSuccessScreen } from './screens/OrderSuccessScreen';
import { ForgotPasswordScreen } from './screens/ForgotPasswordScreen';
import { TermsScreen } from './screens/TermsScreen';
import { PrivacyPolicyScreen } from './screens/PrivacyPolicyScreen';

import { AdminDashboard } from './screens/AdminDashboard';

const PageWrapper: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.98 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 1.02 }}
      transition={{ duration: 0.15, ease: "easeOut" }}
      className="w-full flex-1 flex flex-col overflow-x-hidden"
    >
      {children}
    </motion.div>
  );
};

const AppRoutes = () => {
  const location = useLocation();
  const hideNav = ['/', '/splash', '/login', '/register', '/forgot-password', '/order-success'].includes(location.pathname);

  return (
    <div className="w-full min-h-[100dvh] bg-spaza-bg relative flex flex-col">
      <AnimatePresence mode="wait">
        <Routes location={location}>
          <Route path="/" element={<PageWrapper><SplashScreen /></PageWrapper>} />
          <Route path="/home" element={<PageWrapper><ProtectedRoute><HomeDashboard /></ProtectedRoute></PageWrapper>} />
          <Route path="/login" element={<PageWrapper><LoginScreen /></PageWrapper>} />
          <Route path="/forgot-password" element={<PageWrapper><ForgotPasswordScreen /></PageWrapper>} />
          <Route path="/register" element={<PageWrapper><RegisterScreen /></PageWrapper>} />
          <Route path="/catalog" element={<PageWrapper><ProtectedRoute><ProductCatalog /></ProtectedRoute></PageWrapper>} />
          <Route path="/cart" element={<PageWrapper><ProtectedRoute><CartScreen /></ProtectedRoute></PageWrapper>} />
          <Route path="/checkout" element={<PageWrapper><ProtectedRoute><CheckoutScreen /></ProtectedRoute></PageWrapper>} />
          <Route path="/order-tracking" element={<PageWrapper><ProtectedRoute><OrderTrackingScreen /></ProtectedRoute></PageWrapper>} />
          <Route path="/orders-history" element={<PageWrapper><ProtectedRoute><OrderHistoryScreen /></ProtectedRoute></PageWrapper>} />
          <Route path="/notifications" element={<PageWrapper><ProtectedRoute><NotificationsScreen /></ProtectedRoute></PageWrapper>} />
          <Route path="/profile" element={<PageWrapper><ProtectedRoute><ProfileScreen /></ProtectedRoute></PageWrapper>} />
          <Route path="/support" element={<PageWrapper><ProtectedRoute><SupportScreen /></ProtectedRoute></PageWrapper>} />
          <Route path="/settings" element={<PageWrapper><ProtectedRoute><SettingsScreen /></ProtectedRoute></PageWrapper>} />
          <Route path="/terms" element={<PageWrapper><TermsScreen /></PageWrapper>} />
          <Route path="/privacy-policy" element={<PageWrapper><PrivacyPolicyScreen /></PageWrapper>} />
          <Route path="/order-success" element={<PageWrapper><ProtectedRoute><OrderSuccessScreen /></ProtectedRoute></PageWrapper>} />
          <Route path="/admin" element={<PageWrapper><ProtectedRoute requireAdmin><AdminDashboard /></ProtectedRoute></PageWrapper>} />
        </Routes>
      </AnimatePresence>
      {!hideNav && <BottomNav />}
    </div>
  );
};

export default function App() {
  return (
    <ThemeProvider>
      <AuthProvider>
        <NotificationProvider>
          <CartProvider>
            <BrowserRouter>
              <AppRoutes />
            </BrowserRouter>
          </CartProvider>
        </NotificationProvider>
      </AuthProvider>
    </ThemeProvider>
  );
}

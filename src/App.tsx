import React from 'react';
import { BrowserRouter, Routes, Route, useLocation } from 'react-router-dom';
import { AnimatePresence, motion } from 'motion/react';
import { AuthProvider } from './context/AuthContext';
import { CartProvider } from './context/CartContext';
import { BottomNav } from './components/BottomNav';

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

const PageWrapper: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.98 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 1.02 }}
      transition={{ duration: 0.15, ease: "easeOut" }}
      className="w-full h-full"
    >
      {children}
    </motion.div>
  );
};

const AppRoutes = () => {
  const location = useLocation();
  const hideNav = ['/', '/splash', '/login', '/register', '/checkout', '/order-tracking'].includes(location.pathname);

  return (
    <div className="max-w-md mx-auto bg-white min-h-screen shadow-2xl relative overflow-hidden flex flex-col">
      <AnimatePresence>
        <Routes location={location}>
          <Route path="/" element={<PageWrapper><SplashScreen /></PageWrapper>} />
          <Route path="/home" element={<PageWrapper><HomeDashboard /></PageWrapper>} />
          <Route path="/login" element={<PageWrapper><LoginScreen /></PageWrapper>} />
          <Route path="/forgot-password" element={<PageWrapper><ForgotPasswordScreen /></PageWrapper>} />
          <Route path="/register" element={<PageWrapper><RegisterScreen /></PageWrapper>} />
          <Route path="/catalog" element={<PageWrapper><ProductCatalog /></PageWrapper>} />
          <Route path="/cart" element={<PageWrapper><CartScreen /></PageWrapper>} />
          <Route path="/checkout" element={<PageWrapper><CheckoutScreen /></PageWrapper>} />
          <Route path="/order-tracking" element={<PageWrapper><OrderTrackingScreen /></PageWrapper>} />
          <Route path="/orders-history" element={<PageWrapper><OrderHistoryScreen /></PageWrapper>} />
          <Route path="/notifications" element={<PageWrapper><NotificationsScreen /></PageWrapper>} />
          <Route path="/profile" element={<PageWrapper><ProfileScreen /></PageWrapper>} />
          <Route path="/support" element={<PageWrapper><SupportScreen /></PageWrapper>} />
          <Route path="/settings" element={<PageWrapper><SettingsScreen /></PageWrapper>} />
          <Route path="/terms" element={<PageWrapper><TermsScreen /></PageWrapper>} />
          <Route path="/privacy-policy" element={<PageWrapper><PrivacyPolicyScreen /></PageWrapper>} />
          <Route path="/order-success" element={<PageWrapper><OrderSuccessScreen /></PageWrapper>} />
        </Routes>
      </AnimatePresence>
      {!hideNav && <BottomNav />}
    </div>
  );
};

import { ThemeProvider } from './context/ThemeContext';

export default function App() {
  return (
    <ThemeProvider>
      <AuthProvider>
        <CartProvider>
          <BrowserRouter>
            <AppRoutes />
          </BrowserRouter>
        </CartProvider>
      </AuthProvider>
    </ThemeProvider>
  );
}

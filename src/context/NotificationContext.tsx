import React, { createContext, useContext, useEffect, useState } from 'react';
import { useAuth } from './AuthContext';
import { notificationService } from '../services/notificationService';
import { Bell, X } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';

interface NotificationContextType {
  token: string | null;
  permission: NotificationPermission;
  requestPermission: () => Promise<void>;
}

const NotificationContext = createContext<NotificationContextType>({
  token: null,
  permission: 'default',
  requestPermission: async () => {},
});

export const useNotifications = () => useContext(NotificationContext);

export const NotificationProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { user } = useAuth();
  const [token, setToken] = useState<string | null>(null);
  const [permission, setPermission] = useState<NotificationPermission>(Notification.permission);
  const [showToast, setShowToast] = useState<{ title: string; body: string } | null>(null);

  useEffect(() => {
    if (user) {
      // Refresh token if permission is already granted
      if (Notification.permission === 'granted') {
        notificationService.saveToken().then(setToken);
      }

      // Listen for foreground messages
      const unsubscribe = notificationService.onForegroundMessage((payload) => {
        setShowToast({
          title: payload.notification?.title || 'New Notification',
          body: payload.notification?.body || 'You have a message',
        });
        
        // Auto hide after 5 seconds
        setTimeout(() => setShowToast(null), 5000);
      });

      return () => unsubscribe();
    }
  }, [user]);

  const requestPermission = async () => {
    const newToken = await notificationService.requestPermission();
    setPermission(Notification.permission);
    if (newToken) setToken(newToken);
  };

  return (
    <NotificationContext.Provider value={{ token, permission, requestPermission }}>
      {children}
      <AnimatePresence>
        {showToast && (
          <motion.div
            initial={{ opacity: 0, y: -50 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -50 }}
            className="fixed top-6 left-4 right-4 z-50 pointer-events-none flex justify-center"
          >
            <div className="bg-white rounded-2xl shadow-premium border border-border-custom p-4 max-w-md w-full pointer-events-auto flex gap-4 items-start animate-bounce-subtle">
              <div className="w-10 h-10 bg-spaza-yellow/10 rounded-full flex items-center justify-center text-spaza-yellow shrink-0">
                <Bell size={20} />
              </div>
              <div className="flex-1 min-w-0">
                <h4 className="text-sm font-bold text-text-primary truncate">{showToast.title}</h4>
                <p className="text-xs text-text-secondary line-clamp-2">{showToast.body}</p>
              </div>
              <button 
                onClick={() => setShowToast(null)}
                className="p-1 hover:bg-spaza-bg rounded-lg text-text-secondary transition-colors"
              >
                <X size={16} />
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </NotificationContext.Provider>
  );
};

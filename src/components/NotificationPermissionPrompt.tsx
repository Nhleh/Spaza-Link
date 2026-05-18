import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Bell, X, ShieldCheck } from 'lucide-react';
import { useNotifications } from '../context/NotificationContext';

export const NotificationPermissionPrompt: React.FC = () => {
  const { permission, requestPermission } = useNotifications();
  const [isVisible, setIsVisible] = useState(permission === 'default');

  if (!isVisible || permission !== 'default') return null;

  return (
    <AnimatePresence>
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0, y: 20 }}
        className="px-6 mb-6 pt-2"
      >
        <div className="bg-white rounded-[32px] p-6 shadow-premium border border-border-custom relative overflow-hidden group">
          {/* Background Decorative Element */}
          <div className="absolute -top-10 -right-10 w-32 h-32 bg-spaza-yellow/5 rounded-full blur-2xl group-hover:bg-spaza-yellow/10 transition-colors" />
          
          <div className="flex items-start gap-4 relative z-10">
            <div className="w-12 h-12 bg-spaza-green/10 rounded-2xl flex items-center justify-center text-spaza-green shrink-0">
              <Bell size={24} />
            </div>
            <div className="flex-1">
              <h3 className="text-sm font-bold text-text-primary uppercase tracking-tight">Stay Updated!</h3>
              <p className="text-xs text-text-secondary mt-1 leading-relaxed">
                Allow notifications to get real-time updates on your orders, delivery tracking, and exclusive bulk deals.
              </p>
            </div>
            <button 
              onClick={() => setIsVisible(false)}
              className="p-1 hover:bg-spaza-bg rounded-lg text-text-secondary transition-colors"
            >
              <X size={18} />
            </button>
          </div>

          <div className="mt-6 flex items-center gap-3">
            <button
              onClick={() => requestPermission()}
              className="flex-1 bg-spaza-green text-white font-black py-3 rounded-2xl text-xs uppercase tracking-widest shadow-md active:scale-95 transition-all"
            >
              Enable Notifications
            </button>
            <div className="flex items-center gap-1.5 px-3 py-3 text-[10px] font-bold text-text-secondary">
              <ShieldCheck size={14} className="text-spaza-green" />
              Secure
            </div>
          </div>
        </div>
      </motion.div>
    </AnimatePresence>
  );
};

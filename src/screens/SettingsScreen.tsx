import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, Bell, Lock, Globe, Moon, Shield, ChevronRight, CheckCircle } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { cn } from '../lib/utils';
import { useTheme } from '../context/ThemeContext';

export const SettingsScreen: React.FC = () => {
  const navigate = useNavigate();
  const { theme, toggleTheme } = useTheme();
  const [toast, setToast] = useState<string | null>(null);
  const [settings, setSettings] = useState({
    notifications: true,
    orderUpdates: true,
    promotions: false,
    inventoryAlerts: true,
    faceId: true,
  });

  const showToast = (message: string) => {
    setToast(message);
    setTimeout(() => setToast(null), 2000);
  };

  const toggleSetting = (key: keyof typeof settings) => {
    setSettings(prev => ({ ...prev, [key]: !prev[key] }));
    showToast('Setting updated');
  };

  const menuItems = [
    { icon: Globe, label: 'Language', value: 'English', onClick: () => showToast('Only English supported') },
    { icon: Lock, label: 'Privacy Policy', onClick: () => navigate('/privacy-policy') },
    { icon: Shield, label: 'Terms of Service', onClick: () => navigate('/terms') },
  ];

  return (
    <div className="min-h-[100dvh] bg-spaza-bg flex flex-col pt-0">
      {/* Toast Notification */}
      <AnimatePresence>
        {toast && (
          <motion.div
            initial={{ opacity: 0, y: -50 }}
            animate={{ opacity: 1, y: 20 }}
            exit={{ opacity: 0, y: -50 }}
            className="fixed top-0 left-0 right-0 z-50 flex justify-center px-6"
          >
            <div className="px-6 py-3 bg-white border border-spaza-green/20 rounded-2xl shadow-xl flex items-center gap-3">
              <CheckCircle size={18} className="text-spaza-green" />
              <span className="text-xs font-black uppercase tracking-wider text-gray-800">{toast}</span>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      <header className="px-6 pt-[env(safe-area-inset-top,2rem)] flex items-center mb-8 gap-4">
        <button 
          onClick={() => navigate(-1)} 
          className="w-10 h-10 bg-card-bg rounded-xl shadow-sm border border-border-custom flex items-center justify-center active:scale-95 transition-transform"
        >
          <ArrowLeft size={20} className="text-spaza-green" />
        </button>
        <h2 className="text-xl font-bold text-text-primary">Settings</h2>
      </header>

      <div className="px-6 space-y-8 pb-32">
        {/* Notifications */}
        <section className="space-y-4">
          <h3 className="text-xs font-bold text-text-secondary uppercase tracking-widest px-1 opacity-40">Notifications</h3>
          <div className="bg-card-bg rounded-3xl border border-border-custom shadow-premium overflow-hidden border-border-custom">
            <ToggleItem 
              icon={Bell} 
              label="Master Push Notifications" 
              active={settings.notifications} 
              onToggle={() => toggleSetting('notifications')} 
            />
            <AnimatePresence>
              {settings.notifications && (
                <motion.div
                  initial={{ height: 0, opacity: 0 }}
                  animate={{ height: 'auto', opacity: 1 }}
                  exit={{ height: 0, opacity: 0 }}
                  className="overflow-hidden bg-spaza-bg"
                >
                  <ToggleItem 
                    icon={Bell} 
                    label="Order Updates" 
                    active={settings.orderUpdates} 
                    onToggle={() => toggleSetting('orderUpdates')} 
                    small
                  />
                  <ToggleItem 
                    icon={Bell} 
                    label="Promotions & Deals" 
                    active={settings.promotions} 
                    onToggle={() => toggleSetting('promotions')} 
                    small
                  />
                  <ToggleItem 
                    icon={Bell} 
                    label="Inventory Alerts" 
                    active={settings.inventoryAlerts} 
                    onToggle={() => toggleSetting('inventoryAlerts')} 
                    small
                    isLast
                  />
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        </section>

        {/* Preferences */}
        <section className="space-y-4">
          <h3 className="text-xs font-bold text-text-secondary uppercase tracking-widest px-1 opacity-40">APP Preferences</h3>
          <div className="bg-card-bg rounded-3xl border border-border-custom shadow-premium overflow-hidden">
            <ToggleItem 
              icon={Moon} 
              label="Dark Mode" 
              active={theme === 'dark'} 
              onToggle={toggleTheme} 
            />
            <ToggleItem 
              icon={Lock} 
              label="Face ID / Biometrics" 
              active={settings.faceId} 
              onToggle={() => toggleSetting('faceId')} 
              isLast
            />
          </div>
        </section>

        {/* General */}
        <section className="space-y-4">
          <h3 className="text-xs font-bold text-text-secondary uppercase tracking-widest px-1 opacity-40">Legal & Support</h3>
          <div className="bg-card-bg rounded-3xl border border-border-custom shadow-premium overflow-hidden">
            {menuItems.map((item, idx) => (
              <button 
                key={item.label}
                onClick={item.onClick}
                className={cn(
                  "w-full flex items-center justify-between p-5 active:bg-spaza-bg transition-colors",
                  idx !== menuItems.length - 1 && "border-b border-border-custom"
                )}
              >
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 bg-spaza-bg rounded-xl flex items-center justify-center text-text-secondary">
                    <item.icon size={20} />
                  </div>
                  <span className="text-sm font-bold text-text-primary">{item.label}</span>
                </div>
                <div className="flex items-center gap-2">
                  {item.value && <span className="text-[11px] font-bold text-text-secondary">{item.value}</span>}
                  <ChevronRight size={18} className="text-text-secondary" />
                </div>
              </button>
            ))}
          </div>
        </section>

        <p className="text-center text-[10px] text-gray-300 font-medium pt-8">
          App Version 1.0.4 (BETA)
        </p>
      </div>
    </div>
  );
};

interface ToggleItemProps {
  icon: any;
  label: string;
  active: boolean;
  onToggle: () => void;
  isLast?: boolean;
  small?: boolean;
}

const ToggleItem: React.FC<ToggleItemProps> = ({ icon: Icon, label, active, onToggle, isLast, small }) => (
  <div className={cn(
    "flex items-center justify-between transition-all",
    small ? "p-4 pl-12" : "p-5",
    !isLast && "border-b border-border-custom"
  )}>
    <div className="flex items-center gap-4">
      {!small && (
        <div className="w-10 h-10 bg-spaza-bg rounded-xl flex items-center justify-center text-text-secondary">
          <Icon size={20} />
        </div>
      )}
      <span className={cn(
        "font-bold text-text-primary",
        small ? "text-xs" : "text-sm"
      )}>{label}</span>
    </div>
    <button 
      onClick={onToggle}
      className={cn(
        "rounded-full transition-all relative outline-none",
        small ? "w-10 h-5" : "w-12 h-6",
        active ? "bg-spaza-green" : "bg-text-secondary/20"
      )}
    >
      <div className={cn(
        "absolute top-0.5 bg-white rounded-full shadow-sm transition-all",
        small ? "w-4 h-4" : "w-5 h-5",
        active 
          ? (small ? "left-5.5" : "left-6.5") 
          : "left-1"
      )} />
    </button>
  </div>
);

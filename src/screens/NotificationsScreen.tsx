import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, Bell, ShoppingBag, Tag, CreditCard, Calendar, Loader2 } from 'lucide-react';
import { firebaseService } from '../services/firebaseService';
import { auth, db } from '../lib/firebase';
import { query, collection, where, onSnapshot, orderBy, writeBatch, doc } from 'firebase/firestore';
import { cn } from '../lib/utils';

export const NotificationsScreen: React.FC = () => {
  const navigate = useNavigate();
  const [notifications, setNotifications] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!auth.currentUser) return;

    const q = query(
      collection(db, 'notifications'),
      where('userId', '==', auth.currentUser.uid),
      orderBy('createdAt', 'desc')
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const msgs = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setNotifications(msgs);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const markAllAsRead = async () => {
    if (!auth.currentUser) return;
    
    const unread = notifications.filter(n => !n.isRead);
    if (unread.length === 0) return;

    try {
      const batch = writeBatch(db);
      unread.forEach(n => {
        const ref = doc(db, 'notifications', n.id);
        batch.update(ref, { isRead: true });
      });
      await batch.commit();
    } catch (error) {
      console.error('Error marking all as read:', error);
    }
  };

  const markAsRead = async (id: string) => {
    try {
      await firebaseService.updateDoc('notifications', id, { isRead: true });
    } catch (error) {
      console.error('Error marking as read:', error);
    }
  };

  const getIcon = (type: string) => {
    switch (type) {
      case 'order': return { icon: ShoppingBag, color: 'text-blue-500', bg: 'bg-blue-500/10' };
      case 'promo': return { icon: Tag, color: 'text-orange-500', bg: 'bg-orange-500/10' };
      case 'delivery': return { icon: ShoppingBag, color: 'text-spaza-green', bg: 'bg-spaza-green/10' };
      case 'payment': return { icon: CreditCard, color: 'text-purple-500', bg: 'bg-purple-500/10' };
      default: return { icon: Bell, color: 'text-text-secondary', bg: 'bg-text-secondary/10' };
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-spaza-bg flex items-center justify-center">
        <Loader2 className="animate-spin text-spaza-green" size={32} />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-spaza-bg flex flex-col pt-4 safe-area-top">
      <header className="px-6 flex items-center justify-between mb-8 mt-2">
        <div className="flex items-center gap-4">
            <button onClick={() => navigate(-1)} className="p-2 bg-card-bg rounded-lg shadow-sm border border-border-custom">
                <ArrowLeft size={20} className="text-spaza-green" />
            </button>
            <h2 className="text-xl font-bold text-text-primary">Notifications</h2>
        </div>
        <div className="relative">
            <Bell size={20} className="text-text-secondary" />
            {notifications.some(n => !n.isRead) && (
              <span className="absolute -top-1 -right-1 w-2 h-2 bg-red-500 rounded-full" />
            )}
        </div>
      </header>

      <div className="px-6 space-y-4 pb-24 flex-1">
        {notifications.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 text-gray-400">
            <Bell size={48} className="mb-4 opacity-20" />
            <p className="text-sm font-medium">No notifications yet</p>
          </div>
        ) : (
          notifications.map((n) => {
            const { icon: Icon, color, bg } = getIcon(n.type);
            return (
              <div 
                key={n.id} 
                onClick={() => !n.isRead && markAsRead(n.id)}
                className={cn(
                  "p-4 rounded-2xl border transition-all flex items-start gap-4 cursor-pointer",
                  n.isRead ? "bg-card-bg border-border-custom shadow-sm" : "bg-card-bg border-spaza-green/30 shadow-md ring-1 ring-spaza-green/10"
                )}
              >
                  <div className={cn("p-3 rounded-xl", bg, color)}>
                      <Icon size={20} />
                  </div>
                  <div className="flex-1">
                      <div className="flex justify-between items-start">
                        <h4 className={cn("text-xs leading-snug", n.isRead ? "font-medium text-text-secondary" : "font-bold text-text-primary")}>
                          {n.message || n.title}
                        </h4>
                        {!n.isRead && <div className="w-1.5 h-1.5 bg-spaza-green rounded-full shrink-0 mt-1" />}
                      </div>
                      <p className="text-[10px] text-text-secondary font-medium mt-1">
                        {n.createdAt && new Date(n.createdAt).toLocaleString()}
                      </p>
                  </div>
              </div>
            );
          })
        )}
      </div>

      {notifications.some(n => !n.isRead) && (
        <div className="p-6 bg-card-bg border-t border-border-custom">
          <button 
            onClick={markAllAsRead}
            className="w-full bg-spaza-green text-white font-bold py-4 rounded-xl shadow-lg active:scale-95 transition-all"
          >
              Mark all as read
          </button>
        </div>
      )}
    </div>
  );
};

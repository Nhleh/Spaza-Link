import React from 'react';
import { NavLink } from 'react-router-dom';
import { Home, ClipboardList, ShoppingCart, MessageSquare, User } from 'lucide-react';
import { cn } from '../lib/utils';
import { useCart } from '../context/CartContext';

export const BottomNav: React.FC = () => {
  const { totalItems } = useCart();

  const navItems = [
    { icon: Home, label: 'Home', path: '/home' },
    { icon: ClipboardList, label: 'Orders', path: '/orders-history' },
    { icon: ShoppingCart, label: 'Cart', path: '/cart', badge: totalItems },
    { icon: MessageSquare, label: 'Alerts', path: '/notifications' },
    { icon: User, label: 'Profile', path: '/profile' },
  ];

  return (
    <nav className="fixed bottom-0 left-0 right-0 bg-card-bg px-2 py-3 flex justify-around items-center safe-area-bottom z-50 border-t border-border-custom shadow-[0_-4px_20px_rgba(0,0,0,0.05)]">
      {navItems.map((item) => (
        <NavLink
          key={item.path}
          to={item.path}
          className={({ isActive }) =>
            cn(
              "flex flex-col items-center justify-center space-y-1 relative px-2 py-1 transition-all active:scale-95",
              isActive ? "text-spaza-green" : "text-text-secondary"
            )
          }
        >
          {({ isActive }) => (
            <>
              <div className="relative">
                <item.icon size={24} strokeWidth={isActive ? 2.5 : 2} />
                {item.badge !== undefined && item.badge > 0 && (
                  <span className="absolute -top-1 -right-2 bg-spaza-yellow text-spaza-green text-[10px] font-bold w-4 h-4 flex items-center justify-center rounded-full border border-card-bg">
                    {item.badge}
                  </span>
                )}
              </div>
              <span className={cn(
                "text-[10px] font-medium tracking-tight",
                isActive ? "text-spaza-green" : "text-text-secondary"
              )}>
                {item.label}
              </span>
            </>
          )}
        </NavLink>
      ))}
    </nav>
  );
};


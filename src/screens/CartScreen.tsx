import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Trash2, Plus, Minus, ArrowLeft, ShoppingCart } from 'lucide-react';
import { useCart } from '../context/CartContext';
import { motion } from 'motion/react';
import { cn } from '../lib/utils';

export const CartScreen: React.FC = () => {
  const navigate = useNavigate();
  const { items, updateQuantity, clearCart, totalPrice, totalItems } = useCart();

  const totalSavings = items.reduce((sum, item) => {
    // Mock savings calculation
    return sum + (item.price * 0.1 * item.quantity);
  }, 0);

  const deliveryFee = totalPrice >= 1500 ? 0 : 125;
  const finalTotal = totalPrice + deliveryFee;

  if (items.length === 0) {
    return (
      <div className="min-h-screen bg-spaza-bg flex flex-col items-center justify-center px-8 text-center pb-32">
        <div className="w-24 h-24 mb-8 text-text-secondary opacity-20">
             <ShoppingCart size={96} strokeWidth={1} />
        </div>
        <h2 className="text-xl font-bold text-text-primary mb-2">Your cart is empty</h2>
        <p className="text-sm text-text-secondary font-medium leading-relaxed mb-10 max-w-[240px]">
          Looks like you haven't added anything to your cart yet.
        </p>
        <button 
          onClick={() => navigate('/catalog')}
          className="bg-spaza-green text-white px-12 py-4.5 rounded-xl font-bold shadow-lg shadow-spaza-green/20 active:scale-95 transition-transform"
        >
          Shop Now
        </button>
      </div>
    );
  }

  return (
    <div className="min-h-[100dvh] bg-spaza-bg flex flex-col">
      <header className="bg-spaza-green pt-[env(safe-area-inset-top,2rem)] pb-6 px-6 flex justify-between items-center shadow-lg shadow-black/5">
        <div className="flex items-center gap-4">
            <button 
              onClick={() => navigate(-1)} 
              className="w-10 h-10 bg-white/10 rounded-xl flex items-center justify-center active:scale-95 transition-transform"
            >
                <ArrowLeft size={20} className="text-white" />
            </button>
            <h2 className="text-lg font-bold text-white">My Cart</h2>
        </div>
        <button 
          onClick={clearCart} 
          className="w-10 h-10 bg-white/10 rounded-xl flex items-center justify-center text-white/60 hover:text-white transition-colors"
        >
            <Trash2 size={20} />
        </button>
      </header>

      <div className="px-6 pt-8 space-y-4 mb-20 flex-1 overflow-y-auto">
        <div className="flex justify-between items-center mb-2 px-1">
            <span className="text-xs font-bold text-text-secondary uppercase tracking-widest">{totalItems} Items</span>
        </div>

        {items.map((item) => (
            <div 
               key={item.id} 
               className="bg-card-bg p-4 rounded-[24px] shadow-premium flex flex-col gap-4 border border-border-custom"
            >
                <div className="flex items-center gap-4">
                    <div className="w-16 h-16 bg-spaza-bg rounded-2xl p-2 flex items-center justify-center shrink-0 border border-border-custom">
                        <img src={item.img} alt={item.name} className="w-full h-full object-contain" />
                    </div>
                    <div className="flex-1 min-w-0">
                        <h4 className="text-[14px] font-bold text-text-primary leading-tight truncate">{item.name}</h4>
                        <p className="text-[11px] text-text-secondary font-medium mb-2">{item.unit}</p>
                        
                        <div className="flex justify-between items-center">
                            <span className="text-sm font-bold text-text-primary">R{item.price.toFixed(2)}</span>
                            
                            <div className="flex items-center bg-spaza-bg rounded-lg p-1 gap-3 border border-border-custom">
                                <button 
                                    onClick={() => updateQuantity(item.id, -1)}
                                    className="w-7 h-7 flex items-center justify-center text-text-secondary hover:text-red-500"
                                >
                                    <Minus size={16} strokeWidth={3} />
                                </button>
                                <span className="text-xs font-bold text-text-primary w-4 text-center">{item.quantity}</span>
                                <button 
                                    onClick={() => updateQuantity(item.id, 1)}
                                    className="w-7 h-7 flex items-center justify-center text-text-secondary active:text-spaza-green"
                                >
                                    <Plus size={16} strokeWidth={3} />
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
                <div className="flex justify-end pt-2 border-t border-border-custom">
                    <span className="text-sm font-bold text-spaza-green">R{(item.price * item.quantity).toFixed(2)}</span>
                </div>
            </div>
        ))}
      </div>

      {/* Summary Section */}
      <div className="bg-card-bg rounded-t-[40px] p-8 shadow-[0_-20px_40px_-20px_rgba(0,0,0,0.1)] border-t border-border-custom pb-32">
        <div className="space-y-4 mb-8">
            <div className="flex justify-between items-center text-sm">
                <span className="text-text-secondary font-medium tracking-tight">Subtotal</span>
                <span className="text-text-primary font-bold tracking-tight">R{totalPrice.toFixed(2)}</span>
            </div>
            <div className="flex justify-between items-center text-sm">
                <span className="text-text-secondary font-medium tracking-tight">Delivery</span>
                <span className={cn(
                    "font-bold tracking-tight",
                    deliveryFee === 0 ? "text-spaza-green" : "text-text-primary"
                )}>
                    {deliveryFee === 0 ? "INCLUDED" : `R${deliveryFee.toFixed(2)}`}
                </span>
            </div>
            <div className="h-px bg-border-custom my-2" />
            <div className="flex justify-between items-center">
                <span className="text-[17px] text-text-primary font-bold tracking-tight">Total Payment</span>
                <span className="text-2xl text-text-primary font-bold tracking-tighter">R{finalTotal.toFixed(2)}</span>
            </div>
            
            {/* Group Savings Highlight */}
            <div className="flex justify-between items-center bg-spaza-green/5 px-4 py-3 rounded-2xl border border-spaza-green/10">
                <div className="flex flex-col">
                  <span className="text-[11px] font-bold text-spaza-green uppercase tracking-widest">Group Savings</span>
                  <span className="text-[10px] text-spaza-green/60 font-medium mt-0.5">Applied on bulk orders</span>
                </div>
                <span className="text-lg font-bold text-spaza-green tracking-tight">R{totalSavings.toFixed(2)}</span>
            </div>
        </div>

        <button 
          onClick={() => navigate('/checkout')}
          className="w-full bg-spaza-green-dark hover:bg-green-900 text-white font-bold py-4.5 rounded-xl shadow-xl shadow-black/20 transition-all active:scale-95"
        >
          Proceed to Checkout
        </button>
      </div>
    </div>
  );
};

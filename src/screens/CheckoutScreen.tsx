import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, MapPin, Check, Truck, CreditCard, Banknote, Landmark, CheckCircle, Loader2 } from 'lucide-react';
import { useCart } from '../context/CartContext';
import { motion, AnimatePresence } from 'motion/react';
import { auth } from '../lib/firebase';
import { apiRequest } from '../lib/apiClient';
import { cn } from '../lib/utils';
import { useAuth } from '../context/AuthContext';

export const CheckoutScreen: React.FC = () => {
  const navigate = useNavigate();
  const { profile: userProfile } = useAuth();
  const { totalPrice, clearCart, items } = useCart();
  const [paymentMethod, setPaymentMethod] = useState('pod');
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState<string | null>(null);

  const showToast = (message: string) => {
    setToast(message);
    setTimeout(() => setToast(null), 3000);
  };

  const deliveryFee = totalPrice >= 1500 ? 0 : 125;
  const finalTotal = totalPrice + deliveryFee;

  const handlePlaceOrder = async () => {
    if (!auth.currentUser) {
      showToast('Please login to place an order');
      return;
    }

    setLoading(true);
    try {
      const orderData = {
        items: items.map(item => ({
          productId: item.id,
          name: item.name,
          quantity: item.quantity,
          price: item.price
        })),
        totalAmount: finalTotal,
        paymentMethod,
        deliveryAddress: userProfile?.location || 'Store Pickup',
        shopName: userProfile?.shopName || 'My Shop'
      };

      const result = await apiRequest(`/api/orders`, {
        method: 'POST',
        body: JSON.stringify(orderData)
      });

      const orderId = result.id;

      clearCart();
      navigate('/order-success', { state: { orderId } });
    } catch (error) {
      console.error('Error placing order:', error);
      showToast('Failed to place order. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-[100dvh] bg-spaza-bg flex flex-col">
      <header className="bg-spaza-green pt-[env(safe-area-inset-top,2rem)] pb-6 px-6 flex items-center gap-4 shadow-lg shadow-black/5">
        <button 
          onClick={() => navigate(-1)} 
          className="w-10 h-10 bg-white/10 rounded-xl flex items-center justify-center active:scale-95 transition-transform"
        >
            <ArrowLeft size={20} className="text-white" />
        </button>
        <h2 className="text-lg font-bold text-white">Checkout</h2>
      </header>

      <div className="px-6 py-8 space-y-8 flex-1 overflow-y-auto pb-40">
        {/* Delivery Address */}
        <section>
            <h3 className="text-[13px] font-bold text-text-primary mb-4 px-1">Delivery Address</h3>
            <div className="bg-card-bg p-5 rounded-[24px] shadow-premium flex items-start gap-4 border border-border-custom">
                <div className="w-10 h-10 bg-spaza-bg rounded-xl flex items-center justify-center shrink-0">
                    <MapPin size={22} className="text-spaza-green" />
                </div>
                <div className="flex-1">
                    <div className="flex justify-between items-center mb-1">
                        <h4 className="text-sm font-bold text-text-primary leading-tight">
                          {userProfile?.activeShopId 
                            ? (userProfile.shopName || "My Shop") 
                            : (userProfile?.firstName ? `${userProfile.firstName}'s Shop` : "My SpazaLink Shop")}
                        </h4>
                        <button 
                          onClick={() => navigate('/profile', { state: { showAddresses: true } })}
                          className="text-spaza-green text-[11px] font-bold"
                        >
                          Change
                        </button>
                    </div>
                    <p className="text-[11px] text-text-secondary font-medium leading-relaxed">
                      {userProfile?.location || "No address saved. Please update in profile."}
                    </p>
                </div>
            </div>
        </section>

        {/* Delivery Option */}
        <section>
            <h3 className="text-[13px] font-bold text-text-primary mb-4 px-1">Delivery Option</h3>
            <div className="bg-card-bg p-5 rounded-[24px] shadow-premium flex items-center justify-between border border-border-custom">
                <div className="flex items-center gap-4">
                    <div className="w-10 h-10 bg-spaza-bg rounded-xl flex items-center justify-center text-text-secondary">
                        <Truck size={22} />
                    </div>
                    <div>
                        <h4 className="text-sm font-bold text-text-primary uppercase tracking-tight">delivery at your doorstep</h4>
                        <p className="text-[11px] text-text-secondary font-medium">Friday, 24 May 2024 | 08:00 – 12:00</p>
                    </div>
                </div>
                <span className={cn(
                    "text-[11px] font-bold uppercase tracking-wider",
                    deliveryFee === 0 ? "text-spaza-green" : "text-text-primary"
                )}>
                    {deliveryFee === 0 ? "INCLUDED" : `R${deliveryFee.toFixed(2)}`}
                </span>
            </div>
        </section>

        {/* Payment Method */}
        <section>
            <h3 className="text-[13px] font-bold text-text-primary mb-4 px-1">Payment Method</h3>
            <div className="space-y-3">
                {[
                    { id: 'pod', label: 'Pay on Delivery', icon: Banknote },
                    { id: 'eft', label: 'EFT / Bank Transfer', icon: Landmark },
                    { id: 'card', label: 'Card Payment', icon: CreditCard },
                ].map((method) => (
                    <button 
                        key={method.id}
                        onClick={() => setPaymentMethod(method.id)}
                        className={cn(
                          "w-full bg-card-bg p-5 rounded-[24px] shadow-premium flex items-center justify-between border transition-all",
                          paymentMethod === method.id ? 'border-spaza-green' : 'border-border-custom'
                        )}
                    >
                        <div className="flex items-center gap-4">
                            <div className={cn(
                              "w-5 h-5 rounded-full border-2 flex items-center justify-center transition-all",
                              paymentMethod === method.id ? 'border-spaza-green' : 'border-text-secondary opacity-20'
                            )}>
                                {paymentMethod === method.id && <div className="w-2.5 h-2.5 rounded-full bg-spaza-green" />}
                            </div>
                            <span className="text-sm font-medium text-text-primary">{method.label}</span>
                        </div>
                        <method.icon size={20} className="text-text-secondary opacity-50" />
                    </button>
                ))}
            </div>
        </section>

        {/* Order Summary */}
        <section className="pt-4">
            <div className="space-y-3 px-1">
                <div className="flex justify-between items-center">
                    <span className="text-sm text-text-secondary font-medium tracking-tight">Subtotal</span>
                    <span className="text-sm text-text-primary font-bold tracking-tight">R{totalPrice.toFixed(2)}</span>
                </div>
                <div className="flex justify-between items-center">
                    <span className="text-sm text-text-secondary font-medium tracking-tight">Delivery</span>
                    <span className={cn(
                        "text-sm font-bold tracking-tight",
                        deliveryFee === 0 ? "text-spaza-green" : "text-text-primary"
                    )}>
                        {deliveryFee === 0 ? "INCLUDED" : `R${deliveryFee.toFixed(2)}`}
                    </span>
                </div>
                <div className="h-px bg-border-custom my-2" />
                <div className="flex justify-between items-center">
                    <span className="text-[15px] text-text-primary font-bold tracking-tight">Total</span>
                    <span className="text-xl text-text-primary font-bold tracking-tighter">R{finalTotal.toFixed(2)}</span>
                </div>
                <div className="flex justify-between items-center mt-3 pt-2">
                   <div className="bg-spaza-green/10 px-3 py-1.5 rounded-lg border border-spaza-green/10 flex items-center gap-2">
                      <span className="text-[11px] font-bold text-spaza-green">You save</span>
                      <span className="text-[11px] font-bold text-spaza-green">R{(totalPrice * 0.1).toFixed(2)}</span>
                   </div>
                </div>
            </div>
        </section>
      </div>

      <div className="fixed bottom-16 left-0 right-0 p-6 bg-card-bg border-t border-border-custom safe-area-bottom shadow-[0_-8px_30px_rgba(0,0,0,0.08)] z-40">
        <button 
          onClick={handlePlaceOrder}
          disabled={loading || items.length === 0}
          className="w-full bg-spaza-green-dark hover:bg-green-900 text-white font-bold py-4.5 rounded-xl shadow-lg shadow-black/20 transition-all active:scale-95 flex items-center justify-center gap-2"
        >
          {loading ? <Loader2 className="animate-spin" size={20} /> : 'Place Order'}
        </button>
      </div>
    </div>
  );
};

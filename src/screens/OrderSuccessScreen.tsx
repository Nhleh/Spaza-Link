import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { motion } from 'motion/react';
import { CheckCircle2, ArrowRight, ShoppingBag } from 'lucide-react';

export const OrderSuccessScreen: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const orderId = location.state?.orderId || 'N/A';

  return (
    <div className="min-h-screen bg-spaza-bg flex flex-col items-center justify-center px-8 text-center">
      <motion.div
        initial={{ scale: 0, rotate: -45 }}
        animate={{ scale: 1, rotate: 0 }}
        transition={{ type: 'spring', damping: 10, stiffness: 100 }}
        className="w-24 h-24 bg-spaza-green rounded-3xl flex items-center justify-center text-white mb-8 shadow-2xl shadow-spaza-green/30"
      >
        <CheckCircle2 size={48} strokeWidth={2.5} />
      </motion.div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
      >
        <h2 className="text-2xl font-bold text-text-primary mb-2">Order Confirmed!</h2>
        <p className="text-text-secondary font-medium mb-12 leading-relaxed">
          Your order {orderId} has been placed successfully. We'll notify you when it's out for delivery.
        </p>
      </motion.div>

      <div className="w-full space-y-4">
        <button 
          onClick={() => navigate('/order-tracking', { state: { orderId } })}
          className="w-full bg-spaza-green text-white font-bold py-4.5 rounded-xl shadow-lg shadow-spaza-green/20 flex items-center justify-center gap-2 active:scale-95 transition-all"
        >
          Track My Order
          <ArrowRight size={18} />
        </button>
        <button 
          onClick={() => navigate('/home')}
          className="w-full bg-card-bg text-text-secondary font-bold py-4.5 rounded-xl border border-border-custom flex items-center justify-center gap-2 active:scale-95 transition-all"
        >
          <ShoppingBag size={18} />
          Go to Home
        </button>
      </div>
    </div>
  );
};

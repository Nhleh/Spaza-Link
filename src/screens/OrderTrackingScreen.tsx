import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { ArrowLeft, CheckCircle2, MapPin, Phone, MessageSquare, Truck, Loader2 } from 'lucide-react';
import { motion } from 'motion/react';
import { cn } from '../lib/utils';
import { apiRequest } from '../lib/apiClient';

export const OrderTrackingScreen: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const orderId = location.state?.orderId;
  
  const [orderData, setOrderData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState<{ message: string; type: 'info' | 'success' } | null>(null);

  useEffect(() => {
    if (!orderId) {
      setLoading(false);
      return;
    }

    const fetchOrder = async () => {
      try {
        const data = await apiRequest(`/api/data/orders/${orderId}`);
        if (data) {
          setOrderData(data);
        }
      } catch (error) {
        console.error('Error fetching order:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchOrder();
    const interval = setInterval(fetchOrder, 10000); // Poll every 10s

    return () => clearInterval(interval);
  }, [orderId]);

  const showToast = (message: string) => {
    setToast({ message, type: 'info' });
    setTimeout(() => setToast(null), 3000);
  };

  const getStatusIndex = (status: string) => {
    const statuses = ["Order Confirmed", "Being Packed", "Out for Delivery", "Delivered"];
    return statuses.indexOf(status);
  };

  const currentIndex = orderData ? getStatusIndex(orderData.status) : -1;

  const steps = [
    { title: 'Order Confirmed', time: '10:15 AM', status: currentIndex > 0 ? 'completed' : currentIndex === 0 ? 'active' : 'upcoming' },
    { title: 'Being Packed', time: '11:30 AM', status: currentIndex > 1 ? 'completed' : currentIndex === 1 ? 'active' : 'upcoming' },
    { title: 'Out for Delivery', time: 'In Transit', status: currentIndex > 2 ? 'completed' : currentIndex === 2 ? 'active' : 'upcoming', desc: 'Thabo is nearby' },
    { title: 'Delivered', time: 'Pending', status: currentIndex === 3 ? 'completed' : 'upcoming' },
  ];

  if (loading) {
    return (
      <div className="min-h-screen bg-spaza-bg flex items-center justify-center">
        <Loader2 className="animate-spin text-spaza-green" size={40} />
      </div>
    );
  }

  if (!orderId && !orderData) {
    return (
      <div className="min-h-screen bg-spaza-bg flex flex-col items-center justify-center p-6 text-center">
        <MapPin size={48} className="text-text-secondary opacity-20 mb-4" />
        <h2 className="text-lg font-bold text-text-primary mb-2">No Order Selected</h2>
        <p className="text-xs text-text-secondary mb-8">Please track an order from your history or checkout.</p>
        <button onClick={() => navigate('/home')} className="bg-spaza-green text-white px-8 py-3 rounded-xl font-bold">Go Home</button>
      </div>
    );
  }

  return (
    <div className="min-h-[100dvh] bg-spaza-bg flex flex-col">
      <header className="px-6 pt-[env(safe-area-inset-top,2rem)] pb-6 flex items-center gap-4 bg-card-bg border-b border-border-custom">
        <button 
          onClick={() => navigate(-1)} 
          className="w-10 h-10 bg-spaza-bg rounded-xl flex items-center justify-center active:scale-95 transition-transform"
        >
            <ArrowLeft size={20} className="text-text-primary" />
        </button>
        <h2 className="text-lg font-bold text-text-primary">Track Order</h2>
      </header>

      <div className="flex-1 overflow-y-auto pb-40">
        {/* Map View */}
        <div className="h-64 bg-gray-100 relative overflow-hidden">
          {/* Mock Map Background */}
          <div className="absolute inset-0 bg-[#f8f9fa]" style={{ backgroundImage: 'radial-gradient(#ddd 1px, transparent 1px)', backgroundSize: '20px 20px' }}>
            <div className="absolute inset-0 flex items-center justify-center opacity-10">
              <MapPin size={100} />
            </div>
          </div>
          
          {/* Driver Marker */}
          <motion.div 
            initial={false}
            animate={{ 
                x: currentIndex === 2 ? 50 : currentIndex === 3 ? 150 : -50,
                y: currentIndex === 2 ? -20 : currentIndex === 3 ? -100 : 0
            }}
            transition={{ type: 'spring', damping: 15 }}
            className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-10"
          >
            <div className="relative">
              <div className="w-12 h-12 bg-spaza-green rounded-2xl flex items-center justify-center border-4 border-white shadow-xl rotate-3">
                  <Truck size={24} className="text-white" />
              </div>
              <div className="w-4 h-4 bg-spaza-green/20 blur-sm rounded-full absolute -bottom-2 left-4 animate-pulse" />
            </div>
          </motion.div>

          {/* Destination Marker */}
          <div className="absolute top-1/3 right-1/4">
             <MapPin size={32} className="text-red-500 fill-red-500/20" />
          </div>
        </div>

        <div className="px-6 -mt-8 relative z-20">
          <div className="bg-card-bg p-6 rounded-[32px] shadow-premium border border-border-custom">
              <div className="flex justify-between items-start mb-8">
                  <div>
                    <h3 className="text-lg font-bold text-text-primary leading-tight">Order #{orderId?.split('-')[1]?.slice(-5) || '8821'}</h3>
                    <p className="text-[11px] text-text-secondary font-medium">
                        {currentIndex === 3 ? 'Delivered successfully' : 'Estimated arrival: 14:30 Today'}
                    </p>
                  </div>
                  <span className={cn(
                      "text-[10px] font-bold px-3 py-1.5 rounded-full uppercase tracking-wider",
                      orderData?.status === 'Delivered' ? "bg-spaza-green/10 text-spaza-green" : "bg-blue-500/10 text-blue-500"
                  )}>
                      {orderData?.status}
                  </span>
              </div>

              {/* Steps */}
              <div className="space-y-8 pl-1">
                  {steps.map((step, idx) => (
                      <div key={idx} className="flex gap-5 relative">
                          {idx !== steps.length - 1 && (
                              <div className={cn(
                                "absolute left-2.5 top-6 w-0.5 h-10 transition-all duration-500",
                                step.status === 'completed' || step.status === 'active' ? 'bg-spaza-green' : 'bg-border-custom border'
                              )} />
                          )}
                          <div className="relative z-10">
                              {step.status === 'completed' ? (
                                  <motion.div 
                                    initial={{ scale: 0.8 }}
                                    animate={{ scale: 1 }}
                                    className="w-5 h-5 bg-spaza-green rounded-full flex items-center justify-center shadow-lg shadow-spaza-green/20"
                                  >
                                      <div className="w-1.5 h-1.5 bg-white rounded-full" />
                                  </motion.div>
                              ) : step.status === 'active' ? (
                                  <div className="w-5 h-5 bg-spaza-green ring-4 ring-spaza-green/10 rounded-full flex items-center justify-center">
                                      <div className="w-2 h-2 bg-white rounded-full animate-pulse" />
                                  </div>
                              ) : (
                                  <div className="w-5 h-5 bg-spaza-bg rounded-full border border-border-custom" />
                              )}
                          </div>
                          <div className="flex-1 pb-2">
                              <div className="flex justify-between items-start">
                                  <h5 className={cn(
                                    "text-[13px] font-bold tracking-tight transition-colors duration-500",
                                    step.status === 'upcoming' ? 'text-text-secondary opacity-30' : step.status === 'active' ? 'text-spaza-green' : 'text-text-primary'
                                  )}>
                                    {step.title}
                                  </h5>
                                  <span className="text-[10px] font-medium text-text-secondary">{step.time}</span>
                              </div>
                              {step.desc && (
                                  <p className="text-[11px] font-medium text-text-secondary mt-0.5">{step.desc}</p>
                              )}
                          </div>
                      </div>
                  ))}
              </div>

              {/* Driver Card */}
              <div className="mt-10 bg-spaza-bg p-4 rounded-[24px] flex items-center gap-4 border border-border-custom">
                  <div className="w-12 h-12 rounded-2xl overflow-hidden shadow-sm border-2 border-card-bg">
                      <img src="https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&q=80&w=100" alt="driver" className="w-full h-full object-cover" />
                  </div>
                  <div className="flex-1">
                      <p className="text-sm font-bold text-text-primary">Sipho Mokoena</p>
                      <p className="text-[11px] text-text-secondary font-medium">SpazaLink Delivery Partner</p>
                  </div>
                  <div className="flex gap-2">
                    <button 
                      onClick={() => showToast('Calling Sipho...')}
                      className="w-10 h-10 bg-card-bg rounded-xl flex items-center justify-center text-spaza-green shadow-sm border border-border-custom active:scale-95 transition-transform"
                    >
                      <Phone size={18} strokeWidth={2.5} />
                    </button>
                    <button 
                      onClick={() => showToast('Chat with Sipho coming soon!')}
                      className="w-10 h-10 bg-card-bg rounded-xl flex items-center justify-center text-text-secondary shadow-sm border border-border-custom active:scale-95 transition-transform"
                    >
                      <MessageSquare size={18} strokeWidth={2.5} />
                    </button>
                  </div>
              </div>
          </div>
        </div>
      </div>

      <div className="fixed bottom-0 left-0 right-0 p-6 bg-card-bg border-t border-border-custom safe-area-bottom shadow-lg">
        <button 
          onClick={() => navigate('/home')}
          className="w-full bg-text-primary text-card-bg font-bold py-4.5 rounded-xl shadow-lg active:scale-95 transition-all"
        >
            Back to Home
        </button>
      </div>

      {toast && (
        <div className="fixed top-12 left-0 right-0 z-[100] px-6">
          <div className="bg-card-bg border border-border-custom px-4 py-3 rounded-2xl shadow-xl flex items-center gap-3">
             <CheckCircle2 size={18} className="text-spaza-green" />
             <span className="text-xs font-bold text-text-primary">{toast.message}</span>
          </div>
        </div>
      )}
    </div>
  );
};


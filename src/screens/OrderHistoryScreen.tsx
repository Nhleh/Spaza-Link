import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, Search, SlidersHorizontal, ChevronRight, CheckCircle, X, ShoppingBag, Loader2 } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { cn } from '../lib/utils';
import { apiRequest } from '../lib/apiClient';
import { auth } from '../lib/firebase';

export const OrderHistoryScreen: React.FC = () => {
  const navigate = useNavigate();
  const [orders, setOrders] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedStatus, setSelectedStatus] = useState('All');
  const [showFilters, setShowFilters] = useState(false);

  const statuses = ['All', 'Delivered', 'Processing', 'Cancelled', 'In Transit', 'Order Confirmed', 'Being Packed', 'Out for Delivery'];

  useEffect(() => {
    const fetchOrders = async () => {
      if (!auth.currentUser) return;
      try {
        const data = await apiRequest('/api/data/orders');
        setOrders(data || []);
      } catch (error) {
        console.error('Error fetching orders:', error);
      } finally {
        setLoading(false);
      }
    };
    fetchOrders();
  }, []);

  const filteredOrders = orders
    .filter(order => selectedStatus === 'All' || order.status === selectedStatus)
    .filter(order => 
      (order.id && order.id.toLowerCase().includes(searchQuery.toLowerCase())) || 
      (order.status && order.status.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (order.items && Array.isArray(order.items) && order.items.some((item: any) => item.name.toLowerCase().includes(searchQuery.toLowerCase())))
    );

  if (loading) {
    return (
      <div className="min-h-screen bg-spaza-bg flex items-center justify-center">
        <Loader2 className="animate-spin text-spaza-green" size={32} />
      </div>
    );
  }

  return (
    <div className="min-h-[100dvh] bg-spaza-bg flex flex-col pt-0 overflow-x-hidden">
      <header className="px-6 pt-[env(safe-area-inset-top,2rem)] space-y-4 mb-6">
        <div className="flex items-center gap-4">
            <button onClick={() => navigate(-1)} className="p-2 bg-card-bg rounded-xl shadow-sm border border-border-custom active:scale-90 transition-transform">
                <ArrowLeft size={20} className="text-spaza-green" />
            </button>
            <h2 className="text-xl font-bold text-text-primary">My Orders</h2>
        </div>
        
        <div className="flex items-center gap-3">
            <div className="flex-1 flex items-center gap-3 bg-card-bg border border-border-custom rounded-xl px-4 py-3 shadow-sm focus-within:ring-2 focus-within:ring-spaza-green/20 transition-all">
                <Search size={20} className="text-text-secondary" />
                <input 
                  type="text" 
                  placeholder="Search order ID..." 
                  className="bg-transparent outline-none flex-1 text-sm font-medium text-text-primary placeholder:text-text-secondary w-full" 
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                />
            </div>
            <button 
              onClick={() => setShowFilters(true)}
              className={cn(
                "p-3 bg-card-bg border rounded-xl shadow-sm transition-all active:scale-90",
                selectedStatus !== 'All' ? "border-spaza-green text-spaza-green" : "border-border-custom text-text-secondary"
              )}
            >
                <SlidersHorizontal size={20} />
            </button>
        </div>
      </header>

      <div className="px-6 space-y-4 pb-32 flex-1 overflow-y-auto scrollbar-hide">
        {filteredOrders.length > 0 ? (
          filteredOrders.map((order) => (
            <div key={order.id} className="bg-card-bg p-5 rounded-3xl border border-border-custom shadow-sm relative overflow-hidden active:scale-[0.98] transition-all">
                <div className="flex justify-between items-start mb-4">
                    <div className="space-y-1">
                        <div className="flex flex-wrap items-center gap-2">
                          <h4 className="text-sm font-black text-text-primary tracking-tight">Order #{order.id.slice(-6).toUpperCase()}</h4>
                          <span className={cn(
                            "text-[9px] font-black uppercase px-2 py-0.5 rounded-full",
                            ['Delivered', 'Delivered'].includes(order.status) && "bg-green-500/10 text-spaza-green",
                            ['Processing', 'Being Packed', 'Order Confirmed'].includes(order.status) && "bg-amber-500/10 text-amber-500",
                            ['In Transit', 'Out for Delivery'].includes(order.status) && "bg-blue-500/10 text-blue-500",
                            order.status === 'Cancelled' && "bg-red-500/10 text-red-500"
                          )}>
                            {order.status}
                          </span>
                        </div>
                        <p className="text-[11px] text-text-secondary font-bold uppercase tracking-wider">
                          {order.createdAt ? (order.createdAt.toDate ? order.createdAt.toDate().toLocaleDateString() : new Date(order.createdAt).toLocaleDateString()) : 'N/A'}
                        </p>
                    </div>
                </div>

                <div className="flex items-center justify-between mt-6 pt-4 border-t border-border-custom">
                    <div className="flex flex-col">
                      <span className="text-[10px] font-bold text-text-secondary uppercase">Total Amount</span>
                      <span className="text-lg font-black text-text-primary">R{order.totalAmount?.toFixed(2) || '0.00'}</span>
                    </div>
                    <button 
                        onClick={() => navigate('/order-tracking', { state: { orderId: order.id } })}
                        className="bg-spaza-bg text-spaza-green p-3 rounded-2xl active:scale-95 transition-all text-xs font-black uppercase tracking-widest flex items-center gap-2"
                    >
                        Details <ChevronRight size={16} />
                    </button>
                </div>
            </div>
          ))
        ) : (
          <div className="flex flex-col items-center justify-center py-20 text-gray-300">
            <ShoppingBag size={48} className="mb-4 opacity-20" />
            <p className="text-sm font-bold">No orders found</p>
            <p className="text-[11px] font-medium mt-1">Try searching for something else</p>
          </div>
        )}
      </div>

      {/* Filter Modal */}
      <AnimatePresence>
        {showFilters && (
          <motion.div
            initial={{ opacity: 0, y: '100%' }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: '100%' }}
            className="fixed inset-0 z-[100] bg-card-bg flex flex-col"
          >
            <header className="px-6 pt-12 pb-6 border-b border-border-custom flex items-center justify-between shrink-0">
              <h2 className="text-xl font-bold text-text-primary">Filter History</h2>
              <button 
                onClick={() => setShowFilters(false)}
                className="w-10 h-10 bg-spaza-bg rounded-xl flex items-center justify-center text-text-secondary active:scale-90 transition-transform"
              >
                <X size={20} />
              </button>
            </header>

            <div className="p-6 space-y-8 flex-1 overflow-y-auto">
              <div className="space-y-4">
                <h3 className="text-sm font-bold text-text-primary uppercase tracking-widest text-opacity-40">Status</h3>
                <div className="grid grid-cols-2 gap-3">
                  {statuses.map((status) => (
                    <button
                      key={status}
                      onClick={() => setSelectedStatus(status)}
                      className={cn(
                        "px-4 py-4 rounded-2xl text-[11px] font-bold border transition-all flex items-center gap-3",
                        selectedStatus === status 
                          ? "bg-spaza-green text-white border-spaza-green shadow-lg shadow-spaza-green/20" 
                          : "bg-card-bg text-text-secondary border-border-custom"
                      )}
                    >
                      <div className={cn(
                        "w-5 h-5 rounded-lg border flex items-center justify-center transition-all shrink-0",
                        selectedStatus === status ? "bg-white border-white" : "border-border-custom"
                      )}>
                        {selectedStatus === status && <CheckCircle size={14} className="text-spaza-green" />}
                      </div>
                      <span className="truncate">{status}</span>
                    </button>
                  ))}
                </div>
              </div>
            </div>

            <div className="p-6 pb-12 flex gap-4 bg-card-bg border-t border-border-custom shrink-0">
              <button 
                onClick={() => {
                  setSelectedStatus('All');
                  setSearchQuery('');
                  setShowFilters(false);
                }}
                className="flex-1 bg-spaza-bg text-text-secondary font-bold py-4 rounded-xl active:scale-95 transition-all text-sm uppercase tracking-widest"
              >
                Reset
              </button>
              <button 
                onClick={() => setShowFilters(false)}
                className="flex-[2] bg-spaza-green text-white font-bold py-4 rounded-xl shadow-lg active:scale-95 transition-all text-sm uppercase tracking-widest"
              >
                Apply
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

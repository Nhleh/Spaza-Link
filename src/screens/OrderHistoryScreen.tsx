import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, Search, SlidersHorizontal, ChevronRight, CheckCircle, X } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { cn } from '../lib/utils';

export const OrderHistoryScreen: React.FC = () => {
  const navigate = useNavigate();
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedStatus, setSelectedStatus] = useState('All');
  const [showFilters, setShowFilters] = useState(false);

  const statuses = ['All', 'Delivered', 'Processing', 'Cancelled', 'In Transit'];

  const orders = [
    { id: 'SL245678', date: '23 May 2024', total: 'R2,356.40', status: 'Delivered', items: [{ name: 'Coca-Cola' }, { name: 'Albany Bread' }] },
    { id: 'SL245201', date: '16 May 2024', total: 'R1,890.20', status: 'Delivered', items: [{ name: 'Sunlight Soap' }] },
    { id: 'SL245350', date: '19 May 2024', total: 'R3,120.00', status: 'In Transit', items: [{ name: 'Maize Meal' }] },
    { id: 'SL245400', date: '20 May 2024', total: 'R950.50', status: 'Processing', items: [{ name: 'Milk' }] },
    { id: 'SL244872', date: '08 May 2024', total: 'R2,150.00', status: 'Delivered', items: [{ name: 'Rice' }] },
    { id: 'SL244310', date: '02 May 2024', total: 'R1,560.35', status: 'Cancelled', items: [{ name: 'Sugar' }] },
    { id: 'SL243998', date: '25 Apr 2024', total: 'R2,008.20', status: 'Delivered', items: [{ name: 'Tea' }] },
  ];

  const filteredOrders = orders
    .filter(order => selectedStatus === 'All' || order.status === selectedStatus)
    .filter(order => 
      order.id.toLowerCase().includes(searchQuery.toLowerCase()) || 
      order.status.toLowerCase().includes(searchQuery.toLowerCase()) ||
      order.items.some(item => item.name.toLowerCase().includes(searchQuery.toLowerCase()))
    );

  return (
    <div className="min-h-screen bg-spaza-bg flex flex-col pt-4">
      <header className="px-6 space-y-4 mb-6">
        <div className="flex items-center gap-4">
            <button onClick={() => navigate(-1)} className="p-2 bg-card-bg rounded-xl shadow-sm border border-border-custom">
                <ArrowLeft size={20} className="text-spaza-green" />
            </button>
            <h2 className="text-xl font-bold text-text-primary">My Orders</h2>
        </div>
        
        <div className="flex items-center gap-3">
            <div className="flex-1 flex items-center gap-3 bg-card-bg border border-border-custom rounded-xl px-4 py-3 shadow-sm">
                <Search size={20} className="text-text-secondary" />
                <input 
                  type="text" 
                  placeholder="Search order ID..." 
                  className="bg-transparent outline-none flex-1 text-sm font-medium text-text-primary placeholder:text-text-secondary" 
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                />
            </div>
            <button 
              onClick={() => setShowFilters(true)}
              className={cn(
                "p-3 bg-card-bg border rounded-xl shadow-sm transition-all",
                selectedStatus !== 'All' ? "border-spaza-green text-spaza-green" : "border-border-custom text-text-secondary"
              )}
            >
                <SlidersHorizontal size={20} />
            </button>
        </div>
      </header>

      <div className="px-6 space-y-4 pb-32 overflow-y-auto">
        {filteredOrders.length > 0 ? (
          filteredOrders.map((order) => (
            <div key={order.id} className="bg-card-bg p-5 rounded-3xl border border-border-custom shadow-sm relative overflow-hidden group">
                <div className="flex justify-between items-start mb-4">
                    <div className="space-y-1">
                        <div className="flex items-center gap-2">
                          <h4 className="text-sm font-black text-text-primary tracking-tight">Order #{order.id}</h4>
                          <span className={cn(
                            "text-[9px] font-black uppercase px-2 py-0.5 rounded-full",
                            order.status === 'Delivered' && "bg-green-500/10 text-spaza-green",
                            order.status === 'Processing' && "bg-amber-500/10 text-amber-500",
                            order.status === 'In Transit' && "bg-blue-500/10 text-blue-500",
                            order.status === 'Cancelled' && "bg-red-500/10 text-red-500"
                          )}>
                            {order.status}
                          </span>
                        </div>
                        <p className="text-[11px] text-text-secondary font-bold uppercase tracking-wider">{order.date}</p>
                    </div>
                </div>

                <div className="flex items-center justify-between mt-6 pt-4 border-t border-border-custom">
                    <div className="flex flex-col">
                      <span className="text-[10px] font-bold text-text-secondary uppercase">Total Amount</span>
                      <span className="text-lg font-black text-text-primary">{order.total}</span>
                    </div>
                    <button 
                        onClick={() => navigate('/order-tracking')}
                        className="bg-spaza-bg text-spaza-green p-3 rounded-2xl active:scale-95 transition-all text-xs font-black uppercase tracking-widest flex items-center gap-2"
                    >
                        Details <ChevronRight size={16} />
                    </button>
                </div>
            </div>
          ))
        ) : (
          <div className="flex flex-col items-center justify-center py-20 text-gray-300">
            <Search size={48} className="mb-4 opacity-20" />
            <p className="text-sm font-bold">No orders found</p>
            <p className="text-[11px] font-medium mt-1">Try adjusting your filters</p>
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
            className="fixed inset-0 z-50 bg-card-bg"
          >
            <header className="px-6 pt-12 pb-6 border-b border-border-custom flex items-center justify-between">
              <h2 className="text-xl font-bold text-text-primary">Filter History</h2>
              <button 
                onClick={() => setShowFilters(false)}
                className="w-10 h-10 bg-spaza-bg rounded-xl flex items-center justify-center text-text-secondary"
              >
                <X size={20} />
              </button>
            </header>

            <div className="p-6 space-y-8">
              <div className="space-y-4">
                <h3 className="text-sm font-bold text-text-primary uppercase tracking-widest text-opacity-40">Status</h3>
                <div className="grid grid-cols-2 gap-3">
                  {statuses.map((status) => (
                    <button
                      key={status}
                      onClick={() => setSelectedStatus(status)}
                      className={cn(
                        "px-4 py-4 rounded-2xl text-xs font-bold border transition-all flex items-center gap-3",
                        selectedStatus === status 
                          ? "bg-spaza-green text-white border-spaza-green shadow-lg shadow-spaza-green/20" 
                          : "bg-card-bg text-text-secondary border-border-custom"
                      )}
                    >
                      <div className={cn(
                        "w-5 h-5 rounded-lg border flex items-center justify-center transition-all",
                        selectedStatus === status ? "bg-white border-white" : "border-border-custom"
                      )}>
                        {selectedStatus === status && <CheckCircle size={14} className="text-spaza-green" />}
                      </div>
                      {status}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            <div className="absolute bottom-12 left-6 right-6 flex gap-4">
              <button 
                onClick={() => {
                  setSelectedStatus('All');
                  setSearchQuery('');
                  setShowFilters(false);
                }}
                className="flex-1 bg-spaza-bg text-text-secondary font-bold py-4 rounded-xl active:scale-95 transition-all"
              >
                Reset
              </button>
              <button 
                onClick={() => setShowFilters(false)}
                className="flex-[2] bg-spaza-green text-white font-bold py-4 rounded-xl shadow-lg active:scale-95 transition-all"
              >
                Apply Filters
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

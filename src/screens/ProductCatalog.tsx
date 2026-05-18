import React, { useState, useEffect, useMemo } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { Search, SlidersHorizontal, Plus, Minus, ArrowLeft, ShoppingCart, CheckCircle, ArrowRight, Loader2, X } from 'lucide-react';
import { useCart } from '../context/CartContext';
import { motion, AnimatePresence } from 'motion/react';
import { cn } from '../lib/utils';
import { productService, Product } from '../services/productService';

export const ProductCatalog: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { items, addToCart, updateQuantity, totalPrice } = useCart();
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState(location.state?.category || 'All');
  const [searchQuery, setSearchQuery] = useState('');
  const [toast, setToast] = useState<string | null>(null);
  const [showFilters, setShowFilters] = useState(false);
  const [sortBy, setSortBy] = useState<'price-asc' | 'price-desc' | 'name'>('name');

  useEffect(() => {
    const fetchProducts = async () => {
      try {
        const data = await productService.getProducts();
        setProducts(data);
      } catch (error) {
        console.error('Error loading products:', error);
      } finally {
        setLoading(false);
      }
    };
    fetchProducts();
  }, []);

  const showToast = (message: string) => {
    setToast(message);
    setTimeout(() => setToast(null), 2000);
  };

  const categories = ['All', 'Drinks', 'Snacks', 'Grocery', 'Toiletries', 'Frozen', 'Bread', 'Cleaning'];

  const filteredProducts = useMemo(() => {
    return products
      .filter(p => selectedCategory === 'All' || p.category === selectedCategory || (selectedCategory === 'More' && !categories.includes(p.category)))
      .filter(p => !searchQuery || p.name.toLowerCase().includes(searchQuery.toLowerCase()) || p.description.toLowerCase().includes(searchQuery.toLowerCase()))
      .sort((a, b) => {
        if (sortBy === 'price-asc') return a.price - b.price;
        if (sortBy === 'price-desc') return b.price - a.price;
        return a.name.localeCompare(b.name);
      });
  }, [products, selectedCategory, searchQuery, sortBy, categories]);

  if (loading) {
    return (
      <div className="min-h-screen bg-spaza-bg flex items-center justify-center">
        <Loader2 className="animate-spin text-spaza-green" size={32} />
      </div>
    );
  }

  return (
    <div className="min-h-[100dvh] bg-spaza-bg flex flex-col">
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

      {/* Search Header */}
      <header className="bg-spaza-green pt-[env(safe-area-inset-top,2rem)] pb-6 px-6 space-y-6 shadow-lg">
        <div className="flex items-center gap-4">
            <button 
              onClick={() => navigate(-1)} 
              className="w-10 h-10 bg-white/10 rounded-xl flex items-center justify-center active:scale-95 transition-transform"
            >
                <ArrowLeft size={20} className="text-white" />
            </button>
            <h2 className="text-lg font-bold text-white">Shop Direct</h2>
        </div>
        
        <div className="flex items-center gap-3">
            <div className="flex-1 flex items-center gap-3 bg-card-bg rounded-2xl px-4 py-3 group focus-within:ring-2 focus-within:ring-white/20 transition-all">
                <Search size={20} className="text-text-secondary" />
                <input 
                   type="text" 
                   value={searchQuery}
                   onChange={(e) => setSearchQuery(e.target.value)}
                   placeholder="Search bulk stock..." 
                   className="bg-transparent outline-none flex-1 text-sm font-medium placeholder:text-text-secondary text-text-primary" 
                />
            </div>
            <button 
               onClick={() => setShowFilters(true)}
               className="w-12 h-12 bg-white rounded-2xl text-spaza-green flex items-center justify-center active:scale-95 shadow-lg shadow-black/5"
            >
                <SlidersHorizontal size={20} />
            </button>
        </div>
      </header>

      {/* Categories Tabs */}
      <div className="px-6 py-4">
        <div className="grid grid-cols-4 gap-2">
          {categories.map((cat) => (
              <button 
                  key={cat}
                  onClick={() => setSelectedCategory(cat)}
                  className={cn(
                      "px-2 py-2 rounded-xl text-[11px] font-black uppercase tracking-tight transition-all text-center border truncate",
                      selectedCategory === cat 
                          ? "bg-spaza-green text-white shadow-lg shadow-spaza-green/20 border-spaza-green" 
                          : "bg-card-bg text-text-secondary border-border-custom"
                  )}
              >
                  {cat}
              </button>
          ))}
        </div>
      </div>

      {/* Product List */}
      <div className="flex-1 px-6 space-y-4 pb-48 overflow-y-auto scrollbar-hide">
        {filteredProducts.length > 0 ? (
          filteredProducts.map((product) => {
            const cartItem = items.find(i => i.id === product.id);
            return (
              <div 
                key={product.id} 
                className="bg-card-bg p-4 rounded-[28px] shadow-premium flex items-center gap-3 sm:gap-4 active:scale-[0.98] transition-all border border-border-custom"
              >
                  {/* Product Image */}
                  <div className="w-14 h-14 sm:w-16 sm:h-16 bg-spaza-bg rounded-2xl p-2 flex items-center justify-center shrink-0 border border-border-custom">
                      <img src={product.img} alt={product.name} className="w-full h-full object-contain" />
                  </div>

                  {/* Product Info */}
                  <div className="flex-1 min-w-0">
                      <h4 className="text-[13px] sm:text-[14px] font-bold text-text-primary leading-tight truncate">{product.name}</h4>
                      <p className="text-[10px] sm:text-[11px] text-text-secondary font-medium mb-1 truncate">{product.description}</p>
                      <div className="flex items-center gap-2">
                          <span className="text-sm font-bold text-text-primary">R{product.price.toFixed(2)}</span>
                      </div>
                  </div>
                  
                  {/* Stepper & Unit */}
                  <div className="flex flex-col items-end gap-1 shrink-0">
                      <div className="flex items-center bg-spaza-bg rounded-lg p-1 gap-2 sm:gap-3 border border-border-custom">
                          <button 
                              disabled={!cartItem}
                              onClick={(e) => {
                                e.stopPropagation();
                                updateQuantity(product.id, -1);
                              }}
                              className="w-7 h-7 flex items-center justify-center text-text-secondary hover:text-red-500 disabled:opacity-30 active:scale-90 transition-transform"
                          >
                              <Minus size={14} strokeWidth={3} />
                          </button>
                          <span className="text-xs font-bold text-text-primary w-4 text-center">{cartItem?.quantity || 0}</span>
                          <button 
                              onClick={(e) => {
                                e.stopPropagation();
                                addToCart(product);
                                showToast(`${product.name} added!`);
                              }}
                              className="w-7 h-7 flex items-center justify-center text-text-secondary active:text-spaza-green active:scale-90 transition-transform"
                          >
                              <Plus size={14} strokeWidth={3} />
                          </button>
                      </div>
                      <span className="text-[9px] font-bold text-text-secondary uppercase">{product.unit}</span>
                  </div>
              </div>
            )
          })
        ) : (
          <div className="flex flex-col items-center justify-center py-20 text-center">
            <div className="w-16 h-16 bg-gray-50 rounded-2xl flex items-center justify-center mb-4">
              <Search className="text-gray-300" size={32} />
            </div>
            <h3 className="text-gray-900 font-bold mb-1">No products found</h3>
            <p className="text-gray-400 text-sm">Try searching for something else</p>
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
            <header className="px-6 pt-6 safe-area-top pb-6 border-b border-border-custom flex items-center justify-between">
              <h2 className="text-xl font-bold text-text-primary">Sort & Filter</h2>
              <button 
                onClick={() => setShowFilters(false)}
                className="w-10 h-10 bg-spaza-bg rounded-xl flex items-center justify-center text-text-secondary"
              >
                <X size={20} />
              </button>
            </header>

            <div className="p-6 space-y-8">
              {/* Sort By */}
              <div className="space-y-4">
                <h3 className="text-sm font-bold text-text-primary uppercase tracking-widest text-opacity-40">Sort By</h3>
                <div className="flex flex-wrap gap-3">
                  {[
                    { id: 'name', label: 'Name (A-Z)' },
                    { id: 'price-asc', label: 'Price (Low-High)' },
                    { id: 'price-desc', label: 'Price (High-Low)' },
                  ].map((option) => (
                    <button
                      key={option.id}
                      onClick={() => setSortBy(option.id as any)}
                      className={cn(
                        "px-4 py-2 rounded-xl text-xs font-bold border transition-all",
                        sortBy === option.id 
                          ? "bg-spaza-green text-white border-spaza-green shadow-lg shadow-spaza-green/20" 
                          : "bg-card-bg text-text-secondary border-border-custom"
                      )}
                    >
                      {option.label}
                    </button>
                  ))}
                </div>
              </div>

              {/* Categories */}
              <div className="space-y-4">
                <h3 className="text-sm font-bold text-text-primary uppercase tracking-widest text-opacity-40">Category</h3>
                <div className="grid grid-cols-2 gap-3">
                  {categories.map((cat) => (
                    <button
                      key={cat}
                      onClick={() => setSelectedCategory(cat)}
                      className={cn(
                        "px-4 py-3 rounded-xl text-xs font-bold border transition-all flex items-center gap-3",
                        selectedCategory === cat 
                          ? "bg-spaza-green text-white border-spaza-green" 
                          : "bg-card-bg text-text-secondary border-border-custom"
                      )}
                    >
                      <div className={cn(
                        "w-5 h-5 rounded-md border flex items-center justify-center transition-all",
                        selectedCategory === cat ? "bg-white border-white" : "border-border-custom"
                      )}>
                        {selectedCategory === cat && <CheckCircle size={14} className="text-spaza-green" />}
                      </div>
                      {cat}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            <div className="absolute bottom-10 left-6 right-6">
              <button 
                onClick={() => setShowFilters(false)}
                className="w-full bg-spaza-green text-white font-bold py-4 rounded-xl shadow-lg active:scale-95 transition-all"
              >
                Show {filteredProducts.length} Results
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Floating Cart Bar */}
      {items.length > 0 && (
        <div className="fixed bottom-24 left-6 right-6 z-40">
            <motion.button 
                initial={{ y: 50, opacity: 0, scale: 0.9 }}
                animate={{ y: 0, opacity: 1, scale: 1 }}
                onClick={() => navigate('/cart')}
                className="w-full bg-spaza-green-dark text-white py-4.5 px-6 rounded-xl flex justify-between items-center shadow-2xl shadow-black/20 border border-white/5 active:scale-95 transition-transform"
            >
                <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-white/20 rounded-xl flex items-center justify-center">
                        <ShoppingCart size={20} className="text-white" />
                    </div>
                    <span className="text-[15px] font-bold tracking-tight">View Cart</span>
                </div>
                <div className="flex items-center gap-2">
                    <span className="text-lg font-bold">R{totalPrice.toFixed(2)}</span>
                    <ArrowRight size={18} />
                </div>
            </motion.button>
        </div>
      )}
    </div>
  );
};


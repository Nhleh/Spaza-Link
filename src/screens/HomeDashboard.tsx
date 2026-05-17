import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Menu, Bell, ChevronDown, Rocket, Truck, ArrowRight, CheckCircle, Beer, Cookie, Package, Bath, Sandwich, SprayCan, Snowflake, LayoutGrid, X, LogOut, User, History, Settings, HelpCircle, Loader2 } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { cn } from '../lib/utils';
import { auth } from '../lib/firebase';
import { onAuthStateChanged, signOut } from 'firebase/auth';
import { firebaseService } from '../services/firebaseService';
import { apiRequest } from '../lib/apiClient';

export const HomeDashboard: React.FC = () => {
  const navigate = useNavigate();
  const [toast, setToast] = useState<string | null>(null);
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const [userProfile, setUserProfile] = useState<any>(null);
  const [shops, setShops] = useState<any[]>([]);
  const [isShopSelectorOpen, setIsShopSelectorOpen] = useState(false);
  const [isSavingsModalOpen, setIsSavingsModalOpen] = useState(false);
  const [loading, setLoading] = useState(true);
  const [hasUnreadNotifications, setHasUnreadNotifications] = useState(false);

  const activeShop = React.useMemo(() => {
    if (!userProfile?.activeShopId) return shops[0] || null;
    return shops.find((s: any) => s.id === userProfile.activeShopId) || shops[0] || null;
  }, [shops, userProfile?.activeShopId]);

  useEffect(() => {
    let unsubProfile: (() => void) | null = null;
    let unsubShops: (() => void) | null = null;
    let unsubNotifs: (() => void) | null = null;

    const unsubscribeAuth = onAuthStateChanged(auth, async (user) => {
      if (user) {
        try {
          // Fetch user profile via backend
          const profile = await apiRequest('/api/user/profile');
          setUserProfile({ uid: user.uid, ...profile });
          
          // Fetch user's shops via backend
          const shopsList = await apiRequest('/api/data/shops');
          setShops(shopsList);
          
          // Fetch notifications via backend
          const notifs = await apiRequest('/api/data/notifications');
          setHasUnreadNotifications(notifs.some((n: any) => !n.isRead));

        } catch (error) {
          console.error('Error fetching dashboard data:', error);
        } finally {
          setLoading(false);
        }
      } else {
        navigate('/login');
      }
    });

    return () => {
      unsubscribeAuth();
    };
  }, [navigate]);

  const handleLogout = async () => {
    try {
      await signOut(auth);
      navigate('/');
    } catch (error) {
      console.error('Logout failed:', error);
    }
  };

  const showToast = (message: string) => {
    setToast(message);
    setTimeout(() => setToast(null), 3000);
  };

  const handleSwitchShop = async (shop: any) => {
    if (!userProfile) return;
    try {
      await firebaseService.updateDoc('users', userProfile.uid, { 
        activeShopId: shop.id,
        shopName: shop.name,
        location: shop.address
      });
      setIsShopSelectorOpen(false);
      showToast(`Switched to ${shop.name}`);
    } catch (error) {
      console.error('Error switching shop:', error);
      showToast('Failed to switch shop');
    }
  };

  const categories = [
    { name: 'Drinks', img: 'https://www.coca-cola.com/content/dam/onexp/us/en/brands/coca-cola-original/en_coca-cola-original-taste-20-oz_750x750_v1.jpg' },
    { name: 'Snacks', img: 'https://snackboxusa.com/cdn/shop/files/SS13_2024_Main_2.jpg?v=1747761954&width=1080' },
    { name: 'Grocery', img: 'https://www.makro.co.za/asset/rukmini/fccp/832/832/ng-fkpublic-ui-user-fbbe/fmcg-combo/n/k/o/grocery-box-dinner-combo-original-imahh29vzfgzcayr.jpeg?q=70' },
    { name: 'Toiletries', img: 'https://theluckyway.com.au/cdn/shop/collections/toiletry_1200x1200.jpg?v=1589018171' },
    { name: 'Bread', img: 'https://cdn-prd-02.pnp.co.za/sys-master/images/hf1/h51/10868899119134/silo-product-image-v2-08Jun2022-180319-6009518601505-Angle_A-39811-38704_400Wx400H' },
    { name: 'Cleaning', img: 'https://media.takealot.com/covers_images/13954fad65fb4d60a4e3a5d797148a0f/s-pdpxl.file' },
    { name: 'Frozen', img: 'https://img.freepik.com/free-photo/frozen-food-table-arrangement_23-2148969451.jpg' },
    { name: 'More', icon: LayoutGrid, color: 'text-gray-500' },
  ];

  const deals = [
    { name: 'Coca-Cola 2L', price: 'R24.50', oldPrice: 'R26.00', img: 'https://www.coca-cola.com/content/dam/onexp/us/en/brands/coca-cola-original/en_coca-cola-original-taste-20-oz_750x750_v1.jpg' },
    { name: 'Albany Bread', price: 'R15.20', oldPrice: 'R16.50', img: 'https://cdn-prd-02.pnp.co.za/sys-master/images/hf1/h51/10868899119134/silo-product-image-v2-08Jun2022-180319-6009518601505-Angle_A-39811-38704_400Wx400H' },
    { name: 'Sunlight Soap', price: 'R8.90', oldPrice: 'R10.00', img: 'https://media.takealot.com/covers_images/13954fad65fb4d60a4e3a5d797148a0f/s-pdpxl.file' },
    { name: 'Maize Meal 10kg', price: 'R132.00', oldPrice: 'R145.00', img: 'https://www.makro.co.za/asset/rukmini/fccp/832/832/ng-fkpublic-ui-user-fbbe/fmcg-combo/n/k/o/grocery-box-dinner-combo-original-imahh29vzfgzcayr.jpeg?q=70' },
  ];

  if (loading) {
    return (
      <div className="min-h-screen bg-spaza-bg flex items-center justify-center">
        <Loader2 className="animate-spin text-spaza-green" size={32} />
      </div>
    );
  }

  return (
    <div className="min-h-[100dvh] pb-32 bg-spaza-bg">
      {/* Toast Notification */}
      <AnimatePresence>
        {toast && (
          <motion.div
            initial={{ opacity: 0, y: -50 }}
            animate={{ opacity: 1, y: 20 }}
            exit={{ opacity: 0, y: -50 }}
            className="fixed top-0 left-0 right-0 z-50 flex justify-center px-6"
          >
            <div className="px-6 py-3 bg-card-bg border border-spaza-green/20 rounded-2xl shadow-xl flex items-center gap-3">
              <CheckCircle size={18} className="text-spaza-green" />
              <span className="text-xs font-black uppercase tracking-wider text-text-primary">{toast}</span>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Savings Modal */}
      <AnimatePresence>
        {isSavingsModalOpen && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsSavingsModalOpen(false)}
              className="fixed inset-0 bg-black/60 backdrop-blur-md z-[80]"
            />
            <motion.div
              initial={{ y: '100%' }}
              animate={{ y: 0 }}
              exit={{ y: '100%' }}
              transition={{ type: 'spring', damping: 25, stiffness: 200 }}
              className="fixed inset-x-0 bottom-0 bg-card-bg z-[90] rounded-t-[40px] shadow-2xl flex flex-col max-h-[85vh] overflow-hidden"
            >
              <div className="w-12 h-1.5 bg-border-custom rounded-full mx-auto mt-4 mb-2" />
              
              <div className="p-8 pt-4 overflow-y-auto">
                <div className="text-center mb-8">
                  <div className="w-20 h-20 bg-spaza-green/10 rounded-[32px] flex items-center justify-center mx-auto mb-4">
                    <Rocket size={40} className="text-spaza-green" />
                  </div>
                  <h2 className="text-2xl font-black text-text-primary uppercase tracking-tight">Your Savings Breakdown</h2>
                  <p className="text-text-secondary text-sm mt-1">Total saved this month</p>
                  <div className="text-4xl font-black text-spaza-green mt-2 tracking-tighter">R1,245.00</div>
                </div>

                <div className="space-y-4">
                  {[
                    { label: 'Bulk Buy Discounts', description: 'Savings from ordering larger quantities', amount: 'R850.00', icon: Package, color: 'text-blue-500', bg: 'bg-blue-50' },
                    { label: 'Flash Deals', description: 'Savings from daily limited-time offers', amount: 'R245.00', icon: Beer, color: 'text-amber-500', bg: 'bg-amber-50' },
                    { label: 'Free Delivery Savings', description: 'Zero delivery fees on orders over R1500', amount: 'R150.00', icon: Truck, color: 'text-spaza-green', bg: 'bg-green-50' },
                  ].map((item, idx) => (
                    <motion.div 
                      key={idx}
                      initial={{ opacity: 0, x: -20 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ delay: 0.1 * idx }}
                      className="p-5 bg-spaza-bg border border-border-custom rounded-[28px] flex items-center gap-4 group"
                    >
                      <div className={cn("w-12 h-12 rounded-2xl flex items-center justify-center shrink-0", item.bg)}>
                        <item.icon size={24} className={item.color} />
                      </div>
                      <div className="flex-1">
                        <div className="flex justify-between items-start">
                          <h4 className="font-bold text-text-primary uppercase tracking-tight text-xs">{item.label}</h4>
                          <span className="font-black text-spaza-green">{item.amount}</span>
                        </div>
                        <p className="text-[11px] text-text-secondary leading-tight mt-0.5">{item.description}</p>
                      </div>
                    </motion.div>
                  ))}
                  <p className="text-center text-[11px] text-text-secondary font-medium px-4 mt-2">
                    Free doorstep delivery on orders over R1,500. Flat R125 fee otherwise.
                  </p>
                </div>

                <div className="mt-10 p-6 bg-spaza-green rounded-[32px] text-center text-white space-y-3 shadow-lg shadow-spaza-green/20">
                  <p className="text-[10px] font-black uppercase tracking-[0.2em] opacity-80">Pro Tip</p>
                  <h4 className="text-lg font-bold leading-tight">Order by Tuesday to maximize bulk savings!</h4>
                  <button 
                    onClick={() => {
                      setIsSavingsModalOpen(false);
                      navigate('/catalog');
                    }}
                    className="w-full bg-white text-spaza-green font-black py-4 rounded-2xl flex items-center justify-center gap-2 text-sm shadow-sm active:scale-95 transition-all"
                  >
                    Shop Deals Now
                    <ArrowRight size={18} />
                  </button>
                </div>
                
                <button 
                  onClick={() => setIsSavingsModalOpen(false)}
                  className="w-full mt-6 py-4 text-text-secondary font-bold text-sm uppercase tracking-widest active:opacity-60 transition-opacity"
                >
                  Close
                </button>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>

      {/* Sidebar Overlay */}
      <AnimatePresence>
        {isSidebarOpen && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsSidebarOpen(false)}
              className="fixed inset-0 bg-black/40 backdrop-blur-sm z-[60]"
            />
            <motion.div
              initial={{ x: '-100%' }}
              animate={{ x: 0 }}
              exit={{ x: '-100%' }}
              transition={{ type: 'spring', damping: 25, stiffness: 200 }}
              className="fixed inset-y-0 left-0 w-[280px] bg-card-bg z-[70] shadow-2xl flex flex-col pt-4"
            >
              <div className="px-6 mb-8 flex justify-between items-center mt-4">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 bg-spaza-green rounded-2xl flex items-center justify-center text-white font-bold text-xl uppercase">
                    {(userProfile?.ownerName || 'U')[0]}
                  </div>
                  <div>
                    <h3 className="font-bold text-text-primary leading-tight">{userProfile?.shopName || 'My Shop'}</h3>
                    <p className="text-[11px] text-text-secondary">Premium Member</p>
                  </div>
                </div>
                <button onClick={() => setIsSidebarOpen(false)} className="p-2 text-text-secondary">
                  <X size={20} />
                </button>
              </div>

              <nav className="flex-1 px-4 space-y-1">
                {[
                  { icon: User, label: 'My Profile', path: '/profile' },
                  { icon: History, label: 'Order History', path: '/orders-history' },
                  { icon: Bell, label: 'Notifications', path: '/notifications' },
                  { icon: Settings, label: 'Settings', path: '/settings' },
                  { icon: HelpCircle, label: 'Support', path: '/support' },
                ].map((item) => (
                  <button
                    key={item.label}
                    onClick={() => {
                      setIsSidebarOpen(false);
                      navigate(item.path);
                    }}
                    className="w-full flex items-center gap-4 px-4 py-3 text-text-primary font-medium text-sm hover:bg-spaza-bg rounded-xl transition-colors"
                  >
                    <item.icon size={20} className="text-text-secondary" />
                    {item.label}
                  </button>
                ))}
              </nav>

              <div className="p-6 border-t border-border-custom">
                <button
                  onClick={handleLogout}
                  className="w-full flex items-center gap-4 px-4 py-3 text-red-500 font-bold text-sm hover:bg-red-50 rounded-xl transition-colors"
                >
                  <LogOut size={20} />
                  Logout
                </button>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>

      {/* Header Area */}
      <header className="bg-spaza-green p-6 pt-[env(safe-area-inset-top,2rem)] pb-14 relative shadow-lg">
        <div className="flex justify-between items-center relative z-10">
          <button 
            onClick={() => setIsSidebarOpen(true)}
            className="p-1 text-white active:scale-90 transition-transform"
          >
            <Menu size={24} />
          </button>
          
          <div className="flex flex-col items-center">
            <span className="text-white/80 text-[12px] font-medium tracking-wide">Good morning, {(userProfile?.ownerName || 'User').split(' ')[0]}!</span>
            <div 
              onClick={() => setIsShopSelectorOpen(!isShopSelectorOpen)}
              className="flex items-center gap-1 group active:opacity-70 transition-all cursor-pointer relative"
              role="button"
              tabIndex={0}
              onKeyDown={(e) => {
                if (e.key === 'Enter' || e.key === ' ') {
                  setIsShopSelectorOpen(!isShopSelectorOpen);
                }
              }}
            >
              <span className="text-white font-bold text-[14px] tracking-tight">{activeShop?.name || userProfile?.shopName || 'SpazaLink Shop'}</span>
              <ChevronDown size={14} className={cn("text-white/60 transition-transform", isShopSelectorOpen && "rotate-180")} />
              
              {/* Shop Selector Dropdown */}
              <AnimatePresence>
                {isShopSelectorOpen && (
                  <motion.div
                    initial={{ opacity: 0, y: 10, scale: 0.95 }}
                    animate={{ opacity: 1, y: 0, scale: 1 }}
                    exit={{ opacity: 0, y: 10, scale: 0.95 }}
                    className="absolute top-full mt-2 w-56 bg-card-bg rounded-2xl shadow-2xl border border-border-custom z-50 overflow-hidden"
                  >
                    <div className="p-3 border-b border-border-custom bg-spaza-bg/50">
                      <p className="text-[10px] font-black text-text-secondary uppercase tracking-[0.1em]">Your Shops</p>
                    </div>
                    <div className="max-h-60 overflow-y-auto">
                      {shops.length > 0 ? (
                        shops.map((shop) => (
                          <button
                            key={shop.id}
                            onClick={(e) => {
                              e.stopPropagation();
                              handleSwitchShop(shop);
                            }}
                            className={cn(
                              "w-full text-left px-4 py-3 text-xs font-bold transition-all flex items-center justify-between",
                              activeShop?.id === shop.id ? "text-spaza-green bg-spaza-green/5" : "text-text-primary hover:bg-spaza-bg"
                            )}
                          >
                            <span className="truncate pr-2">{shop.name}</span>
                            {activeShop?.id === shop.id && <CheckCircle size={14} />}
                          </button>
                        ))
                      ) : (
                        <div className="px-4 py-3 text-[10px] text-text-secondary italic">No shops found</div>
                      )}
                    </div>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        setIsShopSelectorOpen(false);
                        navigate('/profile', { state: { openAddShop: true } });
                      }}
                      className="w-full text-left px-4 py-3 text-[10px] font-black text-spaza-green uppercase tracking-widest hover:bg-spaza-green/5 transition-all border-t border-border-custom"
                    >
                      + Add New Shop
                    </button>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          </div>

          <button 
            onClick={() => navigate('/notifications')}
            className="relative p-1 active:scale-90 transition-transform"
          >
            <Bell size={24} className="text-white" />
            {hasUnreadNotifications && (
              <span className="absolute top-1 right-1 w-2.5 h-2.5 bg-[#FF4B4B] rounded-full border-2 border-spaza-green" />
            )}
          </button>
        </div>
      </header>

      {/* Main Sections */}
      <div className="px-6 mt-6 flex flex-col space-y-6 relative z-20">
        {/* Savings Card */}
        <motion.div 
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          className="bg-spaza-green-dark rounded-xl p-5 shadow-lg"
        >
          <div className="flex flex-col">
            <p className="text-white/60 text-[13px] font-medium mb-1">You saved</p>
            <h3 className="text-[34px] font-bold text-white mb-2 leading-none">R1,245.00</h3>
            <div className="flex justify-between items-center">
              <p className="text-white text-[14px] font-semibold">this week</p>
              <button 
                onClick={() => setIsSavingsModalOpen(true)}
                className="text-white text-[13px] font-medium flex items-center gap-1"
              >
                View details <span className="text-[14px] font-light opacity-80">›</span>
              </button>
            </div>
          </div>
        </motion.div>

        {/* Next Delivery */}
        <div className="bg-card-bg p-5 rounded-xl shadow-sm flex items-center justify-between border border-border-custom">
          <div className="space-y-1">
            <p className="text-text-secondary text-[12px] font-medium">Next Delivery</p>
            <h4 className="text-text-primary text-[14px] font-bold tracking-tight">Friday, 24 May 2024</h4>
            <p className="text-text-secondary text-[12px] font-semibold">08:00 – 12:00</p>
          </div>
          <div className="w-24 h-16 flex items-center justify-center p-1">
             <img 
               src="https://img.freepik.com/premium-psd/white-box-truck-isolated-background_1409-3462.jpg" 
               alt="truck" 
               className="w-full h-full object-contain" 
               referrerPolicy="no-referrer"
             />
          </div>
        </div>

        {/* Shop Now Categories */}
        <section>
          <div className="flex justify-between items-center mb-4">
            <h3 className="text-sm font-bold text-text-primary tracking-tight">Shop Now</h3>
            <button onClick={() => navigate('/catalog')} className="text-spaza-green text-[11px] font-bold tracking-widest uppercase">View all</button>
          </div>
          <div className="grid grid-cols-4 gap-x-4 gap-y-6">
            {categories.map((cat) => (
              <button 
                key={cat.name}
                onClick={() => navigate('/catalog', { state: { category: cat.name } })}
                className="flex flex-col items-center gap-2 group"
              >
                <div className="w-14 h-14 bg-card-bg rounded-xl shadow-premium flex items-center justify-center border border-border-custom group-active:scale-95 transition-all overflow-hidden p-2">
                  {cat.img ? (
                    <img src={cat.img} alt={cat.name} className="w-full h-full object-contain" referrerPolicy="no-referrer" />
                  ) : (
                    <cat.icon size={20} className={cat.color || "text-text-secondary"} />
                  )}
                </div>
                <span className="text-[10px] font-semibold text-text-secondary tracking-tight">{cat.name}</span>
              </button>
            ))}
          </div>
        </section>

        {/* Top Deals */}
        <section>
          <div className="flex justify-between items-center mb-4">
            <h3 className="text-sm font-bold text-text-primary tracking-tight">Top Deals for You</h3>
            <button onClick={() => navigate('/catalog')} className="text-spaza-green text-[11px] font-bold tracking-widest uppercase">View all</button>
          </div>
          <div className="flex gap-4 overflow-x-auto pb-4 -mx-6 px-6 scrollbar-hide">
            {deals.map((deal) => (
              <div 
                key={deal.name}
                onClick={() => navigate('/catalog')}
                className="min-w-[140px] bg-card-bg p-4 rounded-[28px] shadow-sm border border-border-custom flex flex-col shrink-0 active:scale-98 transition-transform"
              >
                <div className="w-full h-24 flex items-center justify-center p-2 mb-2">
                  <img src={deal.img} alt={deal.name} className="w-full h-full object-contain drop-shadow-sm" />
                </div>
                <h4 className="text-[10px] font-bold text-text-secondary line-through">{deal.oldPrice}</h4>
                <div className="flex justify-between items-end">
                   <span className="text-[15px] font-bold text-text-primary tracking-tighter">{deal.price}</span>
                   <span className="text-[10px] font-semibold text-text-secondary">2L</span>
                </div>
                <h5 className="text-[11px] font-bold text-text-primary mt-1 leading-tight">{deal.name}</h5>
              </div>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
};


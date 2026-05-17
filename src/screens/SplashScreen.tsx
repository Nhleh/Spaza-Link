import React from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'motion/react';
import { MessageCircle } from 'lucide-react';

export const SplashScreen: React.FC = () => {
  const navigate = useNavigate();

  return (
    <div className="relative min-h-[100dvh] w-full overflow-hidden bg-[#0A1A14] flex flex-col items-center justify-between pt-[env(safe-area-inset-top,2rem)] pb-8 px-8">
      {/* Background Storefront Image (Bottom) */}
      <div 
        className="absolute bottom-0 left-0 right-0 h-2/3 opacity-40 bg-cover bg-top bg-no-repeat"
        style={{ backgroundImage: 'url("https://images.unsplash.com/photo-1534723452862-4c874018d66d?auto=format&fit=crop&q=80&w=1000")' }}
      >
        <div className="absolute inset-0 bg-gradient-to-t from-[#0A1A14] via-transparent to-[#0A1A14]" />
      </div>

      {/* Top Section: Logo & Slogan */}
      <motion.div 
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        className="relative z-10 flex flex-col items-center"
      >
        <div className="flex flex-col items-center">
             <div className="w-16 h-16 bg-transparent flex items-center justify-center mb-2">
                <svg width="60" height="60" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <path d="M3 3H5L5.4 5M5.4 5H21L19 13H7M5.4 5L7 13M7 13L4.707 15.293C4.077 15.923 4.523 17 5.414 17H19" stroke="#F5C400" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  <path d="M9 20C9 20.5523 8.55228 21 8 21C7.44772 21 7 20.5523 7 20C7 19.4477 7.44772 19 8 19C8.55228 19 9 19.4477 9 20Z" fill="#F5C400"/>
                  <path d="M20 20C20 20.5523 19.5523 21 19 21C18.4477 21 18 20.5523 18 20C18 19.4477 18.4477 19 19 19C19.5523 19 20 19.4477 20 20Z" fill="#F5C400"/>
                </svg>
             </div>
             <h1 className="text-4xl font-extrabold text-white tracking-tighter">
               Spaza<span className="text-spaza-yellow">Link</span>
             </h1>
        </div>
        <div className="mt-4 text-center">
          <p className="text-white text-sm font-semibold tracking-wide">Stronger together.</p>
          <p className="text-white text-sm font-semibold tracking-wide">Cheaper together.</p>
        </div>
      </motion.div>

      {/* Middle Spacer */}
      <div className="flex-1" />

      {/* Bottom Section: Text & Buttons */}
      <motion.div 
        initial={{ opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.3 }}
        className="relative z-10 w-full flex flex-col items-center space-y-6"
      >
        <div className="text-center px-4">
          <p className="text-white text-sm font-medium leading-relaxed">
            Bulk buying power.<br />
            Better prices. Delivery at your doorstep.
          </p>
        </div>

        <div className="w-full space-y-3">
          <button 
            onClick={() => navigate('/login')}
            className="w-full bg-spaza-green hover:bg-spaza-green-dark text-white font-bold py-4.5 rounded-xl shadow-lg shadow-black/10 transition-all active:scale-95"
          >
            Login
          </button>
          <button 
            onClick={() => navigate('/register')}
            className="w-full bg-transparent border-[4px] border-white/20 hover:border-white/40 text-white font-bold py-4.5 rounded-xl shadow-lg transition-all active:scale-95"
          >
            Register Your Shop
          </button>
        </div>
        
        <div className="text-center">
            <motion.button 
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              onClick={() => window.open('https://wa.me/27812345678', '_blank')}
              className="group flex items-center gap-2 mx-auto text-white/60 text-[11px] hover:text-white transition-all"
            >
                <div className="w-1.5 h-1.5 bg-spaza-green rounded-full animate-pulse" />
                <span>Need help? <span className="text-spaza-green font-bold group-hover:text-spaza-yellow transition-colors">Contact us on WhatsApp</span></span>
            </motion.button>
        </div>
      </motion.div>
    </div>
  );
};

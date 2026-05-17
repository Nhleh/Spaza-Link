import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, MessageCircle, Phone, ChevronDown, ChevronUp } from 'lucide-react';

export const SupportScreen: React.FC = () => {
  const navigate = useNavigate();
  const [openFaq, setOpenFaq] = useState<number | null>(null);

  const faqs = [
    { q: 'How do I place an order?', a: 'To place an order, go to the Shop tab, add items to your cart, and proceed to checkout.' },
    { q: 'What are the delivery times?', a: 'We deliver Monday to Friday, 08:00 - 17:00. Orders placed before 12:00 are usually delivered next day.' },
    { q: 'How do payments work?', a: 'You can pay on delivery (cash/card), via EFT, or securely via the app using your credit/debit card.' },
    { q: 'Can I return an item?', a: 'Yes, items can be returned within 48 hours if they are damaged or incorrect.' },
  ];

  return (
    <div className="min-h-[100dvh] bg-spaza-bg flex flex-col pt-0">
      <header className="px-6 pt-[env(safe-area-inset-top,2rem)] flex items-center mb-8 gap-4">
        <button onClick={() => navigate(-1)} className="w-10 h-10 bg-card-bg rounded-xl shadow-sm border border-border-custom flex items-center justify-center active:scale-95 transition-transform">
            <ArrowLeft size={20} className="text-spaza-green" />
        </button>
        <h2 className="text-xl font-bold text-text-primary">Help & Support</h2>
      </header>

      <div className="px-6 space-y-8 pb-24 overflow-y-auto flex-1">
        <div className="text-center py-6">
            <h3 className="text-xl font-bold text-text-primary mb-2">Need Help?</h3>
            <p className="text-text-secondary text-sm">We're here for you.</p>
        </div>

        <div className="space-y-4">
            <button 
                onClick={() => window.open('https://wa.me/27812345678', '_blank')}
                className="w-full bg-spaza-green text-white font-bold py-5 rounded-2xl flex items-center justify-center gap-3 shadow-lg shadow-spaza-green/20 active:scale-95 transition-all"
            >
                <MessageCircle size={24} fill="white" />
                Chat on WhatsApp
            </button>
            <button className="w-full bg-card-bg border border-border-custom text-text-primary font-bold py-5 rounded-2xl flex flex-col items-center justify-center gap-2 active:scale-95 transition-all">
                <div className="flex items-center gap-3">
                    <Phone size={20} className="text-spaza-green" />
                    Call Support
                </div>
                <span className="text-lg text-text-primary">031 123 4567</span>
            </button>
        </div>

        <section className="space-y-4">
            <h4 className="text-xs font-bold text-text-secondary uppercase tracking-wider">Frequently Asked Questions</h4>
            <div className="space-y-3">
                {faqs.map((faq, idx) => (
                    <div key={idx} className="bg-card-bg rounded-2xl border border-border-custom shadow-sm overflow-hidden">
                        <button 
                            onClick={() => setOpenFaq(openFaq === idx ? null : idx)}
                            className="w-full px-5 py-4 flex items-center justify-between text-left"
                        >
                            <span className="text-xs font-bold text-text-primary">{faq.q}</span>
                            {openFaq === idx ? <ChevronUp size={16} className="text-text-secondary" /> : <ChevronDown size={16} className="text-text-secondary" />}
                        </button>
                        {openFaq === idx && (
                            <div className="px-5 pb-5 text-[10px] leading-relaxed text-text-secondary">
                                {faq.a}
                            </div>
                        )}
                    </div>
                ))}
            </div>
        </section>
      </div>
    </div>
  );
};

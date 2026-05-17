import React from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, Shield, Eye, Lock, Database, UserCheck } from 'lucide-react';

export const PrivacyPolicyScreen: React.FC = () => {
  const navigate = useNavigate();

  const sections = [
    {
      icon: Database,
      title: 'Information We Collect',
      content: 'We collect information you provide directly to us when you register your shop, including your shop name, owner name, physical address for deliveries, and contact details. We also collect transaction data related to your orders to improve our bulk inventory services.'
    },
    {
      icon: Eye,
      title: 'How We Use Your Data',
      content: 'Your data is used primarily to process and deliver your orders accurately. We also use your purchase history to provide data-driven insights on savings and to suggest categories you might need. We do not sell your personal data to third parties.'
    },
    {
      icon: TruckIcon, // Using a fallback since Truck is imported in Terms but let's just use local icons
      title: 'Sharing with Partners',
      content: 'We share your delivery address and contact person details with our logistics partners to ensure your bulk stock reaches your SpazaLink shop on time. These partners are contractually obligated to protect your data and use it only for delivery purposes.'
    },
    {
      icon: Lock,
      title: 'Security Measures',
      content: 'We implement industry-standard security measures to protect your information from unauthorized access, including encryption for data in transit and secure storage for your payment method details through our PCI-compliant processing partners.'
    },
    {
      icon: UserCheck,
      title: 'Your Rights & Control',
      content: 'You have the right to access, update, or delete your shop profile at any time. You can also manage your notification preferences in the Settings screen to control how we communicate with you regarding deals and order status.'
    }
  ];

  return (
    <div className="min-h-[100dvh] bg-spaza-bg flex flex-col pt-0">
      <header className="px-6 pt-[env(safe-area-inset-top,2rem)] flex items-center mb-8 gap-4">
        <button 
          onClick={() => navigate(-1)} 
          className="w-10 h-10 bg-card-bg rounded-xl shadow-sm border border-border-custom flex items-center justify-center active:scale-95 transition-transform"
        >
          <ArrowLeft size={20} className="text-spaza-green" />
        </button>
        <h2 className="text-xl font-bold text-text-primary">Privacy Policy</h2>
      </header>

      <div className="flex-1 overflow-y-auto px-6 pb-20 space-y-6">
        <div className="bg-spaza-green/10 p-6 rounded-3xl border border-spaza-green/10">
          <h1 className="text-lg font-black text-spaza-green-dark uppercase tracking-tight mb-2">Our Commitment</h1>
          <p className="text-sm text-text-primary leading-relaxed font-medium">
            At SpazaLink, we respect your privacy and are committed to protecting the personal and business data you share with us while stocking your shop.
          </p>
        </div>

        {sections.map((section, idx) => (
          <div key={idx} className="bg-card-bg p-6 rounded-3xl border border-border-custom shadow-sm space-y-3">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-spaza-bg rounded-xl flex items-center justify-center text-spaza-green">
                {section.icon ? <section.icon size={20} /> : <Shield size={20} />}
              </div>
              <h3 className="font-bold text-text-primary">{section.title}</h3>
            </div>
            <p className="text-sm text-text-secondary leading-relaxed font-medium">
              {section.content}
            </p>
          </div>
        ))}

        <div className="text-center pt-8">
          <p className="text-[10px] text-text-secondary font-bold uppercase tracking-widest leading-loose">
            Privacy Policy Last Updated: May 2024<br/>
            © 2024 SpazaLink (Pty) Ltd
          </p>
        </div>
      </div>
    </div>
  );
};

// Simple internal Truck for consistency if needed
const TruckIcon = ({ size }: { size: number }) => (
  <svg 
    xmlns="http://www.w3.org/2000/svg" 
    width={size} 
    height={size} 
    viewBox="0 0 24 24" 
    fill="none" 
    stroke="currentColor" 
    strokeWidth="2" 
    strokeLinecap="round" 
    strokeLinejoin="round"
  >
    <path d="M14 18V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v11a1 1 0 0 0 1 1h2" />
    <path d="M15 18H9" />
    <path d="M19 18h2a1 1 0 0 0 1-1v-5l-4-4h-3a2 2 0 0 0-2 2v12" />
    <circle cx="7" cy="18" r="2" />
    <circle cx="17" cy="18" r="2" />
  </svg>
);

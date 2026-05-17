import React from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, Shield, Info, Truck, Scale, AlertCircle } from 'lucide-react';

export const TermsScreen: React.FC = () => {
  const navigate = useNavigate();

  const sections = [
    {
      icon: Truck,
      title: 'Delivery & Shipping',
      content: 'Delivery at your doorstep is included for all orders of R1,500 and above. For orders below this threshold, a flat service fee of R125 will be applied at checkout. Delivery timelines vary by location but typically range from 24 to 48 hours.'
    },
    {
      icon: Scale,
      title: 'Business Requirements',
      content: 'This application is exclusively for registered SpazaLink shop owners and small businesses. Users may be required to provide valid business identification or trade references upon registration or order placement.'
    },
    {
      icon: Info,
      title: 'Product Availability',
      content: 'Prices and availability are subject to change without notice. In the event of a stock shortage, we reserve the right to offer substitutes of equal or greater value, or issue a refund for the missing items.'
    },
    {
      icon: AlertCircle,
      title: 'Cancellations & Returns',
      content: 'Orders can only be cancelled within 1 hour of placement. Perishable goods cannot be returned once delivered and signed for. Non-perishable items may be returned within 7 days if they remain in their original, unopened packaging.'
    },
    {
      icon: Shield,
      title: 'Payment Terms',
      content: 'We support Cash on Delivery (COD) for verified accounts. New accounts may be required to pay via Card or Instant EFT for their first three orders. Payments must be settled in full before goods are offloaded.'
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
        <h2 className="text-xl font-bold text-text-primary">Terms of Service</h2>
      </header>

      <div className="flex-1 overflow-y-auto px-6 pb-20 space-y-6">
        <div className="bg-spaza-green/10 p-6 rounded-3xl border border-spaza-green/10">
          <h1 className="text-lg font-black text-spaza-green-dark uppercase tracking-tight mb-2">Important Notice</h1>
          <p className="text-sm text-text-primary leading-relaxed font-medium">
            Please read these terms carefully before using our bulk inventory services. By placing an order, you agree to be bound by these legal conditions.
          </p>
        </div>

        {sections.map((section, idx) => (
          <div key={idx} className="bg-card-bg p-6 rounded-3xl border border-border-custom shadow-sm space-y-3">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-spaza-bg rounded-xl flex items-center justify-center text-spaza-green">
                <section.icon size={20} />
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
            Last Updated: May 2024<br/>
            © 2024 SpazaLink (Pty) Ltd
          </p>
        </div>
      </div>
    </div>
  );
};

import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, Rocket, Database, CheckCircle, AlertCircle, Loader2 } from 'lucide-react';
import { apiRequest } from '../lib/apiClient';

export const AdminDashboard: React.FC = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  const seedProducts = async () => {
    setLoading(true);
    setStatus(null);
    try {
      const sampleProducts = [
        {
          id: 'prod-001',
          name: 'Coca-Cola 2L',
          description: 'Original Taste Carbonated Soft Drink',
          price: 24.50,
          category: 'Drinks',
          unit: '1x2L Bottle',
          stock: 500,
          img: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&q=80&w=400'
        },
        {
          id: 'prod-002',
          name: 'Albany Superior White Bread',
          description: 'Fresh sliced superior white bread 700g',
          price: 15.20,
          category: 'Bread',
          unit: '1x700g Loaf',
          stock: 200,
          img: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&q=80&w=400'
        },
        {
          id: 'prod-003',
          name: 'Sunlight Dishwashing Liquid',
          description: 'Original Lemon 750ml',
          price: 28.90,
          category: 'Cleaning',
          unit: '1x750ml Bottle',
          stock: 300,
          img: 'https://images.unsplash.com/photo-1584622781564-1d987f7333c1?auto=format&fit=crop&q=80&w=400'
        },
        {
          id: 'prod-004',
          name: 'Lucky Star Pilchards',
          description: 'Pilchards in Tomato Sauce 400g',
          price: 22.00,
          category: 'Grocery',
          unit: '1x400g Can',
          stock: 450,
          img: 'https://images.unsplash.com/photo-1534483507429-1f9d82c71942?auto=format&fit=crop&q=80&w=400'
        }
      ];

      await apiRequest('/api/products/seed', {
        method: 'POST',
        body: JSON.stringify({ products: sampleProducts })
      });

      setStatus({ message: 'Products seeded successfully!', type: 'success' });
    } catch (error: any) {
      console.error('Seeding failed:', error);
      setStatus({ 
        message: error.status === 403 ? 'Access Denied: You must be an Admin' : 'Failed to seed products', 
        type: 'error' 
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-spaza-bg pb-20">
      <header className="bg-spaza-green pt-12 pb-6 px-6 flex items-center gap-4 text-white shadow-lg">
        <button onClick={() => navigate('/home')} className="p-2 hover:bg-white/10 rounded-xl transition-colors">
          <ArrowLeft size={24} />
        </button>
        <h1 className="text-xl font-bold">Admin Console</h1>
      </header>

      <div className="p-6 space-y-6">
        <div className="bg-white p-6 rounded-[32px] shadow-premium border border-border-custom">
          <div className="flex items-center gap-4 mb-6">
            <div className="w-12 h-12 bg-spaza-yellow/10 rounded-2xl flex items-center justify-center text-spaza-yellow">
              <Rocket size={24} />
            </div>
            <div>
              <h2 className="text-lg font-bold text-text-primary">Direct Data Operations</h2>
              <p className="text-xs text-text-secondary">Perform bulk database operations</p>
            </div>
          </div>

          <div className="space-y-4">
            <button 
              onClick={seedProducts}
              disabled={loading}
              className="w-full flex items-center justify-between p-4 bg-spaza-bg border border-border-custom rounded-2xl active:scale-[0.98] transition-all hover:border-spaza-green group"
            >
              <div className="flex items-center gap-4">
                <div className="w-10 h-10 bg-white rounded-xl flex items-center justify-center text-text-secondary group-hover:text-spaza-green transition-colors">
                  <Database size={20} />
                </div>
                <div className="text-left">
                  <h4 className="text-sm font-bold text-text-primary uppercase tracking-tight">Seed Sample Products</h4>
                  <p className="text-[10px] text-text-secondary">Initialize the catalog with base data</p>
                </div>
              </div>
              {loading ? <Loader2 className="animate-spin text-spaza-green" size={20} /> : <Rocket size={20} className="text-spaza-green opacity-0 group-hover:opacity-100 transition-opacity" />}
            </button>

            {status && (
              <div className={`p-4 rounded-2xl flex items-center gap-3 ${
                status.type === 'success' ? 'bg-green-50 text-green-700 border border-green-100' : 'bg-red-50 text-red-700 border border-red-100'
              }`}>
                {status.type === 'success' ? <CheckCircle size={18} /> : <AlertCircle size={18} />}
                <span className="text-xs font-bold">{status.message}</span>
              </div>
            )}
          </div>
        </div>

        <div className="bg-white p-6 rounded-[32px] shadow-premium border border-border-custom">
          <h3 className="text-xs font-black uppercase text-text-secondary tracking-widest mb-4">Security Notice</h3>
          <p className="text-xs text-text-secondary leading-relaxed">
            This dashboard is protected by server-side <strong>Role-Based Access Control (RBAC)</strong>. 
            Even if the UI is accessed, only users with the <code className="bg-spaza-bg px-1 rounded text-spaza-green px-1">admin</code> role in Firestore can execute these operations.
          </p>
        </div>
      </div>
    </div>
  );
};

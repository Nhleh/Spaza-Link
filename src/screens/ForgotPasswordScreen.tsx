import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, Mail, Loader2, CheckCircle } from 'lucide-react';
import { sendPasswordResetEmail } from 'firebase/auth';
import { auth } from '../lib/firebase';

export const ForgotPasswordScreen: React.FC = () => {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const handleResetPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    
    try {
      await sendPasswordResetEmail(auth, email);
      setSuccess(true);
    } catch (err: any) {
      if (err.code === 'auth/user-not-found') {
        setError('No user found with this email address.');
      } else {
        setError(err.message || 'Failed to send reset email.');
      }
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-spaza-bg flex flex-col px-6 py-12">
      <button onClick={() => navigate(-1)} className="mb-8 w-10 h-10 bg-card-bg rounded-xl border border-border-custom flex items-center justify-center">
        <ArrowLeft size={20} className="text-text-primary" />
      </button>

      <div className="mb-10">
        <h2 className="text-2xl font-bold text-text-primary mb-2">Reset Password</h2>
        <p className="text-text-secondary">Enter your email and we'll send you a link to reset your password.</p>
      </div>

      {error && (
        <div className="mb-4 p-4 bg-red-500/10 border border-red-500/20 text-red-500 text-sm rounded-xl font-medium">
          {error}
        </div>
      )}

      {success ? (
        <div className="flex-1 flex flex-col items-center justify-center text-center space-y-6">
          <div className="w-20 h-20 bg-green-500/10 rounded-full flex items-center justify-center">
            <CheckCircle size={40} className="text-spaza-green" />
          </div>
          <div className="space-y-2">
            <h3 className="text-xl font-bold text-text-primary">Email Sent!</h3>
            <p className="text-text-secondary">Check your inbox for the reset link.</p>
          </div>
          <button 
            onClick={() => navigate('/login')}
            className="w-full bg-spaza-green hover:bg-spaza-green-dark text-white font-bold py-4.5 rounded-xl shadow-lg shadow-black/10 transition-all active:scale-95"
          >
            Back to Login
          </button>
        </div>
      ) : (
        <form onSubmit={handleResetPassword} className="space-y-6 flex-1">
          <div className="space-y-2">
            <label className="text-sm font-semibold text-text-primary flex items-center gap-2">
              <span className="p-2 bg-card-bg border border-border-custom rounded-lg"><Mail size={16} className="text-text-secondary" /></span>
              Email Address
            </label>
            <input 
              type="email"
              required
              placeholder="Enter your email"
              className="w-full bg-card-bg border border-border-custom rounded-xl px-4 py-4 focus:ring-2 focus:ring-spaza-green focus:border-transparent outline-none transition-all text-text-primary placeholder:text-text-secondary"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
          </div>

          <button 
            type="submit"
            disabled={loading}
            className="w-full bg-spaza-green hover:bg-spaza-green-dark text-white font-bold py-4.5 rounded-xl shadow-lg shadow-black/10 transition-all active:scale-95 flex items-center justify-center gap-2"
          >
            {loading ? <Loader2 className="animate-spin" size={20} /> : 'Send Reset Link'}
          </button>
        </form>
      )}
    </div>
  );
};

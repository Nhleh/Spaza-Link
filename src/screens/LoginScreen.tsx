import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'motion/react';
import { Eye, EyeOff, MessageCircle, ArrowLeft, Mail, Lock, Loader2 } from 'lucide-react';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { auth } from '../lib/firebase';

export const LoginScreen: React.FC = () => {
  const navigate = useNavigate();
  const [showPassword, setShowPassword] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    
    try {
      await signInWithEmailAndPassword(auth, email, password);
      navigate('/home');
    } catch (err: any) {
      if (err.code === 'auth/user-not-found' || err.code === 'auth/wrong-password' || err.code === 'auth/invalid-credential') {
        setError('Invalid email or password.');
      } else if (err.code === 'auth/operation-not-allowed') {
        setError('Login is currently disabled. Please enable Email/Password in the Firebase Console.');
      } else {
        setError(err.message || 'Login failed. Please check your credentials.');
      }
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-[100dvh] bg-spaza-bg flex flex-col px-6 pt-[env(safe-area-inset-top,1.5rem)] pb-8">
      <button onClick={() => navigate(-1)} className="mb-8 w-10 h-10 bg-card-bg rounded-xl border border-border-custom flex items-center justify-center">
        <ArrowLeft size={20} className="text-text-primary" />
      </button>

      <div className="mb-10">
        <h2 className="text-2xl font-bold text-text-primary mb-2">Welcome Back!</h2>
        <p className="text-text-secondary">Login to your SpazaLink account</p>
      </div>

      {error && (
        <div className="mb-4 p-4 bg-red-500/10 border border-red-500/20 text-red-500 text-sm rounded-xl font-medium">
          {error}
        </div>
      )}

      <form onSubmit={handleLogin} className="space-y-6 flex-1">
        <div className="space-y-2">
          <label className="text-sm font-semibold text-text-primary flex items-center gap-2">
            <span className="p-2 bg-card-bg border border-border-custom rounded-lg"><Mail size={16} className="text-text-secondary" /></span>
            Email Address
          </label>
          <input 
            type="email"
            required
            placeholder="Enter your email"
            className="w-full bg-card-bg border border-border-custom rounded-xl px-4 py-4 focus:ring-2 focus:ring-spaza-green focus:border-transparent outline-none transition-all text-text-primary"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />
        </div>

        <div className="space-y-2">
          <label className="text-sm font-semibold text-text-primary flex items-center gap-2">
            <span className="p-2 bg-card-bg border border-border-custom rounded-lg"><Lock size={16} className="text-text-secondary" /></span>
            Password
          </label>
          <div className="relative">
            <input 
              type={showPassword ? "text" : "password"}
              required
              placeholder="Enter your password"
              className="w-full bg-card-bg border border-border-custom rounded-xl px-4 py-4 focus:ring-2 focus:ring-spaza-green focus:border-transparent outline-none transition-all text-text-primary"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
            <button 
              type="button"
              onClick={() => setShowPassword(!showPassword)}
              className="absolute right-4 top-1/2 -translate-y-1/2 text-text-secondary"
            >
              {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
            </button>
          </div>
          <div className="text-right">
            <button 
              type="button" 
              onClick={() => navigate('/forgot-password')}
              className="text-xs font-bold text-text-secondary hover:text-spaza-green"
            >
              Forgot password?
            </button>
          </div>
        </div>

        <button 
          type="submit"
          disabled={loading}
          className="w-full bg-spaza-green hover:bg-spaza-green-dark text-white font-bold py-4.5 rounded-xl shadow-lg shadow-black/10 transition-all active:scale-95 flex items-center justify-center gap-2"
        >
          {loading ? <Loader2 className="animate-spin" size={20} /> : 'Login'}
        </button>

        <div className="relative flex items-center justify-center py-4">
          <div className="absolute inset-0 flex items-center"><div className="w-full border-t border-border-custom"></div></div>
          <span className="relative px-4 bg-spaza-bg text-xs font-bold text-text-secondary uppercase tracking-widest leading-none">OR</span>
        </div>

        <button 
          type="button"
          onClick={() => window.open('https://wa.me/27123456789', '_blank')}
          className="w-full border-2 border-spaza-green text-spaza-green font-bold py-4.5 rounded-xl flex items-center justify-center gap-2 hover:bg-spaza-green/5 transition-all active:scale-95"
        >
          <MessageCircle size={20} className="fill-spaza-green" />
          Support via WhatsApp
        </button>
      </form>

      <div className="mt-auto text-center pt-8">
        <p className="text-text-secondary text-sm">
          Don't have an account? <button onClick={() => navigate('/register')} className="text-spaza-green font-bold">Register</button>
        </p>
      </div>
    </div>
  );
};

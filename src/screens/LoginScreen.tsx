import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'motion/react';
import { Eye, EyeOff, MessageCircle, ArrowLeft, Mail, Lock, Loader2 } from 'lucide-react';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { auth } from '../lib/firebase';
import { useAuth } from '../context/AuthContext';

export const LoginScreen: React.FC = () => {
  const navigate = useNavigate();
  const { signInWithGoogle } = useAuth();
  const [showPassword, setShowPassword] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [googleLoading, setGoogleLoading] = useState(false);
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

  const handleGoogleSignIn = async () => {
    setGoogleLoading(true);
    setError(null);
    try {
      await signInWithGoogle();
      navigate('/home');
    } catch (err: any) {
      setError(err.message || 'Google sign in failed');
      console.error(err);
    } finally {
      setGoogleLoading(false);
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
          disabled={loading || googleLoading}
          className="w-full bg-spaza-green hover:bg-spaza-green-dark text-white font-bold py-4.5 rounded-xl shadow-lg shadow-black/10 transition-all active:scale-95 flex items-center justify-center gap-2 disabled:opacity-50"
        >
          {loading ? <Loader2 className="animate-spin" size={20} /> : 'Login'}
        </button>

        <div className="relative flex items-center justify-center py-4">
          <div className="absolute inset-0 flex items-center"><div className="w-full border-t border-border-custom"></div></div>
          <span className="relative px-4 bg-spaza-bg text-xs font-bold text-text-secondary uppercase tracking-widest leading-none">OR</span>
        </div>

        <div className="grid grid-cols-1 gap-4">
          <button 
            type="button"
            onClick={handleGoogleSignIn}
            disabled={loading || googleLoading}
            className="w-full bg-white border border-border-custom text-text-primary font-bold py-4.5 rounded-xl flex items-center justify-center gap-3 hover:bg-spaza-bg transition-all active:scale-95 disabled:opacity-50 shadow-sm"
          >
            {googleLoading ? (
              <Loader2 className="animate-spin" size={20} />
            ) : (
              <>
                <svg width="20" height="20" viewBox="0 0 24 24">
                  <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
                  <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-1 .67-2.28 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
                  <path d="M5.84 14.09c-.22-.67-.35-1.39-.35-2.09s.13-1.42.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z" fill="#FBBC05"/>
                  <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
                </svg>
                Sign in with Google
              </>
            )}
          </button>

          <button 
            type="button"
            onClick={() => window.open('https://wa.me/27123456789', '_blank')}
            className="w-full border-2 border-spaza-green text-spaza-green font-bold py-4.5 rounded-xl flex items-center justify-center gap-2 hover:bg-spaza-green/5 transition-all active:scale-95 shadow-sm"
          >
            <MessageCircle size={20} className="fill-spaza-green" />
            Support via WhatsApp
          </button>
        </div>
      </form>

      <div className="mt-auto text-center pt-8">
        <p className="text-text-secondary text-sm">
          Don't have an account? <button onClick={() => navigate('/register')} className="text-spaza-green font-bold">Register</button>
        </p>
      </div>
    </div>
  );
};

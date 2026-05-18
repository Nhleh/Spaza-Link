import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Camera, ArrowLeft, Store, User, Phone, Lock, MapPin, Mail, Loader2, CheckCircle } from 'lucide-react';
import { createUserWithEmailAndPassword, sendEmailVerification, updateProfile } from 'firebase/auth';
import { auth } from '../lib/firebase';
import { firebaseService } from '../services/firebaseService';
import { apiRequest } from '../lib/apiClient';
import { useAuth } from '../context/AuthContext';

export const RegisterScreen: React.FC = () => {
  const navigate = useNavigate();
  const { signInWithGoogle } = useAuth();
  const [loading, setLoading] = useState(false);
  const [googleLoading, setGoogleLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [photoBase64, setPhotoBase64] = useState<string | null>(null);
  
  const [formData, setFormData] = useState({
    shopName: '',
    firstName: '',
    lastName: '',
    phone: '',
    email: '',
    password: '',
    location: '',
    lat: 0,
    lng: 0
  });

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (file.size > 1024 * 1024) { // 1MB limit for firestore document size
        setError('Image is too large. Please select an image under 1MB.');
        return;
      }
      const reader = new FileReader();
      reader.onloadend = () => {
        setPhotoBase64(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.location) {
      setError('Please select your shop location');
      return;
    }
    setLoading(true);
    setError(null);

    try {
      // 1. Create Auth User
      const userCredential = await createUserWithEmailAndPassword(auth, formData.email, formData.password);
      const user = userCredential.user;

      const fullName = `${formData.firstName} ${formData.lastName}`.trim();

      // 2. Update Profile Display Name (Fallback)
      await updateProfile(user, {
        displayName: fullName
      });

      // 3. Send Verification Email
      await sendEmailVerification(user);

      // 4. Create User Profile in Firestore
      const token = await user.getIdToken();
      await apiRequest('/api/user/profile', {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          uid: user.uid,
          email: formData.email,
          shopName: formData.shopName,
          ownerName: fullName,
          firstName: formData.firstName,
          lastName: formData.lastName,
          phone: formData.phone,
          location: formData.location,
          lat: formData.lat,
          lng: formData.lng,
          photoUrl: photoBase64,
          createdAt: new Date().toISOString()
        })
      });

      setSuccess(true);
      setTimeout(() => navigate('/login'), 3000);
    } catch (err: any) {
      if (err.code === 'auth/email-already-in-use') {
        setError('This email is already registered. Please try logging in instead.');
      } else if (err.code === 'auth/operation-not-allowed') {
        setError('Email/Password registration is not enabled. Please enable it in the Firebase Console.');
      } else if (err.code === 'auth/weak-password') {
        setError('Password should be at least 6 characters.');
      } else {
        setError(err.message || 'Registration failed');
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
    <div className="min-h-screen bg-spaza-bg w-full overflow-x-hidden">
      <div className="max-w-md mx-auto flex flex-col px-4 pt-[env(safe-area-inset-top,1.5rem)] pb-8">
        <button onClick={() => navigate(-1)} className="mb-3 w-10 h-10 bg-card-bg rounded-xl border border-border-custom flex items-center justify-center shrink-0">
          <ArrowLeft size={20} className="text-text-primary" />
        </button>

        <div className="mb-4">
          <h2 className="text-2xl font-bold text-text-primary mb-0.5">Create Account</h2>
          <p className="text-text-secondary text-xs">Join SpazaLink for premium local deals</p>
        </div>

        {error && (
          <div className="mb-3 p-3 bg-red-500/10 border border-red-500/20 text-red-500 text-xs rounded-lg font-medium">
            {error}
          </div>
        )}

        {success && (
          <div className="mb-3 p-3 bg-green-500/10 border border-green-500/20 text-green-600 text-xs rounded-lg font-medium">
            Registration successful! Redirecting...
          </div>
        )}

        <button 
          type="button"
          onClick={handleGoogleSignIn}
          disabled={loading || googleLoading}
          className="w-full bg-white border border-border-custom text-text-primary font-bold py-3.5 rounded-xl flex items-center justify-center gap-3 hover:bg-spaza-bg transition-all active:scale-95 disabled:opacity-50 shadow-sm mb-4 text-sm"
        >
          {googleLoading ? (
            <Loader2 className="animate-spin" size={18} />
          ) : (
            <>
              <svg width="18" height="18" viewBox="0 0 24 24">
                <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
                <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-1 .67-2.28 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
                <path d="M5.84 14.09c-.22-.67-.35-1.39-.35-2.09s.13-1.42.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z" fill="#FBBC05"/>
                <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
              </svg>
              Register with Google
            </>
          )}
        </button>

        <div className="relative flex items-center justify-center mb-6">
          <div className="absolute inset-0 flex items-center"><div className="w-full border-t border-border-custom"></div></div>
          <span className="relative px-3 bg-spaza-bg text-[10px] font-bold text-text-secondary uppercase tracking-widest leading-none">OR USE EMAIL</span>
        </div>

        <div className="flex flex-col items-center mb-6">
          <label className="w-full">
            <div className="w-full aspect-[21/9] bg-card-bg rounded-2xl border-2 border-dashed border-border-custom flex flex-col items-center justify-center gap-1 cursor-pointer hover:bg-spaza-bg transition-all overflow-hidden relative">
              {photoBase64 ? (
                <img src={photoBase64} alt="Shop" className="w-full h-full object-cover" />
              ) : (
                <>
                  <Camera size={24} className="text-text-secondary opacity-30" />
                  <span className="text-[10px] font-bold text-text-secondary uppercase tracking-widest">Shop Photo (Optional)</span>
                </>
              )}
            </div>
            <input type="file" accept="image/*" className="hidden" onChange={handleFileChange} />
          </label>
        </div>

        <form className="space-y-3" onSubmit={handleRegister}>
          <div className="space-y-3">
            <h3 className="text-[11px] font-bold text-text-primary uppercase tracking-wider">Business Details</h3>
            
            <div className="flex items-center gap-3 bg-card-bg border border-border-custom rounded-xl px-4 py-2.5 focus-within:ring-2 focus-within:ring-spaza-green transition-all">
              <Store size={18} className="text-text-secondary" />
              <input 
                type="text" 
                required
                value={formData.shopName}
                onChange={(e) => setFormData({...formData, shopName: e.target.value})}
                placeholder="Shop Name" 
                className="bg-transparent outline-none flex-1 text-sm font-medium text-text-primary placeholder:text-text-secondary w-full" 
              />
            </div>

            <div className="flex flex-col sm:flex-row gap-3">
              <div className="flex-1 flex items-center gap-3 bg-card-bg border border-border-custom rounded-xl px-4 py-2.5 focus-within:ring-2 focus-within:ring-spaza-green transition-all min-w-0">
                <User size={18} className="text-text-secondary hidden sm:block" />
                <input 
                  type="text" 
                  required
                  value={formData.firstName}
                  onChange={(e) => setFormData({...formData, firstName: e.target.value})}
                  placeholder="First Name" 
                  className="bg-transparent outline-none flex-1 text-sm font-medium text-text-primary placeholder:text-text-secondary w-full" 
                />
              </div>
              <div className="flex-1 flex items-center gap-3 bg-card-bg border border-border-custom rounded-xl px-4 py-2.5 focus-within:ring-2 focus-within:ring-spaza-green transition-all min-w-0">
                <input 
                  type="text" 
                  required
                  value={formData.lastName}
                  onChange={(e) => setFormData({...formData, lastName: e.target.value})}
                  placeholder="Last Name" 
                  className="bg-transparent outline-none flex-1 text-sm font-medium text-text-primary placeholder:text-text-secondary w-full" 
                />
              </div>
            </div>
          </div>

          <div className="space-y-3 pt-2">
            <h3 className="text-[11px] font-bold text-text-primary uppercase tracking-wider">Contact Info</h3>
            
            <div className="flex items-center gap-3 bg-card-bg border border-border-custom rounded-xl px-4 py-2.5 focus-within:ring-2 focus-within:ring-spaza-green transition-all">
              <Mail size={18} className="text-text-secondary" />
              <input 
                type="email" 
                required
                value={formData.email}
                onChange={(e) => setFormData({...formData, email: e.target.value})}
                placeholder="Email Address" 
                className="bg-transparent outline-none flex-1 text-sm font-medium text-text-primary placeholder:text-text-secondary w-full" 
              />
            </div>

            <div className="flex items-center gap-3 bg-card-bg border border-border-custom rounded-xl px-4 py-2.5 focus-within:ring-2 focus-within:ring-spaza-green transition-all">
              <Phone size={18} className="text-text-secondary" />
              <input 
                type="tel" 
                required
                value={formData.phone}
                onChange={(e) => setFormData({...formData, phone: e.target.value})}
                placeholder="Phone Number" 
                className="bg-transparent outline-none flex-1 text-sm font-medium text-text-primary placeholder:text-text-secondary w-full" 
              />
            </div>

            <div className="flex items-center gap-3 bg-card-bg border border-border-custom rounded-xl px-4 py-2.5 focus-within:ring-2 focus-within:ring-spaza-green transition-all">
              <Lock size={18} className="text-text-secondary" />
              <input 
                type="password" 
                required
                value={formData.password}
                onChange={(e) => setFormData({...formData, password: e.target.value})}
                placeholder="Password" 
                className="bg-transparent outline-none flex-1 text-sm font-medium text-text-primary placeholder:text-text-secondary w-full" 
              />
            </div>
          </div>

          <div className="space-y-3 pt-2">
            <h3 className="text-[11px] font-bold text-text-primary uppercase tracking-wider">Location</h3>
            <div className="bg-card-bg border border-border-custom rounded-xl px-4 py-2.5 focus-within:ring-2 focus-within:ring-spaza-green transition-all">
              <textarea 
                required
                value={formData.location}
                onChange={(e) => setFormData({...formData, location: e.target.value})}
                placeholder="Shop address" 
                className="w-full bg-transparent outline-none flex-1 text-sm font-medium text-text-primary placeholder:text-text-secondary resize-none min-h-[60px]" 
              />
            </div>
          </div>

          <button 
            type="submit"
            disabled={loading || googleLoading}
            className="w-full bg-spaza-green hover:bg-spaza-green-dark text-white font-bold py-3.5 rounded-xl shadow-lg shadow-black/10 mt-4 active:scale-95 transition-all flex items-center justify-center gap-2 disabled:opacity-50 text-sm"
          >
            {loading ? <Loader2 className="animate-spin" size={18} /> : 'Create Account'}
          </button>
        </form>

        <div className="text-center mt-6">
          <p className="text-text-secondary text-xs">
            Already have an account? <button onClick={() => navigate('/login')} className="text-spaza-green font-bold">Login</button>
          </p>
        </div>
      </div>
    </div>
  );
};

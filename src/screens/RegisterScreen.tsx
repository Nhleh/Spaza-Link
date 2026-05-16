import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Camera, ArrowLeft, Store, User, Phone, Lock, MapPin, Mail, Loader2, CheckCircle } from 'lucide-react';
import { createUserWithEmailAndPassword, sendEmailVerification } from 'firebase/auth';
import { auth } from '../lib/firebase';
import { firebaseService } from '../services/firebaseService';
import { LocationPicker } from '../components/LocationPicker';

export const RegisterScreen: React.FC = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [photoBase64, setPhotoBase64] = useState<string | null>(null);
  
  const [formData, setFormData] = useState({
    shopName: '',
    ownerName: '',
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

      // 2. Send Verification Email
      await sendEmailVerification(user);

      // 3. Create User Profile in Firestore
      await firebaseService.saveDoc('users', user.uid, {
        uid: user.uid,
        email: formData.email,
        shopName: formData.shopName,
        ownerName: formData.ownerName,
        phone: formData.phone,
        location: formData.location,
        lat: formData.lat,
        lng: formData.lng,
        photoUrl: photoBase64,
        createdAt: new Date().toISOString()
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

  return (
    <div className="min-h-screen bg-spaza-bg flex flex-col px-6 py-8">
      <button onClick={() => navigate(-1)} className="mb-4 w-10 h-10 bg-card-bg rounded-xl border border-border-custom flex items-center justify-center">
        <ArrowLeft size={20} className="text-text-primary" />
      </button>

      <div className="mb-6">
        <h2 className="text-2xl font-bold text-text-primary mb-1">Create Your Account</h2>
        <p className="text-text-secondary text-sm">Let's get your spaza shop on SpazaLink</p>
      </div>

      {error && (
        <div className="mb-4 p-4 bg-red-500/10 border border-red-500/20 text-red-500 text-sm rounded-xl font-medium">
          {error}
        </div>
      )}

      {success && (
        <div className="mb-4 p-4 bg-green-500/10 border border-green-500/20 text-green-600 text-sm rounded-xl font-medium">
          Registration successful! Check your email to verify your account. Redirecting to login...
        </div>
      )}

      <div className="flex flex-col items-center mb-8">
        <label className="w-full">
          <div className="w-full aspect-[16/9] bg-card-bg rounded-[24px] border-2 border-dashed border-border-custom flex flex-col items-center justify-center gap-2 cursor-pointer hover:bg-spaza-bg transition-all overflow-hidden relative">
            {photoBase64 ? (
              <img src={photoBase64} alt="Shop" className="w-full h-full object-cover" />
            ) : (
              <>
                <Camera size={32} className="text-text-secondary opacity-30" />
                <span className="text-[11px] font-bold text-text-secondary uppercase tracking-widest">Upload Shop Photo</span>
              </>
            )}
          </div>
          <input type="file" accept="image/*" className="hidden" onChange={handleFileChange} />
        </label>
      </div>

      <form className="space-y-4 flex-1" onSubmit={handleRegister}>
        <div className="space-y-4">
          <h3 className="text-sm font-bold text-text-primary uppercase tracking-wider">Business Details</h3>
          
          <div className="flex items-center gap-3 bg-card-bg border border-border-custom rounded-xl px-4 py-3 focus-within:ring-2 focus-within:ring-spaza-green transition-all">
            <Store size={20} className="text-text-secondary" />
            <input 
              type="text" 
              required
              value={formData.shopName}
              onChange={(e) => setFormData({...formData, shopName: e.target.value})}
              placeholder="Shop Name" 
              className="bg-transparent outline-none flex-1 text-sm font-medium text-text-primary placeholder:text-text-secondary" 
            />
          </div>

          <div className="flex items-center gap-3 bg-card-bg border border-border-custom rounded-xl px-4 py-3 focus-within:ring-2 focus-within:ring-spaza-green transition-all">
            <User size={20} className="text-text-secondary" />
            <input 
              type="text" 
              required
              value={formData.ownerName}
              onChange={(e) => setFormData({...formData, ownerName: e.target.value})}
              placeholder="Owner Name" 
              className="bg-transparent outline-none flex-1 text-sm font-medium text-text-primary placeholder:text-text-secondary" 
            />
          </div>
        </div>

        <div className="space-y-4 pt-4">
          <h3 className="text-sm font-bold text-text-primary uppercase tracking-wider">Contact Info</h3>
          
          <div className="flex items-center gap-3 bg-card-bg border border-border-custom rounded-xl px-4 py-3 focus-within:ring-2 focus-within:ring-spaza-green transition-all">
            <Mail size={20} className="text-text-secondary" />
            <input 
              type="email" 
              required
              value={formData.email}
              onChange={(e) => setFormData({...formData, email: e.target.value})}
              placeholder="Email Address" 
              className="bg-transparent outline-none flex-1 text-sm font-medium text-text-primary placeholder:text-text-secondary" 
            />
          </div>

          <div className="flex items-center gap-3 bg-card-bg border border-border-custom rounded-xl px-4 py-3 focus-within:ring-2 focus-within:ring-spaza-green transition-all">
            <Phone size={20} className="text-text-secondary" />
            <input 
              type="tel" 
              required
              value={formData.phone}
              onChange={(e) => setFormData({...formData, phone: e.target.value})}
              placeholder="Phone Number" 
              className="bg-transparent outline-none flex-1 text-sm font-medium text-text-primary placeholder:text-text-secondary" 
            />
          </div>

          <div className="flex items-center gap-3 bg-card-bg border border-border-custom rounded-xl px-4 py-3 focus-within:ring-2 focus-within:ring-spaza-green transition-all">
            <Lock size={20} className="text-text-secondary" />
            <input 
              type="password" 
              required
              value={formData.password}
              onChange={(e) => setFormData({...formData, password: e.target.value})}
              placeholder="Password" 
              className="bg-transparent outline-none flex-1 text-sm font-medium text-text-primary placeholder:text-text-secondary" 
            />
          </div>
        </div>

        <div className="space-y-4 pt-4">
          <h3 className="text-sm font-bold text-text-primary uppercase tracking-wider">Shop Location</h3>
          <LocationPicker 
            onLocationSelect={(loc) => setFormData({
              ...formData, 
              location: loc.address,
              lat: loc.lat,
              lng: loc.lng
            })} 
          />
        </div>

        <button 
          type="submit"
          disabled={loading}
          className="w-full bg-spaza-green hover:bg-spaza-green-dark text-white font-bold py-4.5 rounded-xl shadow-lg shadow-black/10 mt-6 active:scale-95 transition-all flex items-center justify-center gap-2"
        >
          {loading ? <Loader2 className="animate-spin" size={20} /> : 'Register'}
        </button>
      </form>

      <div className="text-center mt-8">
        <p className="text-text-secondary text-sm">
          Already have an account? <button onClick={() => navigate('/login')} className="text-spaza-green font-bold">Login</button>
        </p>
      </div>
    </div>
  );
};

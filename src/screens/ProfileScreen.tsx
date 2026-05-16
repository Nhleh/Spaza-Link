import React, { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, User, MapPin, CreditCard, Lock, Bell, HelpCircle, LogOut, ChevronRight, Store, CheckCircle, AlertCircle, Loader2, Camera, X } from 'lucide-react';
import { auth, db } from '../lib/firebase';
import { signOut, onAuthStateChanged, updatePassword, EmailAuthProvider, reauthenticateWithCredential } from 'firebase/auth';
import { motion, AnimatePresence } from 'motion/react';
import { firebaseService } from '../services/firebaseService';
import { cn } from '../lib/utils';
import { LocationPicker } from '../components/LocationPicker';

import { UserProfile, Address, PaymentMethod, Shop } from '../types';
import { Plus, Trash2, CreditCard as CardIcon, Eye, EyeOff, Building2 } from 'lucide-react';
import { useLocation } from 'react-router-dom';
import { collection, query, where, onSnapshot, addDoc } from 'firebase/firestore';

export const ProfileScreen: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const [toast, setToast] = useState<{ message: string; type: 'info' | 'success' | 'error' } | null>(null);
  const [loading, setLoading] = useState(true);
  const [isEditing, setIsEditing] = useState(false);
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const shopPhotoInputRef = useRef<HTMLInputElement>(null);
  const [showShopInfo, setShowShopInfo] = useState(false);
  const [showShopsList, setShowShopsList] = useState(false);
  const [isAddingShop, setIsAddingShop] = useState(false);
  const [shops, setShops] = useState<Shop[]>([]);
  const [showAddresses, setShowAddresses] = useState(false);
  const [showPayments, setShowPayments] = useState(false);
  const [showPasswordModal, setShowPasswordModal] = useState(false);
  const [editingAddress, setEditingAddress] = useState<Address | null>(null);
  const [editingPayment, setEditingPayment] = useState<PaymentMethod | null>(null);

  // New Shop form state
  const [newShop, setNewShop] = useState<Partial<Shop>>({
    name: '',
    address: '',
    managerName: '',
    contactNumber: '',
    photoUrl: ''
  });

  // Password state
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showCurrentPass, setShowCurrentPass] = useState(false);
  const [showNewPass, setShowNewPass] = useState(false);
  const [passwordLoading, setPasswordLoading] = useState(false);

  useEffect(() => {
    if (location.state?.openAddShop) {
      setShowShopsList(true);
      setIsAddingShop(true);
    }
  }, [location.state]);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (user) {
        try {
          const profile = await firebaseService.getDoc('users', user.uid);
          setUserProfile(profile || { 
            uid: user.uid, 
            email: user.email, 
            shopName: 'New SpazaLink Shop', 
            ownerName: user.displayName || 'Spaza Owner',
            location: 'Update your location',
            role: 'customer',
            createdAt: new Date().toISOString()
          } as UserProfile);

          // Listen to user's shops
          const shopsQuery = query(
            collection(db, 'shops'),
            where('ownerId', '==', user.uid)
          );
          
          const unsubShops = onSnapshot(shopsQuery, (snapshot) => {
            const shopsList = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Shop));
            setShops(shopsList);
          });

          return () => unsubShops();
        } catch (error) {
          console.error('Error fetching profile:', error);
        } finally {
          setLoading(false);
        }
      } else {
        navigate('/login');
      }
    });

    return () => unsubscribe();
  }, [navigate]);

  const handleAddShop = async () => {
    if (!auth.currentUser || !newShop.name || !newShop.address) {
      showToast('Please fill in shop name and address', 'error');
      return;
    }

    try {
      setLoading(true);
      const shopData = {
        name: newShop.name,
        address: newShop.address,
        managerName: newShop.managerName || '',
        contactNumber: newShop.contactNumber || '',
        photoUrl: newShop.photoUrl || '',
        ownerId: auth.currentUser.uid,
        createdAt: new Date().toISOString(),
        lat: newShop.lat || 0,
        lng: newShop.lng || 0
      };

      const docRef = await addDoc(collection(db, 'shops'), shopData);
      
      // If no active shop, set this as active
      if (!userProfile?.activeShopId) {
        await firebaseService.updateDoc('users', auth.currentUser.uid, {
          activeShopId: docRef.id,
          shopName: shopData.name,
          location: shopData.address
        });
      }

      showToast('Shop added successfully!', 'success');
      setIsAddingShop(false);
      setNewShop({
        name: '',
        address: '',
        managerName: '',
        contactNumber: '',
        photoUrl: ''
      });
    } catch (error) {
      console.error('Error adding shop:', error);
      showToast('Failed to add shop', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleShopPhotoUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (file.size > 1024 * 1024) {
        showToast('Image too large (max 1MB)', 'error');
        return;
      }
      const reader = new FileReader();
      reader.onloadend = () => {
        setNewShop({ ...newShop, photoUrl: reader.result as string });
      };
      reader.readAsDataURL(file);
    }
  };

  const handlePhotoUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (file.size > 1024 * 1024) {
        showToast('Image too large (max 1MB)', 'error');
        return;
      }
      const reader = new FileReader();
      reader.onloadend = async () => {
        const base64 = reader.result as string;
        try {
          setLoading(true);
          await firebaseService.updateDoc('users', auth.currentUser!.uid, {
            photoUrl: base64
          });
          setUserProfile({ ...userProfile, photoUrl: base64 });
          showToast('Photo updated successfully!', 'success');
        } catch (error) {
          showToast('Failed to upload photo', 'error');
        } finally {
          setLoading(false);
        }
      };
      reader.readAsDataURL(file);
    }
  };

  const showToast = (message: string, type: 'info' | 'success' | 'error' = 'info') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  const handleLogout = async () => {
    try {
      await signOut(auth);
      navigate('/');
    } catch (error) {
      console.error('Error signing out:', error);
      showToast('Error signing out. Please try again.', 'error');
    }
  };

  const handleSaveProfile = async () => {
    if (!auth.currentUser) return;
    
    try {
      setLoading(true);
      await firebaseService.updateDoc('users', auth.currentUser.uid, {
        shopName: userProfile.shopName,
        ownerName: userProfile.ownerName,
        location: userProfile.location,
        lat: userProfile.lat,
        lng: userProfile.lng,
        phone: userProfile.phone
      });
      setIsEditing(false);
      setShowShopInfo(false);
      showToast('Profile updated successfully!', 'success');
    } catch (error) {
      showToast('Failed to update profile.', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleSaveAddresses = async (newAddresses: Address[]) => {
    if (!auth.currentUser || !userProfile) return;
    try {
      setLoading(true);
      await firebaseService.updateDoc('users', auth.currentUser.uid, {
        addresses: newAddresses
      });
      setUserProfile({ ...userProfile, addresses: newAddresses });
      showToast('Addresses updated!', 'success');
    } catch (error) {
      showToast('Failed to update addresses', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleSavePayments = async (newPayments: PaymentMethod[]) => {
    if (!auth.currentUser || !userProfile) return;
    try {
      setLoading(true);
      await firebaseService.updateDoc('users', auth.currentUser.uid, {
        paymentMethods: newPayments
      });
      setUserProfile({ ...userProfile, paymentMethods: newPayments });
      showToast('Payment methods updated!', 'success');
    } catch (error) {
      showToast('Failed to update payment methods', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleChangePassword = async () => {
    if (!auth.currentUser || !currentPassword || !newPassword) {
      showToast('Please fill all fields', 'error');
      return;
    }

    if (newPassword !== confirmPassword) {
      showToast('Passwords do not match', 'error');
      return;
    }

    if (newPassword.length < 6) {
      showToast('Password must be at least 6 characters', 'error');
      return;
    }

    try {
      setPasswordLoading(true);
      // Re-authenticate user first
      const credential = EmailAuthProvider.credential(auth.currentUser.email!, currentPassword);
      await reauthenticateWithCredential(auth.currentUser, credential);
      
      // Update password
      await updatePassword(auth.currentUser, newPassword);
      
      showToast('Password updated successfully!', 'success');
      setShowPasswordModal(false);
      setCurrentPassword('');
      setNewPassword('');
      setConfirmPassword('');
    } catch (error: any) {
      console.error('Password reset error:', error);
      if (error.code === 'auth/wrong-password') {
        showToast('Incorrect current password', 'error');
      } else {
        showToast(error.message || 'Failed to update password', 'error');
      }
    } finally {
      setPasswordLoading(false);
    }
  };

  const menuItems = [
    { icon: Store, label: 'Manage Shops', onClick: () => setShowShopsList(true) },
    { icon: MapPin, label: 'Delivery Addresses', onClick: () => setShowAddresses(true) },
    { icon: CreditCard, label: 'Payment Methods', onClick: () => setShowPayments(true) },
    { icon: Lock, label: 'Change Password', onClick: () => setShowPasswordModal(true) },
    { icon: Bell, label: 'Notification Settings', onClick: () => navigate('/settings') },
    { icon: HelpCircle, label: 'Help & Support', onClick: () => navigate('/support') },
  ];

  if (loading && !userProfile) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-spaza-bg">
        <Loader2 className="animate-spin text-spaza-green" size={32} />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-spaza-bg flex flex-col">
      {/* Toast Notification */}
      <AnimatePresence>
        {toast && (
          <motion.div
            initial={{ opacity: 0, y: -50 }}
            animate={{ opacity: 1, y: 20 }}
            exit={{ opacity: 0, y: -50 }}
            className="fixed top-0 left-0 right-0 z-50 flex justify-center px-6"
          >
          <div className={cn(
              "px-6 py-3 bg-card-bg border rounded-2xl shadow-xl flex items-center gap-3",
              toast.type === 'success' ? "border-spaza-green/20" : "border-red-500/20"
            )}>
              {toast.type === 'success' ? <CheckCircle size={18} className="text-spaza-green" /> : <AlertCircle size={18} className="text-red-500" />}
              <span className="text-xs font-black uppercase tracking-wider text-text-primary">{toast.message}</span>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      <header className="px-6 pt-4 safe-area-top pb-6 flex items-center justify-between bg-card-bg border-b border-border-custom">
        <h2 className="text-lg font-bold text-text-primary mt-4">Account</h2>
      </header>

      <div className="px-6 py-8 space-y-8 flex-1 overflow-y-auto pb-40">
        {/* Profile Card */}
        <div className="bg-card-bg p-6 rounded-[32px] shadow-premium flex flex-col items-center text-center border border-border-custom">
            <div 
              onClick={() => fileInputRef.current?.click()}
              className="w-24 h-24 rounded-full bg-spaza-bg overflow-hidden border-4 border-spaza-bg shadow-md mb-4 relative group cursor-pointer"
            >
                <img 
                  src={userProfile?.photoUrl || "https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=80&w=200"} 
                  alt="profile" 
                  className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500" 
                />
                <div className="absolute inset-0 bg-black/20 group-hover:bg-black/40 flex items-center justify-center text-white transition-all opacity-0 group-hover:opacity-100">
                  <Camera size={20} />
                </div>
                <input 
                  type="file" 
                  ref={fileInputRef}
                  onChange={handlePhotoUpload}
                  accept="image/*"
                  className="hidden"
                />
            </div>

            {isEditing ? (
              <div className="w-full space-y-4 mb-4">
                <div className="space-y-3">
                  <div className="flex items-center gap-3 bg-spaza-bg border border-border-custom rounded-xl px-4 py-2">
                    <Store size={18} className="text-text-secondary" />
                    <input 
                      type="text" 
                      value={userProfile?.shopName || ''}
                      onChange={(e) => setUserProfile({...userProfile, shopName: e.target.value})}
                      className="flex-1 bg-transparent text-sm font-bold outline-none text-text-primary"
                      placeholder="Shop Name"
                    />
                  </div>
                  <div className="flex items-center gap-3 bg-spaza-bg border border-border-custom rounded-xl px-4 py-2">
                    <User size={18} className="text-text-secondary" />
                    <input 
                      type="text" 
                      value={userProfile?.ownerName || ''}
                      onChange={(e) => setUserProfile({...userProfile, ownerName: e.target.value})}
                      className="flex-1 bg-transparent text-sm font-medium outline-none text-text-primary"
                      placeholder="Owner Name"
                    />
                  </div>
                </div>

                <div className="flex gap-2">
                  <button 
                    onClick={() => setIsEditing(false)}
                    className="flex-1 text-text-secondary text-sm font-bold bg-spaza-bg px-6 py-2 rounded-xl active:scale-95 transition-transform"
                  >
                    Cancel
                  </button>
                  <button 
                    onClick={handleSaveProfile}
                    disabled={loading}
                    className="flex-1 text-white text-sm font-bold bg-spaza-green px-6 py-2 rounded-xl active:scale-95 transition-transform flex items-center justify-center"
                  >
                    {loading ? <Loader2 className="animate-spin" size={16} /> : 'Save'}
                  </button>
                </div>
              </div>
            ) : (
              <>
                <h3 className="text-lg font-bold text-text-primary tracking-tight leading-tight">{userProfile?.shopName}</h3>
                <p className="text-sm text-text-secondary font-medium mb-4">{userProfile?.location}</p>
                <div className="flex gap-2">
                  <button 
                    onClick={() => setIsEditing(true)}
                    className="text-spaza-green text-sm font-bold bg-spaza-green/10 px-6 py-2 rounded-xl border border-spaza-green/10 active:scale-95 transition-transform"
                  >
                    Edit Profile
                  </button>
                </div>
              </>
            )}
        </div>

        <AnimatePresence>
          {showPasswordModal && (
            <motion.div 
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="fixed inset-0 z-[60] flex items-center justify-center p-6"
            >
              <div 
                className="absolute inset-0 bg-black/60 backdrop-blur-sm" 
                onClick={() => setShowPasswordModal(false)}
              />
              <div className="relative w-full max-w-md bg-card-bg rounded-[32px] p-8 shadow-2xl overflow-y-auto max-h-[85vh] border border-border-custom">
                <h2 className="text-xl font-bold text-text-primary mb-6 font-display">Change Password</h2>
                
                <div className="space-y-6">
                  {/* Current Password */}
                  <div className="space-y-2">
                    <label className="text-xs font-bold text-text-secondary uppercase tracking-wider">Current Password</label>
                    <div className="flex items-center gap-3 bg-spaza-bg border border-border-custom rounded-xl px-4 py-3">
                      <Lock size={20} className="text-text-secondary" />
                      <input 
                        type={showCurrentPass ? "text" : "password"} 
                        value={currentPassword}
                        onChange={(e) => setCurrentPassword(e.target.value)}
                        className="flex-1 bg-transparent text-sm font-medium outline-none text-text-primary"
                        placeholder="••••••••"
                      />
                      <button onClick={() => setShowCurrentPass(!showCurrentPass)} className="text-text-secondary p-1">
                        {showCurrentPass ? <EyeOff size={18} /> : <Eye size={18} />}
                      </button>
                    </div>
                  </div>

                  {/* New Password */}
                  <div className="space-y-2">
                    <label className="text-xs font-bold text-text-secondary uppercase tracking-wider">New Password</label>
                    <div className="flex items-center gap-3 bg-spaza-bg border border-border-custom rounded-xl px-4 py-3">
                      <Lock size={20} className="text-text-secondary" />
                      <input 
                        type={showNewPass ? "text" : "password"} 
                        value={newPassword}
                        onChange={(e) => setNewPassword(e.target.value)}
                        className="flex-1 bg-transparent text-sm font-medium outline-none text-text-primary"
                        placeholder="Min 6 characters"
                      />
                      <button onClick={() => setShowNewPass(!showNewPass)} className="text-text-secondary p-1">
                        {showNewPass ? <EyeOff size={18} /> : <Eye size={18} />}
                      </button>
                    </div>
                  </div>

                  {/* Confirm Password */}
                  <div className="space-y-2">
                    <label className="text-xs font-bold text-text-secondary uppercase tracking-wider">Confirm New Password</label>
                    <div className="flex items-center gap-3 bg-spaza-bg border border-border-custom rounded-xl px-4 py-3">
                      <Lock size={20} className="text-text-secondary" />
                      <input 
                        type={showNewPass ? "text" : "password"} 
                        value={confirmPassword}
                        onChange={(e) => setConfirmPassword(e.target.value)}
                        className="flex-1 bg-transparent text-sm font-medium outline-none text-text-primary"
                        placeholder="••••••••"
                      />
                    </div>
                  </div>

                  <div className="flex gap-3 pt-4">
                    <button 
                      onClick={() => setShowPasswordModal(false)}
                      className="flex-1 py-3 text-text-secondary font-bold text-sm bg-spaza-bg rounded-xl active:scale-95 transition-all"
                    >
                      Cancel
                    </button>
                    <button 
                      onClick={handleChangePassword}
                      disabled={passwordLoading || !currentPassword || !newPassword}
                      className="flex-1 py-3 text-white font-bold text-sm bg-spaza-green rounded-xl shadow-lg shadow-spaza-green/20 active:scale-95 transition-all flex items-center justify-center gap-2 disabled:opacity-50"
                    >
                      {passwordLoading ? <Loader2 className="animate-spin" size={18} /> : 'Update Password'}
                    </button>
                  </div>
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Shops List Modal */}
        <AnimatePresence>
          {showShopsList && (
            <motion.div 
              initial={{ opacity: 0, x: '100%' }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: '100%' }}
              className="fixed inset-0 z-[70] bg-spaza-bg flex flex-col pt-4"
            >
              <header className="px-6 pt-4 safe-area-top pb-4 flex items-center justify-between border-b border-border-custom bg-card-bg">
                <div className="flex items-center gap-4 mt-4">
                  <button onClick={() => setShowShopsList(false)} className="p-2 -ml-2 text-text-secondary active:bg-spaza-bg rounded-full transition-colors">
                    <ArrowLeft size={24} />
                  </button>
                  <h2 className="text-lg font-bold text-text-primary">Manage Shops</h2>
                </div>
                <button 
                  onClick={() => setIsAddingShop(true)}
                  className="p-2 bg-spaza-green/10 text-spaza-green rounded-xl active:scale-95 transition-all flex items-center gap-1 px-3"
                >
                  <Plus size={18} />
                  <span className="text-xs font-black uppercase">Add</span>
                </button>
              </header>

              <div className="flex-1 overflow-y-auto px-6 py-6 space-y-4 pb-32">
                {shops.length > 0 ? (
                  shops.map((shop) => (
                    <div key={shop.id} className={cn(
                      "p-5 rounded-[28px] border transition-all flex items-center gap-4 shadow-sm",
                      userProfile?.activeShopId === shop.id 
                        ? "bg-spaza-green/5 border-spaza-green shadow-spaza-green/10" 
                        : "bg-card-bg border-border-custom"
                    )}>
                      <div className="w-14 h-14 rounded-2xl bg-spaza-bg overflow-hidden border border-border-custom flex-shrink-0">
                        {shop.photoUrl ? (
                          <img src={shop.photoUrl} alt={shop.name} className="w-full h-full object-cover" />
                        ) : (
                          <div className="w-full h-full flex items-center justify-center text-spaza-green">
                            <Store size={24} />
                          </div>
                        )}
                      </div>
                      <div className="flex-1">
                        <div className="flex justify-between items-center">
                          <h4 className="text-sm font-bold text-text-primary">{shop.name}</h4>
                          {userProfile?.activeShopId === shop.id && (
                            <span className="text-[10px] font-black uppercase text-spaza-green bg-spaza-green/10 px-2 py-0.5 rounded-full">Active</span>
                          )}
                        </div>
                        <p className="text-[11px] text-text-secondary line-clamp-1 mt-0.5">{shop.address}</p>
                        <div className="flex items-center gap-4 mt-3">
                          <p className="text-[10px] font-bold text-text-secondary">Manager: <span className="text-text-primary">{shop.managerName || 'Owner'}</span></p>
                          <button 
                            onClick={async () => {
                              try {
                                await firebaseService.updateDoc('users', auth.currentUser!.uid, {
                                  activeShopId: shop.id,
                                  shopName: shop.name,
                                  location: shop.address
                                });
                                setUserProfile({ 
                                  ...userProfile as UserProfile, 
                                  activeShopId: shop.id,
                                  shopName: shop.name,
                                  location: shop.address
                                });
                                showToast(`${shop.name} is now active`, 'success');
                              } catch (e) {
                                showToast('Failed to switch shop', 'error');
                              }
                            }}
                            className={cn(
                              "text-[10px] font-black uppercase tracking-widest",
                              userProfile?.activeShopId === shop.id ? "text-spaza-green opacity-50 cursor-default" : "text-spaza-green"
                            )}
                            disabled={userProfile?.activeShopId === shop.id}
                          >
                            {userProfile?.activeShopId === shop.id ? 'Already Active' : 'Set as Active'}
                          </button>
                        </div>
                      </div>
                    </div>
                  ))
                ) : (
                  <div className="flex flex-col items-center justify-center py-20 text-text-secondary opacity-30">
                    <Store size={48} className="mb-4 opacity-20" />
                    <p className="text-sm font-medium">No shops found</p>
                  </div>
                )}
              </div>

              {/* Add Shop Overlay */}
              <AnimatePresence>
                {isAddingShop && (
                  <motion.div 
                    initial={{ opacity: 0, y: '100%' }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: '100%' }}
                    className="fixed inset-0 z-[80] bg-spaza-bg flex flex-col"
                  >
                    <header className="px-6 pt-4 safe-area-top pb-8 flex items-center gap-4 border-b border-border-custom bg-card-bg">
                      <button onClick={() => setIsAddingShop(false)} className="p-2 text-text-secondary mt-4">
                        <X size={24} />
                      </button>
                      <h2 className="text-lg font-bold text-text-primary">Add New Spaza Shop</h2>
                    </header>

                    <div className="flex-1 overflow-y-auto px-6 py-8 space-y-6">
                      <div className="flex flex-col items-center mb-6">
                        <div 
                          onClick={() => shopPhotoInputRef.current?.click()}
                          className="w-28 h-28 bg-card-bg rounded-[32px] border-2 border-dashed border-border-custom flex flex-col items-center justify-center text-text-secondary cursor-pointer overflow-hidden relative"
                        >
                          {newShop.photoUrl ? (
                            <img src={newShop.photoUrl} alt="Preview" className="w-full h-full object-cover" />
                          ) : (
                            <>
                              <Camera size={32} className="opacity-20 mb-1" />
                              <span className="text-[10px] font-bold uppercase tracking-widest leading-none">Shop Photo</span>
                            </>
                          )}
                        </div>
                        <input 
                          type="file" 
                          ref={shopPhotoInputRef}
                          onChange={handleShopPhotoUpload}
                          accept="image/*"
                          className="hidden"
                        />
                      </div>

                      <div className="space-y-4">
                        <div className="space-y-1">
                          <label className="text-[11px] font-black text-text-secondary uppercase tracking-widest ml-1">Shop Name</label>
                          <div className="flex items-center gap-3 bg-card-bg border border-border-custom rounded-2xl px-4 py-4">
                            <Store size={20} className="text-text-secondary" />
                            <input 
                              type="text" 
                              value={newShop.name}
                              onChange={(e) => setNewShop({...newShop, name: e.target.value})}
                              className="flex-1 bg-transparent text-sm font-bold outline-none text-text-primary"
                              placeholder="e.g. Thabo's Spaza Link"
                            />
                          </div>
                        </div>

                        <div className="space-y-1">
                          <label className="text-[11px] font-black text-text-secondary uppercase tracking-widest ml-1">Shop Address</label>
                          <LocationPicker 
                            initialAddress={newShop.address}
                            onLocationSelect={(loc) => setNewShop({
                              ...newShop,
                              address: loc.address,
                              lat: loc.lat,
                              lng: loc.lng
                            })}
                          />
                        </div>

                        <div className="grid grid-cols-1 gap-4">
                          <div className="space-y-1">
                            <label className="text-[11px] font-black text-text-secondary uppercase tracking-widest ml-1">Shop Manager Name</label>
                            <div className="flex items-center gap-3 bg-card-bg border border-border-custom rounded-2xl px-4 py-4">
                              <User size={20} className="text-text-secondary" />
                              <input 
                                type="text" 
                                value={newShop.managerName}
                                onChange={(e) => setNewShop({...newShop, managerName: e.target.value})}
                                className="flex-1 bg-transparent text-sm font-bold outline-none text-text-primary"
                                placeholder="Who manages this shop?"
                              />
                            </div>
                          </div>
                          
                          <div className="space-y-1">
                            <label className="text-[11px] font-black text-text-secondary uppercase tracking-widest ml-1">Contact Number</label>
                            <div className="flex items-center gap-3 bg-card-bg border border-border-custom rounded-2xl px-4 py-4">
                              <HelpCircle size={20} className="text-text-secondary" />
                              <input 
                                type="tel" 
                                value={newShop.contactNumber}
                                onChange={(e) => setNewShop({...newShop, contactNumber: e.target.value})}
                                className="flex-1 bg-transparent text-sm font-bold outline-none text-text-primary"
                                placeholder="Shop Phone Number"
                              />
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>

                    <div className="p-6 border-t border-border-custom bg-card-bg">
                      <button 
                        onClick={handleAddShop}
                        disabled={loading || !newShop.name || !newShop.address}
                        className="w-full bg-spaza-green text-white font-black py-4 rounded-2xl shadow-lg active:scale-95 transition-all flex items-center justify-center gap-2 disabled:opacity-50"
                      >
                        {loading ? <Loader2 className="animate-spin" size={20} /> : 'Save New Shop'}
                      </button>
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Payment Methods Modal */}
        <AnimatePresence>
          {showPayments && (
            <motion.div 
              initial={{ opacity: 0, x: '100%' }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: '100%' }}
              className="fixed inset-0 z-[70] bg-spaza-bg flex flex-col pt-4"
            >
              <header className="px-6 pt-4 safe-area-top pb-4 flex items-center justify-between border-b border-border-custom bg-card-bg">
                <div className="flex items-center gap-4 mt-4">
                  <button onClick={() => setShowPayments(false)} className="p-2 -ml-2 text-text-secondary active:bg-spaza-bg rounded-full transition-colors">
                    <ArrowLeft size={24} />
                  </button>
                  <h2 className="text-lg font-bold text-text-primary">Payment Methods</h2>
                </div>
                <button 
                  onClick={() => setEditingPayment({ id: Math.random().toString(36).substr(2, 9), type: 'card', brand: 'Visa', last4: '****', isDefault: false })}
                  className="p-2 bg-spaza-green/10 text-spaza-green rounded-xl active:scale-95 transition-all"
                >
                  <Plus size={20} />
                </button>
              </header>

              <div className="flex-1 overflow-y-auto px-6 py-6 space-y-4">
                {userProfile?.paymentMethods?.length ? (
                  userProfile.paymentMethods.map((pm) => (
                    <div key={pm.id} className="p-4 bg-card-bg border border-border-custom rounded-2xl shadow-sm flex items-start gap-4">
                      <div className="p-3 bg-spaza-bg text-text-secondary rounded-xl border border-border-custom">
                        {pm.type === 'card' ? <CardIcon size={20} /> : <Store size={20} />}
                      </div>
                      <div className="flex-1">
                        <div className="flex justify-between items-center">
                          <h4 className="text-sm font-bold text-text-primary">{pm.brand} ending in {pm.last4}</h4>
                          {pm.isDefault && <span className="text-[10px] font-black uppercase text-spaza-green bg-spaza-green/10 px-2 py-0.5 rounded-full">Default</span>}
                        </div>
                        <p className="text-xs text-text-secondary font-medium mt-0.5">{pm.type.toUpperCase()} • Expires {pm.expiry || '01/29'}</p>
                        <div className="flex gap-4 mt-3">
                          <button 
                            onClick={() => handleSavePayments(userProfile.paymentMethods?.filter(p => p.id !== pm.id) || [])}
                            className="text-xs font-bold text-red-500"
                          >
                            Remove
                          </button>
                        </div>
                      </div>
                    </div>
                  ))
                ) : (
                  <div className="flex flex-col items-center justify-center py-20 text-text-secondary opacity-30">
                    <CardIcon size={48} className="mb-4 opacity-20" />
                    <p className="text-sm font-medium">No payment methods saved</p>
                  </div>
                )}
                
                <div className="p-4 bg-spaza-green/5 rounded-2xl border border-spaza-green/10">
                  <div className="flex items-center gap-3 mb-2">
                    <AlertCircle size={16} className="text-spaza-green" />
                    <h5 className="text-xs font-bold text-text-primary">Note on Payments</h5>
                  </div>
                  <p className="text-[10px] text-text-secondary font-medium leading-relaxed">
                    We support Cash on Delivery by default. Adding a card allows for faster checkout and contactless delivery.
                  </p>
                </div>
              </div>

              {/* Add Card Overlay */}
              <AnimatePresence>
                {editingPayment && (
                  <motion.div 
                    initial={{ opacity: 0, y: '100%' }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: '100%' }}
                    className="fixed inset-0 z-[80] bg-spaza-bg flex flex-col"
                  >
                    <header className="px-6 pt-4 safe-area-top pb-8 flex items-center gap-4 border-b border-border-custom bg-card-bg">
                      <button onClick={() => setEditingPayment(null)} className="p-2 text-text-secondary mt-4">
                        <X size={24} />
                      </button>
                      <h2 className="text-lg font-bold text-text-primary">Add Payment Method</h2>
                    </header>

                    <div className="flex-1 overflow-y-auto px-6 py-8 space-y-6">
                      <div className="space-y-4">
                        <div className="space-y-2">
                          <label className="text-xs font-bold text-text-secondary uppercase tracking-wider">Card Number</label>
                          <div className="flex items-center gap-3 bg-card-bg border border-border-custom rounded-xl px-4 py-3.5">
                            <CardIcon size={20} className="text-text-secondary" />
                            <input 
                              type="text" 
                              className="flex-1 bg-transparent text-sm font-bold outline-none text-text-primary"
                              placeholder="0000 0000 0000 0000"
                              onChange={(e) => {
                                const val = e.target.value.replace(/\s/g, '');
                                if (val.length >= 16) {
                                  setEditingPayment({...editingPayment, last4: val.slice(-4)});
                                }
                              }}
                            />
                          </div>
                        </div>

                        <div className="grid grid-cols-2 gap-4">
                          <div className="space-y-2">
                            <label className="text-xs font-bold text-text-secondary uppercase tracking-wider">Expiry Date</label>
                            <input 
                              type="text" 
                              placeholder="MM/YY"
                              onChange={(e) => setEditingPayment({...editingPayment, expiry: e.target.value})}
                              className="w-full bg-card-bg border border-border-custom rounded-xl px-4 py-3.5 text-sm font-bold outline-none text-text-primary"
                            />
                          </div>
                          <div className="space-y-2">
                            <label className="text-xs font-bold text-text-secondary uppercase tracking-wider">CVV</label>
                            <input 
                              type="password" 
                              placeholder="***"
                              className="w-full bg-card-bg border border-border-custom rounded-xl px-4 py-3.5 text-sm font-bold outline-none text-text-primary"
                            />
                          </div>
                        </div>
                      </div>

                      <label className="flex items-center gap-3 p-4 bg-card-bg border border-border-custom rounded-xl cursor-pointer">
                        <input 
                          type="checkbox" 
                          checked={editingPayment.isDefault}
                          onChange={(e) => setEditingPayment({...editingPayment, isDefault: e.target.checked})}
                          className="w-5 h-5 accent-spaza-green"
                        />
                        <span className="text-sm font-bold text-text-primary">Set as default payment method</span>
                      </label>
                    </div>

                    <div className="p-6 border-t border-border-custom bg-card-bg">
                      <button 
                        onClick={() => {
                          const others = userProfile?.paymentMethods?.filter(p => p.id !== editingPayment.id) || [];
                          const finalPayments = editingPayment.isDefault 
                            ? [...others.map(po => ({...po, isDefault: false})), editingPayment]
                            : [...others, editingPayment];
                          handleSavePayments(finalPayments);
                          setEditingPayment(null);
                        }}
                        className="w-full bg-spaza-green text-white font-bold py-4 rounded-xl shadow-lg active:scale-95 transition-all"
                      >
                        Add Card
                      </button>
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>
            </motion.div>
          )}
        </AnimatePresence>
        <AnimatePresence>
          {showAddresses && (
            <motion.div 
              initial={{ opacity: 0, x: '100%' }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: '100%' }}
              className="fixed inset-0 z-[70] bg-spaza-bg flex flex-col pt-4"
            >
              <header className="px-6 pt-4 safe-area-top pb-4 flex items-center justify-between border-b border-border-custom bg-card-bg">
                <div className="flex items-center gap-4 mt-4">
                  <button onClick={() => setShowAddresses(false)} className="p-2 -ml-2 text-text-secondary active:bg-spaza-bg rounded-full transition-colors">
                    <ArrowLeft size={24} />
                  </button>
                  <h2 className="text-lg font-bold text-text-primary">Delivery Addresses</h2>
                </div>
                <button 
                  onClick={() => setEditingAddress({ id: Math.random().toString(36).substr(2, 9), name: '', address: '', lat: 0, lng: 0, isDefault: false })}
                  className="p-2 bg-spaza-green/10 text-spaza-green rounded-xl active:scale-95 transition-all"
                >
                  <Plus size={20} />
                </button>
              </header>

              <div className="flex-1 overflow-y-auto px-6 py-6 space-y-4">
                {userProfile?.addresses?.length ? (
                  userProfile.addresses.map((addr) => (
                    <div key={addr.id} className="p-4 bg-card-bg border border-border-custom rounded-2xl shadow-sm flex items-start gap-4">
                      <div className="p-3 bg-spaza-bg text-text-secondary rounded-xl border border-border-custom">
                        <MapPin size={20} />
                      </div>
                      <div className="flex-1">
                        <div className="flex justify-between items-center">
                          <h4 className="text-sm font-bold text-text-primary">{addr.name}</h4>
                          {addr.isDefault && <span className="text-[10px] font-black uppercase text-spaza-green bg-spaza-green/10 px-2 py-0.5 rounded-full">Default</span>}
                        </div>
                        <p className="text-xs text-text-secondary font-medium mt-0.5">{addr.address}</p>
                        <div className="flex gap-4 mt-3">
                          <button onClick={() => setEditingAddress(addr)} className="text-xs font-bold text-spaza-green">Edit</button>
                          <button 
                            onClick={() => handleSaveAddresses(userProfile.addresses?.filter(a => a.id !== addr.id) || [])}
                            className="text-xs font-bold text-red-500"
                          >
                            Delete
                          </button>
                        </div>
                      </div>
                    </div>
                  ))
                ) : (
                  <div className="flex flex-col items-center justify-center py-20 text-text-secondary opacity-30">
                    <MapPin size={48} className="mb-4 opacity-20" />
                    <p className="text-sm font-medium">No saved addresses</p>
                  </div>
                )}
              </div>

              {/* Edit Address Overlay */}
              <AnimatePresence>
                {editingAddress && (
                  <motion.div 
                    initial={{ opacity: 0, y: '100%' }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: '100%' }}
                    className="fixed inset-0 z-[80] bg-spaza-bg flex flex-col"
                  >
                    <header className="px-6 pt-4 safe-area-top pb-8 flex items-center gap-4 border-b border-border-custom bg-card-bg">
                      <button onClick={() => setEditingAddress(null)} className="p-2 text-text-secondary mt-4">
                        <X size={24} />
                      </button>
                      <h2 className="text-lg font-bold text-text-primary">{userProfile?.addresses?.find(a => a.id === editingAddress.id) ? 'Edit Address' : 'New Address'}</h2>
                    </header>

                    <div className="flex-1 overflow-y-auto px-6 py-8 space-y-6 text-text-primary">
                      <div className="space-y-2">
                        <label className="text-xs font-bold text-text-secondary uppercase tracking-wider">Address Label (e.g. Home, Shop)</label>
                        <input 
                          type="text" 
                          value={editingAddress.name}
                          onChange={(e) => setEditingAddress({...editingAddress, name: e.target.value})}
                          className="w-full bg-card-bg border border-border-custom rounded-xl px-4 py-3.5 text-sm font-medium focus:ring-2 focus:ring-spaza-green outline-none transition-all text-text-primary"
                          placeholder="Home, My Spaza, Warehouse etc."
                        />
                      </div>

                      <div className="space-y-2">
                        <label className="text-xs font-bold text-text-secondary uppercase tracking-wider">Search Address</label>
                        <LocationPicker 
                          initialAddress={editingAddress.address}
                          onLocationSelect={(loc) => setEditingAddress({
                            ...editingAddress,
                            address: loc.address,
                            lat: loc.lat,
                            lng: loc.lng
                          })}
                        />
                      </div>

                      <label className="flex items-center gap-3 p-4 bg-card-bg border border-border-custom rounded-xl cursor-pointer">
                        <input 
                          type="checkbox" 
                          checked={editingAddress.isDefault}
                          onChange={(e) => setEditingAddress({...editingAddress, isDefault: e.target.checked})}
                          className="w-5 h-5 accent-spaza-green"
                        />
                        <span className="text-sm font-bold text-text-primary">Set as default delivery address</span>
                      </label>
                    </div>

                    <div className="p-6 border-t border-border-custom bg-card-bg">
                      <button 
                        onClick={() => {
                          const others = userProfile?.addresses?.filter(a => a.id !== editingAddress.id) || [];
                          const finalAddresses = editingAddress.isDefault 
                            ? [...others.map(ao => ({...ao, isDefault: false})), editingAddress]
                            : [...others, editingAddress];
                          handleSaveAddresses(finalAddresses);
                          setEditingAddress(null);
                        }}
                        disabled={!editingAddress.name || !editingAddress.address}
                        className="w-full bg-spaza-green text-white font-bold py-4 rounded-xl shadow-lg active:scale-95 transition-all disabled:opacity-50"
                      >
                        Save Address
                      </button>
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>
            </motion.div>
          )}
        </AnimatePresence>
        <div className="space-y-4">
            <h3 className="text-[13px] font-bold text-text-primary px-1 uppercase tracking-widest text-opacity-40">Account Settings</h3>
            <div className="bg-card-bg rounded-[32px] shadow-premium border border-border-custom overflow-hidden divide-y divide-border-custom">
                {menuItems.map((item, idx) => (
                    <button 
                        key={idx}
                        onClick={item.onClick}
                        className="w-full px-6 py-5 flex items-center justify-between active:bg-spaza-bg transition-all"
                    >
                        <div className="flex items-center gap-4">
                            <div className="w-10 h-10 bg-spaza-bg rounded-xl flex items-center justify-center text-text-secondary">
                                <item.icon size={20} />
                            </div>
                            <span className="text-sm font-bold text-text-primary">{item.label}</span>
                        </div>
                        <ChevronRight size={18} className="text-text-secondary" />
                    </button>
                ))}
            </div>
        </div>

        {/* Support & Legal */}
        <div className="space-y-4 pt-2">
            <div className="bg-card-bg rounded-[32px] shadow-premium border border-border-custom overflow-hidden divide-y divide-border-custom">
                <button 
                    onClick={() => handleLogout()}
                    className="w-full px-6 py-5 flex items-center justify-between active:bg-red-50 transition-all text-red-500"
                >
                    <div className="flex items-center gap-4">
                        <div className="w-10 h-10 bg-red-50 rounded-xl flex items-center justify-center">
                            <LogOut size={20} />
                        </div>
                        <span className="text-sm font-semibold">Log out</span>
                    </div>
                </button>
            </div>
        </div>

        <div className="text-center py-4">
          <p className="text-[10px] font-medium text-gray-300 uppercase tracking-widest">Version 1.0.4 • Build 82</p>
        </div>
      </div>
    </div>
  );
};

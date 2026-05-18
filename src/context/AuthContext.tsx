import React, { createContext, useContext, useEffect, useState } from 'react';
import { onAuthStateChanged, User, signInWithPopup } from 'firebase/auth';
import { auth, googleProvider } from '../lib/firebase';
import { UserProfile } from '../types';
import { apiRequest } from '../lib/apiClient';

interface AuthContextType {
  user: User | null;
  profile: UserProfile | null;
  loading: boolean;
  setProfile: React.Dispatch<React.SetStateAction<UserProfile | null>>;
  refreshProfile: () => Promise<void>;
  isAdmin: boolean;
  signInWithGoogle: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType>({ 
  user: null, 
  profile: null, 
  loading: true,
  setProfile: () => {},
  refreshProfile: async () => {},
  isAdmin: false,
  signInWithGoogle: async () => {}
});

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);

  const isAdmin = profile?.role === 'admin';

  const fetchProfile = async (authenticatedUser: User) => {
    try {
      const token = await authenticatedUser.getIdToken();
      const profileData = await apiRequest('/api/user/profile', {}, token);
      // Merge with auth data to ensure ownerName is present if missing in doc
      const mergedProfile = {
        uid: authenticatedUser.uid,
        email: authenticatedUser.email || '',
        photoUrl: authenticatedUser.photoURL || '',
        ...profileData,
      } as UserProfile;

      // Ensure ownerName is set and prioritize Firestore over Auth if it's not generic
      if (!mergedProfile.ownerName || mergedProfile.ownerName === 'User') {
        mergedProfile.ownerName = authenticatedUser.displayName || 'User';
      }

      // Split ownerName into firstName and lastName if missing
      if (mergedProfile.ownerName && mergedProfile.ownerName !== 'User') {
        const names = mergedProfile.ownerName.trim().split(/\s+/);
        if (!mergedProfile.firstName) mergedProfile.firstName = names[0];
        if (!mergedProfile.lastName && names.length > 1) {
          mergedProfile.lastName = names.slice(1).join(' ');
        }
      }
      
      setProfile(mergedProfile);
    } catch (error: any) {
      // If it's a 404, the user just doesn't have a profile doc yet, which is fine
      // But we should create a basic one for them in Firestore so it's persistent
      const names = (authenticatedUser.displayName || 'User').trim().split(/\s+/);
      const newProfile = {
        uid: authenticatedUser.uid,
        ownerName: authenticatedUser.displayName || 'User',
        firstName: names[0],
        lastName: names.slice(1).join(' '),
        email: authenticatedUser.email || '',
        photoUrl: authenticatedUser.photoURL || '',
        role: 'customer',
        createdAt: new Date().toISOString()
      } as UserProfile;

      setProfile(newProfile);

      // Attempt to persist if it was a 404
      if (error.status === 404 || error.message === 'User not found') {
        try {
          const token = await authenticatedUser.getIdToken();
          await apiRequest('/api/user/profile', {
            method: 'POST',
            body: JSON.stringify(newProfile)
          }, token);
        } catch (postError) {
          console.error('Failed to persist new profile:', postError);
        }
      } else {
        console.error('Error fetching profile in AuthContext:', error);
      }
    }
  };

  const refreshProfile = async () => {
    if (user) {
      await fetchProfile(user);
    }
  };

  const signInWithGoogle = async () => {
    try {
      setLoading(true);
      await signInWithPopup(auth, googleProvider);
    } catch (error) {
      console.error('Error signing in with Google:', error);
      throw error;
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (authenticatedUser) => {
      setUser(authenticatedUser);
      if (authenticatedUser) {
        await fetchProfile(authenticatedUser);
      } else {
        setProfile(null);
      }
      setLoading(false);
    });

    return unsubscribe;
  }, []);

  return (
    <AuthContext.Provider value={{ user, profile, loading, setProfile, refreshProfile, isAdmin, signInWithGoogle }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);

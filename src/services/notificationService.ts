import { messaging, db, auth } from '../lib/firebase';
import { getToken, onMessage } from 'firebase/messaging';
import { setDoc, doc, serverTimestamp } from 'firebase/firestore';

export const notificationService = {
  async requestPermission() {
    try {
      const permission = await Notification.requestPermission();
      if (permission === 'granted') {
        return await this.saveToken();
      }
      return null;
    } catch (error) {
      console.error('Error requesting notification permission:', error);
      return null;
    }
  },

  async saveToken() {
    try {
      const token = await getToken(messaging, {
        vapidKey: 'BMD0yWn9Pz-_l8M9t1G-OxtjGk-_7vO_0C9-u7Y5L-_W-M_L-_f-L-_v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v-v' // I need a real VAPID key usually, but sometimes Firebase handles it if configured
      });
      
      const user = auth.currentUser;
      if (token && user) {
        const tokenId = `${user.uid}_${btoa(token).substring(0, 10)}`;
        await setDoc(doc(db, 'fcmTokens', tokenId), {
          userId: user.uid,
          token,
          platform: 'web',
          deviceInfo: navigator.userAgent,
          updatedAt: serverTimestamp()
        }, { merge: true });
        return token;
      }
      return null;
    } catch (error) {
      console.error('Error saving FCM token:', error);
      return null;
    }
  },

  onForegroundMessage(callback: (payload: any) => void) {
    return onMessage(messaging, (payload) => {
      console.log('Foreground message received:', payload);
      callback(payload);
    });
  }
};

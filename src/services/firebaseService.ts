import { auth } from '../lib/firebase';
import { apiRequest } from '../lib/apiClient';

export enum OperationType {
  CREATE = 'create',
  UPDATE = 'update',
  DELETE = 'delete',
  LIST = 'list',
  GET = 'get',
  WRITE = 'write',
}

export const firebaseService = {
  // Generic collection fetch via backend
  getCollection: async (collectionName: string) => {
    try {
      // Use public products endpoint if it's products, otherwise use protected data endpoint
      const endpoint = collectionName === 'products' ? '/api/products' : `/api/data/${collectionName}`;
      return await apiRequest(endpoint);
    } catch (error) {
      console.error(`Error fetching collection ${collectionName}:`, error);
      throw error;
    }
  },

  // Get single doc via backend
  getDoc: async (collectionName: string, id: string) => {
    try {
      return await apiRequest(`/api/data/${collectionName}/${id}`);
    } catch (error) {
      console.error(`Error fetching doc ${collectionName}/${id}:`, error);
      return null;
    }
  },

  // Save/Create doc via backend
  saveDoc: async (collectionName: string, id: string, data: any) => {
    try {
      // Use specific orders endpoint if it's an order
      if (collectionName === 'orders') {
        return await apiRequest('/api/orders', {
          method: 'POST',
          body: JSON.stringify(data)
        });
      }
      
      return await apiRequest(`/api/data/${collectionName}/${id}`, {
        method: 'POST',
        body: JSON.stringify(data)
      });
    } catch (error) {
      console.error(`Error saving doc ${collectionName}/${id}:`, error);
      throw error;
    }
  },

  // Update doc via backend
  updateDoc: async (collectionName: string, id: string, data: any) => {
    try {
      return await apiRequest(`/api/data/${collectionName}/${id}`, {
        method: 'POST', // Backend uses POST with merge: true for updates
        body: JSON.stringify(data)
      });
    } catch (error) {
      console.error(`Error updating doc ${collectionName}/${id}:`, error);
      throw error;
    }
  }
};

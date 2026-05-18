export enum OrderStatus {
  CONFIRMED = "Order Confirmed",
  PACKING = "Being Packed",
  OUT_FOR_DELIVERY = "Out for Delivery",
  DELIVERED = "Delivered"
}

export interface Address {
  id: string;
  name: string;
  address: string;
  lat: number;
  lng: number;
  isDefault: boolean;
}

export interface PaymentMethod {
  id: string;
  type: 'card' | 'cash' | 'eft';
  last4?: string;
  brand?: string;
  expiry?: string;
  isDefault: boolean;
}

export interface Shop {
  id: string;
  ownerId: string;
  name: string;
  address: string;
  lat?: number;
  lng?: number;
  photoUrl?: string;
  managerName?: string;
  contactNumber?: string;
  createdAt: string;
}

export interface UserProfile {
  uid: string;
  email: string;
  phone?: string;
  shopName?: string;
  ownerName?: string;
  firstName?: string;
  lastName?: string;
  location?: string;
  lat?: number;
  lng?: number;
  photoUrl?: string;
  role: 'customer' | 'admin';
  addresses?: Address[];
  paymentMethods?: PaymentMethod[];
  activeShopId?: string;
  createdAt: string;
}

export interface Product {
  id: string;
  name: string;
  description: string;
  price: number;
  category: string;
  unit: string;
  img: string;
  stock: number;
}

export interface CartItem extends Product {
  quantity: number;
}

export interface Order {
  id: string;
  userId: string;
  items: CartItem[];
  totalAmount: number;
  status: OrderStatus;
  deliveryAddress: string;
  createdAt: string;
  updatedAt: string;
  driverInfo?: {
    name: string;
    phone: string;
    photoUrl: string;
  };
}

export interface Notification {
  id: string;
  userId: string;
  message: string;
  type: string;
  isRead: boolean;
  createdAt: string;
}

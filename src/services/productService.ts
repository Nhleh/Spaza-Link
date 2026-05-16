import { collection, getDocs, setDoc, doc, query, where } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { firebaseService, OperationType, handleFirestoreError } from './firebaseService';

export interface Product {
  id: string;
  name: string;
  description: string;
  price: number;
  oldPrice?: number;
  img: string;
  unit: string;
  category: string;
  stock: number;
}

const INITIAL_PRODUCTS: Product[] = [
  { id: '1', name: 'Coca-Cola Original', description: '2L (Case)', price: 24.50, oldPrice: 26.00, img: 'https://www.coca-cola.com/content/dam/onexp/us/en/brands/coca-cola-original/en_coca-cola-original-taste-20-oz_750x750_v1.jpg', unit: 'Case (6)', category: 'Drinks', stock: 100 },
  { id: '2', name: 'Fanta Orange', description: '2L', price: 22.00, oldPrice: 24.00, img: 'https://images.unsplash.com/photo-1624517452488-04869289c4ca?auto=format&fit=crop&q=80&w=200', unit: 'Case (6)', category: 'Drinks', stock: 100 },
  { id: '3', name: 'Albany Brown Bread', description: '700g', price: 15.20, oldPrice: 16.50, img: 'https://cdn-prd-02.pnp.co.za/sys-master/images/hf1/h51/10868899119134/silo-product-image-v2-08Jun2022-180319-6009518601505-Angle_A-39811-38704_400Wx400H', unit: 'Each', category: 'Grocery', stock: 100 },
  { id: '4', name: 'Sunlight Laundry Soap', description: '500g', price: 8.90, oldPrice: 10.00, img: 'https://media.takealot.com/covers_images/13954fad65fb4d60a4e3a5d797148a0f/s-pdpxl.file', unit: 'Each', category: 'Toiletries', stock: 100 },
  { id: '5', name: 'White Star Maize Meal', description: '10kg', price: 132.00, oldPrice: 145.00, img: 'https://www.makro.co.za/asset/rukmini/fccp/832/832/ng-fkpublic-ui-user-fbbe/fmcg-combo/n/k/o/grocery-box-dinner-combo-original-imahh29vzfgzcayr.jpeg?q=70', unit: 'Each', category: 'Grocery', stock: 100 },
  { id: '6', name: 'Frozen Mixed Veg', description: '1kg', price: 35.00, oldPrice: 40.00, img: 'https://img.freepik.com/free-photo/frozen-food-table-arrangement_23-2148969451.jpg', unit: 'Each', category: 'Frozen', stock: 100 },
  { id: '7', name: 'Simba Fruit Chutney', description: '120g', price: 18.50, oldPrice: 20.00, img: 'https://media.takealot.com/covers_images/548231c54e0b4a4cb0d82995e807382d/s-pdpxl.file', unit: 'Each', category: 'Snacks', stock: 100 },
  { id: '8', name: 'Cadbury Dairy Milk', description: '80g', price: 21.00, oldPrice: 23.00, img: 'https://media.takealot.com/covers_images/58e235a92a5445d4a198c691379ec66d/s-pdpxl.file', unit: 'Each', category: 'Snacks', stock: 100 },
  { id: '9', name: 'Colgate Toothpaste', description: '100ml', price: 19.90, oldPrice: 22.00, img: 'https://media.takealot.com/covers_images/54a1a082e66d40539bdaf67417e089d8/s-pdpxl.file', unit: 'Each', category: 'Toiletries', stock: 100 },
  { id: '10', name: 'McCain Slap Chips', description: '1kg', price: 42.00, oldPrice: 48.00, img: 'https://img.freepik.com/free-photo/french-fries-wooden-background_144627-14732.jpg', unit: 'Each', category: 'Frozen', stock: 100 },
];

export const productService = {
  getProducts: async (): Promise<Product[]> => {
    try {
      const products = await firebaseService.getCollection('products') as Product[];
      
      // If collection is empty, trigger seed
      const needsSeeding = !products || products.length === 0;

      if (needsSeeding) {
        console.log('Seeding products to Firestore...');
        await productService.seedProducts();
        // Fetch again after seeding
        const updatedProducts = await firebaseService.getCollection('products');
        return updatedProducts as Product[];
      }
      
      return products;
    } catch (error) {
      console.error('Error fetching products:', error);
      return INITIAL_PRODUCTS; // Fallback
    }
  },

  seedProducts: async () => {
    try {
      for (const product of INITIAL_PRODUCTS) {
        await setDoc(doc(db, 'products', product.id), product);
      }
      console.log('Products seeded successfully to Firestore');
    } catch (error) {
      handleFirestoreError(error, OperationType.WRITE, 'products');
    }
  }
};

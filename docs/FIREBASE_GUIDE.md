# Firebase Setup & Integration Guide

## 1. Create a Firebase Project
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Click **Add Project** and name it "Spaza Shop".
3. Enable Google Analytics (optional).

## 2. Web App Configuration
1. Click the **Web icon (</>)** to add an app.
2. Copy the `firebaseConfig` object.
3. Paste these values into your `.env` file or `src/lib/firebase.ts`.

## 3. Enable Services

### Authentication
1. Go to **Build > Authentication**.
2. Click **Get Started**.
3. Enable **Email/Password** and **Google** sign-in providers.

### Firestore Database
1. Go to **Build > Firestore Database**.
2. Click **Create Database**.
3. Choose a location and start in **Production Mode**.
4. Create a `products` collection and add demo documents.

## 4. Security Rules
Copy the following into your **Rules** tab:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

## 5. Seeding Data
Example structure for a `products` document:
- `name`: "Fresh Milk"
- `price`: 25.00
- `category`: "Dairy"
- `img`: "url_to_image"
- `stock`: 50

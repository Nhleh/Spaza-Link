# Android Studio & Mobile Build Guide

Since this is a React app, we use **Capacitor** to generate the Android Studio project.

## 1. Install Capacitor
```bash
npm install @capacitor/core @capacitor/cli @capacitor/android
npx cap init "Spaza Shop" "com.spazashop.app"
```

## 2. Build the Web App
```bash
npm run build
```

## 3. Create Android Project
```bash
npx cap add android
npx cap copy android
```

## 4. Open in Android Studio
1. Launch **Android Studio**.
2. Open the `android` folder in your project directory.
3. Wait for Gradle to sync.

## 5. Running the App
- **Emulator**: Click the "Run" button in Android Studio.
- **Physical Device**: Connect via USB, enable Developer Options/USB Debugging, and select your device.

## 6. Generating APK/AAB
1. In Android Studio: **Build > Build Bundle(s) / APK(s) > Build APK(s)**.
2. For Play Store: **Build > Generate Signed Bundle / APK**.
3. Create a New Key Store (JKS) and follow the wizard to generate an `.aab` file.
